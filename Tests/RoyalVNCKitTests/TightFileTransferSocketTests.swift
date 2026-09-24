import Foundation
import XCTest
import Darwin
@testable import RoyalVNCKit

final class TightFileTransferSocketTests: XCTestCase {
    func testTightFileTransferRunsOverAnRFBConnection() async throws {
        let server = try TightFileTransferServer()
        defer { server.stop() }

        let settings = VNCConnection.Settings(isDebugLoggingEnabled: false, hostname: "127.0.0.1", port: server.port,
            isShared: true, isScalingEnabled: true, useDisplayLink: false,
            inputMode: .forwardKeyboardShortcutsIfNotInUseLocally, isClipboardRedirectionEnabled: false,
            colorDepth: .depth24Bit, frameEncodings: .default)
        let logger = TransferTestLogger()
        let connection = VNCConnection(settings: settings, logger: logger)
        connection.prefersTightSecurityForFileTransfer = true
        defer { connection.disconnect() }

        let finished = expectation(description: "Tight upload and download finish")
        var stage = 0
        var eventNames: [String] = []
        var downloaded = Data()
        connection.fileTransferHandler = { event in
            switch event {
            case .fileList(let files):
                eventNames.append("fileList")
                XCTAssertEqual(files.map(\.name), ["remote.txt"])
                if stage == 0 {
                    stage = 1
                    do {
                        try connection.requestFileUpload(path: "/upload.txt")
                        try connection.sendFileUploadData(Data("uploaded bytes".utf8))
                        try connection.finishFileUpload(modificationTime: 99)
                        try connection.requestFileList(directory: "/")
                    } catch { XCTFail("Could not queue upload: \(error)") }
                } else if stage == 1 {
                    stage = 2
                    do { try connection.requestFileDownload(path: "/remote.txt") }
                    catch { XCTFail("Could not queue download: \(error)") }
                }
            case .downloadData(let data):
                eventNames.append("downloadData")
                downloaded.append(data)
            case .downloadFinished(let modificationTime):
                eventNames.append("downloadFinished")
                XCTAssertEqual(downloaded, Data("downloaded bytes".utf8))
                XCTAssertEqual(modificationTime, 123)
                finished.fulfill()
            case .failed(let reason):
                XCTFail("Server rejected file transfer: \(reason)")
            }
        }

        connection.connect()
        let deadline = ContinuousClock.now + .seconds(10)
        while connection.connectionState.status != .connected && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertEqual(connection.connectionState.status, .connected)
        try connection.requestFileList(directory: "/")
        await fulfillment(of: [finished], timeout: 20)
        XCTAssertEqual(eventNames, ["fileList", "fileList", "downloadData", "downloadFinished"], "server at \(server.currentStage), fixture error \(String(describing: server.error)), connection error \(String(describing: connection.connectionState.error)), log \(logger.messages.suffix(12))")
        XCTAssertTrue(connection.canTransferFiles)
        XCTAssertNil(server.error)
        XCTAssertEqual(server.receivedUpload, Data("uploaded bytes".utf8))
        XCTAssertEqual(server.receivedUploadModificationTime, 99)
    }
}

private final class TransferTestLogger: VNCLogger {
    var isDebugLoggingEnabled = true
    private let lock = NSLock()
    private var storedMessages: [String] = []
    var messages: [String] { lock.lock(); defer { lock.unlock() }; return storedMessages }
    func logDebug(_ message: @autoclosure () -> String) { append(message()) }
    func logInfo(_ message: String) { append(message) }
    func logWarning(_ message: String) { append(message) }
    func logError(_ message: String) { append(message) }
    private func append(_ message: String) { lock.lock(); storedMessages.append(message); lock.unlock() }
}

private final class TightFileTransferServer: @unchecked Sendable {
    let listener: Int32
    let port: UInt16
    private let queue = DispatchQueue(label: "RoyalVNCKitTests.TightFileTransferServer")
    private var client: Int32 = -1
    private let lock = NSLock()
    private var storedError: Error?
    private var storedUpload = Data()
    private var storedUploadModificationTime: UInt32?
    private var storedStage = "listening"
    var error: Error? { lock.lock(); defer { lock.unlock() }; return storedError }
    var receivedUpload: Data { lock.lock(); defer { lock.unlock() }; return storedUpload }
    var receivedUploadModificationTime: UInt32? { lock.lock(); defer { lock.unlock() }; return storedUploadModificationTime }
    var currentStage: String { lock.lock(); defer { lock.unlock() }; return storedStage }
    private var stopped = false

    init() throws {
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
        var reuse: Int32 = 1
        setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        address.sin_port = 0
        let bindResult = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0, listen(socketFD, 1) == 0 else {
            let code = errno
            Darwin.close(socketFD)
            throw POSIXError(.init(rawValue: code) ?? .EIO)
        }
        var actual = sockaddr_in()
        var actualLength = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameResult = withUnsafeMutablePointer(to: &actual) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(socketFD, $0, &actualLength)
            }
        }
        guard nameResult == 0 else {
            let code = errno
            Darwin.close(socketFD)
            throw POSIXError(.init(rawValue: code) ?? .EIO)
        }
        listener = socketFD
        port = UInt16(bigEndian: actual.sin_port)
        queue.async { [weak self] in self?.serve() }
    }

    func stop() {
        lock.lock()
        guard !stopped else { lock.unlock(); return }
        stopped = true
        let peer = client
        client = -1
        lock.unlock()
        if peer >= 0 { Darwin.shutdown(peer, SHUT_RDWR); Darwin.close(peer) }
        Darwin.shutdown(listener, SHUT_RDWR)
        Darwin.close(listener)
    }

    private func serve() {
        var address = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let fd = withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { accept(listener, $0, &length) }
        }
        guard fd >= 0 else { return }
        setStage("accepted")
        lock.lock(); client = fd; lock.unlock()
        do {
            setStage("handshake")
            try handshake(fd)
            setStage("pixel format and encodings")
            _ = try readExactly(fd, 20) // SetPixelFormat
            let encodingsHeader = try readExactly(fd, 4)
            let encodingCount = Int(encodingsHeader[2]) << 8 | Int(encodingsHeader[3])
            _ = try readExactly(fd, encodingCount * 4)
            setStage("initial framebuffer request")
            _ = try readExactly(fd, 10) // First FramebufferUpdateRequest

            setStage("first list request")
            let listRequest = try readRequest(fd, type: 130)
            guard listRequest == Data("/".utf8) else { throw fixtureError("unexpected list path") }
            try sendFileList(fd)

            setStage("upload request")
            let uploadPath = try readRequest(fd, type: 132)
            guard uploadPath == Data("/upload.txt".utf8) else { throw fixtureError("unexpected upload path") }
            setStage("upload data")
            let upload = try readUploadPacket(fd)
            setUpload(upload)
            setStage("upload end")
            let modificationTime = try readUploadEnd(fd)
            setUploadModificationTime(modificationTime)

            setStage("refresh list request")
            let refreshRequest = try readRequest(fd, type: 130)
            guard refreshRequest == Data("/".utf8) else { throw fixtureError("unexpected refresh path") }
            try sendFileList(fd)

            setStage("download request")
            let downloadPath = try readRequest(fd, type: 131)
            guard downloadPath == Data("/remote.txt".utf8) else { throw fixtureError("unexpected download path") }
            try sendDownloadChunk(fd, Data("downloaded bytes".utf8))
            try sendDownloadEnd(fd, modificationTime: 123)
            setStage("complete")
        } catch {
            lock.lock(); storedError = error; lock.unlock()
        }
    }

    private func handshake(_ fd: Int32) throws {
        try writeAll(fd, Data("RFB 003.008\n".utf8))
        guard try readExactly(fd, 12) == Data("RFB 003.008\n".utf8) else { throw fixtureError("bad client protocol version") }
        try writeAll(fd, Data([2, 1, 16])) // None and Tight; client must prefer Tight.
        guard try readExactly(fd, 1) == Data([16]) else { throw fixtureError("client did not select Tight security") }
        var tunnel = Data(); tunnel.append(UInt32(0), bigEndian: true); try writeAll(fd, tunnel)
        var auth = Data(); auth.append(UInt32(1), bigEndian: true); auth.append(capability(1, "STDV", "NOAUTH__")); try writeAll(fd, auth)
        let selectedAuth = try readExactly(fd, 4)
        guard selectedAuth == Data([0, 0, 0, 1]) else { throw fixtureError("client did not choose no-auth Tight subtype") }
        try writeAll(fd, Data([0, 0, 0, 0])) // SecurityResult OK
        _ = try readExactly(fd, 1) // ClientInit shared flag

        var serverInitData = Data([0, 1, 0, 1])
        serverInitData.append(VNCProtocol.PixelFormat(depth: 24).data)
        serverInitData.append(UInt32(0), bigEndian: true) // Empty desktop name
        let serverMessages = [capability(130, "TGHT", "FTS_LSDT"), capability(131, "TGHT", "FTS_DNDT")]
        let clientMessages = [capability(130, "TGHT", "FTC_LSRQ"), capability(131, "TGHT", "FTC_DNRQ"),
                              capability(132, "TGHT", "FTC_UPRQ"), capability(133, "TGHT", "FTC_UPDT")]
        serverInitData.append(UInt16(serverMessages.count), bigEndian: true)
        serverInitData.append(UInt16(clientMessages.count), bigEndian: true)
        serverInitData.append(UInt16(0), bigEndian: true); serverInitData.append(UInt16(0), bigEndian: true)
        for capability in serverMessages + clientMessages { serverInitData.append(capability) }
        try writeAll(fd, serverInitData)
    }

    private func readRequest(_ fd: Int32, type: UInt8) throws -> Data {
        guard try readExactly(fd, 1) == Data([type]) else { throw fixtureError("unexpected client message") }
        if type == 130 {
            let header = try readExactly(fd, 3)
            let size = Int(header[1]) << 8 | Int(header[2])
            return try readExactly(fd, size)
        }
        let header = try readExactly(fd, 7)
        let size = Int(header[1]) << 8 | Int(header[2])
        return try readExactly(fd, size)
    }

    private func readUploadPacket(_ fd: Int32) throws -> Data {
        guard try readExactly(fd, 1) == Data([133]) else { throw fixtureError("expected upload data") }
        let header = try readExactly(fd, 5)
        let realSize = Int(header[1]) << 8 | Int(header[2])
        let compressedSize = Int(header[3]) << 8 | Int(header[4])
        guard realSize == compressedSize else { throw fixtureError("fixture expects uncompressed upload") }
        return try readExactly(fd, compressedSize)
    }

    private func readUploadEnd(_ fd: Int32) throws -> UInt32 {
        guard try readExactly(fd, 1) == Data([133]) else { throw fixtureError("expected upload end marker") }
        let body = try readExactly(fd, 9)
        guard body[1...4].allSatisfy({ $0 == 0 }) else { throw fixtureError("invalid upload end marker") }
        return body.withUnsafeBytes { UInt32(bigEndian: $0.loadUnaligned(fromByteOffset: 5, as: UInt32.self)) }
    }

    private func sendFileList(_ fd: Int32) throws {
        let names = Data("remote.txt\0".utf8)
        var body = Data([130, 0])
        body.append(UInt16(1), bigEndian: true); body.append(UInt16(names.count), bigEndian: true)
        body.append(UInt16(names.count), bigEndian: true)
        body.append(UInt32(14), bigEndian: true); body.append(UInt32(123), bigEndian: true)
        body.append(names)
        try writeAll(fd, body)
    }

    private func sendDownloadChunk(_ fd: Int32, _ data: Data) throws {
        var packet = Data([131, 0]); packet.append(UInt16(data.count), bigEndian: true)
        packet.append(UInt16(data.count), bigEndian: true); packet.append(data)
        try writeAll(fd, packet)
    }

    private func sendDownloadEnd(_ fd: Int32, modificationTime: UInt32) throws {
        var packet = Data([131, 0, 0, 0, 0, 0]); packet.append(modificationTime, bigEndian: true)
        try writeAll(fd, packet)
    }

    private func capability(_ code: UInt32, _ vendor: String, _ signature: String) -> Data {
        var result = Data(); result.append(code, bigEndian: true)
        result.append(Data(vendor.utf8)); result.append(Data(signature.utf8)); return result
    }

    private func readExactly(_ fd: Int32, _ count: Int) throws -> Data {
        var result = Data(count: count)
        var offset = 0
        while offset < count {
            let received = result.withUnsafeMutableBytes { bytes in
                Darwin.recv(fd, bytes.baseAddress!.advanced(by: offset), count - offset, 0)
            }
            guard received > 0 else { throw fixtureError("socket closed while receiving packet") }
            offset += received
        }
        return result
    }

    private func writeAll(_ fd: Int32, _ data: Data) throws {
        var offset = 0
        while offset < data.count {
            let sent = data.withUnsafeBytes { bytes in
                Darwin.send(fd, bytes.baseAddress!.advanced(by: offset), data.count - offset, 0)
            }
            guard sent > 0 else { throw fixtureError("socket closed while sending packet") }
            offset += sent
        }
    }

    private func fixtureError(_ message: String) -> NSError {
        NSError(domain: "TightFileTransferSocketTests", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func setStage(_ value: String) { lock.lock(); storedStage = value; lock.unlock() }
    private func setUpload(_ value: Data) { lock.lock(); storedUpload = value; lock.unlock() }
    private func setUploadModificationTime(_ value: UInt32) { lock.lock(); storedUploadModificationTime = value; lock.unlock() }

    deinit { stop() }
}
