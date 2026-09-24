import Foundation
import XCTest
@testable import RoyalVNCKit

final class TightInteractionCapabilitiesTests: XCTestCase {
    func testRecognizesOnlyAdvertisedTightFileTransferDirections() throws {
        let server = [capability(130, "TGHT", "FTS_LSDT"), capability(131, "TGHT", "FTS_DNDT")]
        let client = [capability(130, "TGHT", "FTC_LSRQ"), capability(131, "TGHT", "FTC_DNRQ"),
                      capability(132, "TGHT", "FTC_UPRQ"), capability(133, "TGHT", "FTC_UPDT")]
        var packet = Data()
        packet.append(UInt16(server.count), bigEndian: true)
        packet.append(UInt16(client.count), bigEndian: true)
        packet.append(UInt16(0), bigEndian: true)
        packet.append(UInt16(0), bigEndian: true)
        for entry in server + client { packet.append(entry) }

        let decoded = try TightInteractionCapabilities.decode(packet)
        XCTAssertTrue(decoded.supportsTightFileDownload)
        XCTAssertTrue(decoded.supportsTightFileUpload)
        XCTAssertTrue(decoded.supportsTightFileTransfer)
        XCTAssertEqual(decoded.serverMessages.map(\.signature), ["FTS_LSDT", "FTS_DNDT"])
        XCTAssertEqual(decoded.clientMessages.map(\.code), [130, 131, 132, 133])
    }

    func testDownloadCapabilityDoesNotRequireServerUploadSupport() throws {
        let server = [capability(130, "TGHT", "FTS_LSDT"), capability(131, "TGHT", "FTS_DNDT")]
        let client = [capability(130, "TGHT", "FTC_LSRQ"), capability(131, "TGHT", "FTC_DNRQ")]
        var packet = Data()
        packet.append(UInt16(server.count), bigEndian: true)
        packet.append(UInt16(client.count), bigEndian: true)
        packet.append(UInt16(0), bigEndian: true)
        packet.append(UInt16(0), bigEndian: true)
        for entry in server + client { packet.append(entry) }

        let decoded = try TightInteractionCapabilities.decode(packet)
        XCTAssertTrue(decoded.supportsTightFileDownload)
        XCTAssertFalse(decoded.supportsTightFileUpload)
        XCTAssertFalse(decoded.supportsTightFileTransfer)
    }

    func testDoesNotInferUnadvertisedFileTransferAndRetainsUnknownExtensions() throws {
        var packet = Data()
        packet.append(UInt16(1), bigEndian: true)
        packet.append(UInt16(1), bigEndian: true)
        packet.append(UInt16(0), bigEndian: true)
        packet.append(UInt16(0), bigEndian: true)
        packet.append(capability(130, "TGHT", "FTS_LSDT"))
        packet.append(capability(130, "VEND", "UNKNOWN_"))

        let decoded = try TightInteractionCapabilities.decode(packet)
        XCTAssertFalse(decoded.supportsTightFileTransfer)
        XCTAssertEqual(decoded.clientMessages.first?.vendor, "VEND")
        XCTAssertEqual(decoded.clientMessages.first?.signature, "UNKNOWN_")
    }

    func testRejectsTruncatedOversizedAndMalformedCapabilityLists() {
        XCTAssertThrowsError(try TightInteractionCapabilities.decode(Data([0, 0, 0])))

        var oversized = Data()
        oversized.append(UInt16(TightInteractionCapabilities.maximumCapabilitiesPerCategory + 1), bigEndian: true)
        oversized.append(contentsOf: [0, 0, 0, 0, 0, 0])
        XCTAssertThrowsError(try TightInteractionCapabilities.decode(oversized))

        let invalidPadding = Data([0, 0, 0, 0, 0, 0, 0, 1])
        XCTAssertThrowsError(try TightInteractionCapabilities.decode(invalidPadding))

        var truncated = Data([0, 1, 0, 0, 0, 0, 0, 0])
        truncated.append(contentsOf: [0, 0, 0])
        XCTAssertThrowsError(try TightInteractionCapabilities.decode(truncated))
    }

    func testTightNegotiationUsesNoTunnelAndPrefersVNCAuthentication() async throws {
        let peer = TightPeer([
            word(1), capability(0, "TGHT", "NOTUNNEL"),
            word(2), capability(1, "STDV", "NOAUTH__"), capability(2, "STDV", "VNCAUTH_")
        ].reduce(into: Data()) { $0.append($1) })

        let authentication = try await TightSecurity.negotiate(connection: peer)
        XCTAssertEqual(authentication, .vnc)
        XCTAssertEqual(peer.written, word(0) + word(2))
    }

    func testTightNegotiationAllowsExplicitNoAuthAndZeroCapabilityLists() async throws {
        let noTunnel = TightPeer(word(0) + word(1) + capability(1, "STDV", "NOAUTH__"))
        let noTunnelAuthentication = try await TightSecurity.negotiate(connection: noTunnel)
        XCTAssertEqual(noTunnelAuthentication, .none)
        XCTAssertEqual(noTunnel.written, word(1))

        let emptyLists = TightPeer(word(0) + word(0))
        let emptyListAuthentication = try await TightSecurity.negotiate(connection: emptyLists)
        XCTAssertEqual(emptyListAuthentication, .none)
        XCTAssertTrue(emptyLists.written.isEmpty)
    }

    func testTightNegotiationRejectsUnsupportedTunnelOrAuthentication() async {
        let unsupportedTunnel = TightPeer(word(1) + capability(5, "VENC", "TLS_____") + word(0))
        do {
            _ = try await TightSecurity.negotiate(connection: unsupportedTunnel)
            XCTFail("Unsupported tunnel must be rejected")
        } catch {}

        let unsupportedAuthentication = TightPeer(word(0) + word(1) + capability(129, "TGHT", "ULGNAUTH"))
        do {
            _ = try await TightSecurity.negotiate(connection: unsupportedAuthentication)
            XCTFail("Unsupported authentication must be rejected")
        } catch {}
    }

    func testTightFileTransferRequestPacketsUseBoundedUTF8Paths() throws {
        XCTAssertEqual(try TightFileTransfer.fileListRequest(directory: "/tmp/日本語"),
                       Data([130, 0, 0, 14]) + Data("/tmp/日本語".utf8))
        var expectedDownload = Data([131, 0, 0, 8, 0, 0, 0, 5])
        expectedDownload.append(Data("file.txt".utf8))
        XCTAssertEqual(try TightFileTransfer.downloadRequest(path: "file.txt", offset: 5), expectedDownload)
        var expectedUpload = Data([132, 0, 0, 8, 0, 0, 0, 0])
        expectedUpload.append(Data("file.txt".utf8))
        XCTAssertEqual(try TightFileTransfer.uploadRequest(path: "file.txt"), expectedUpload)
        XCTAssertThrowsError(try TightFileTransfer.fileListRequest(directory: "bad\0path"))
        XCTAssertThrowsError(try TightFileTransfer.downloadRequest(path: String(repeating: "x", count: 4097)))
    }

    func testTightFileTransferDecodesListsChunksAndEndMarker() throws {
        var list = Data([0])
        list.append(UInt16(2), bigEndian: true)
        let names = Data("folder\0hello.txt\0".utf8)
        list.append(UInt16(names.count), bigEndian: true)
        list.append(UInt16(names.count), bigEndian: true)
        list.append(UInt32.max, bigEndian: true)
        list.append(UInt32(10), bigEndian: true)
        list.append(UInt32(123), bigEndian: true)
        list.append(UInt32(20), bigEndian: true)
        list.append(names)
        XCTAssertEqual(try TightFileTransfer.decodeFileList(list), [
            .init(name: "folder", size: 0, modificationTime: 10, isDirectory: true),
            .init(name: "hello.txt", size: 123, modificationTime: 20, isDirectory: false)
        ])

        XCTAssertEqual(try TightFileTransfer.decodeDownloadChunk(Data([0, 0, 3, 0, 3, 1, 2, 3])),
                       .init(data: Data([1, 2, 3]), modificationTime: nil))
        XCTAssertEqual(try TightFileTransfer.decodeDownloadChunk(Data([0, 0, 0, 0, 0, 0, 0, 0, 42])),
                       .init(data: Data(), modificationTime: 42))
        XCTAssertThrowsError(try TightFileTransfer.decodeDownloadChunk(Data([0, 0, 0, 0, 4, 1, 2, 3])))
        XCTAssertThrowsError(try TightFileTransfer.decodeFileList(Data([0, 0, 1, 0, 1, 0, 1, 0])))
    }

    func testTightFileTransferRejectsUnsafeNamesAndMalformedPayloads() throws {
        for name in ["..", ".", "../escape", "folder/file", "bad\\name", "nul\0byte", "line\nbreak"] {
            var list = Data([0])
            list.append(UInt16(1), bigEndian: true)
            let names = Data((name + "\0").utf8)
            list.append(UInt16(names.count), bigEndian: true)
            list.append(UInt16(names.count), bigEndian: true)
            list.append(UInt32(1), bigEndian: true)
            list.append(UInt32(0), bigEndian: true)
            list.append(names)
            XCTAssertThrowsError(try TightFileTransfer.decodeFileList(list), "accepted unsafe name: \\(name)")
        }

        // A compressed block cannot expand past the length announced by the peer.
        let compressed = Data([120, 156, 203, 72, 205, 201, 201, 7, 0, 6, 44, 2, 21]) // zlib("hello")
        var oversizedExpansion = Data([0])
        oversizedExpansion.append(UInt16(6), bigEndian: true)
        oversizedExpansion.append(UInt16(compressed.count), bigEndian: true)
        oversizedExpansion.append(compressed)
        XCTAssertThrowsError(try TightFileTransfer.decodeDownloadChunk(oversizedExpansion))

        XCTAssertThrowsError(try TightFileTransfer.decodeDownloadChunk(Data([0, 0, 0, 0, 4, 1, 2, 3])))
        XCTAssertThrowsError(try TightFileTransfer.decodeFileList(Data(repeating: 0xff, count: 7)))
    }

    func testTightFileTransferDecompressesBoundedListNamesAndDownloadChunks() throws {
        // zlib.compress(bytes([97, 108, 112, 104, 97, 0])) and zlib.compress(b"hello")
        let compressedNames = Data([120, 156, 75, 204, 41, 200, 72, 100, 0, 0, 8, 34, 2, 7])
        var list = Data([0])
        list.append(UInt16(1), bigEndian: true)
        list.append(UInt16(6), bigEndian: true)
        list.append(UInt16(compressedNames.count), bigEndian: true)
        list.append(UInt32(4), bigEndian: true)
        list.append(UInt32(7), bigEndian: true)
        list.append(compressedNames)
        XCTAssertEqual(try TightFileTransfer.decodeFileList(list), [
            .init(name: "alpha", size: 4, modificationTime: 7, isDirectory: false)
        ])

        let compressedChunk = Data([120, 156, 203, 72, 205, 201, 201, 7, 0, 6, 44, 2, 21])
        var chunk = Data([0])
        chunk.append(UInt16(5), bigEndian: true)
        chunk.append(UInt16(compressedChunk.count), bigEndian: true)
        chunk.append(compressedChunk)
        XCTAssertEqual(try TightFileTransfer.decodeDownloadChunk(chunk),
                       .init(data: Data("hello".utf8), modificationTime: nil))
    }

    func testTightFileTransferUploadDataEncodesChunksAndEndMarker() throws {
        XCTAssertEqual(try TightFileTransfer.uploadData(Data([1, 2, 3])),
                       Data([133, 0, 0, 3, 0, 3, 1, 2, 3]))
        XCTAssertEqual(try TightFileTransfer.uploadData(Data(), endModificationTime: 42),
                       Data([133, 0, 0, 0, 0, 0, 0, 0, 0, 42]))
        XCTAssertThrowsError(try TightFileTransfer.uploadData(Data()))
        XCTAssertThrowsError(try TightFileTransfer.uploadData(Data(repeating: 0, count: 65_536)))
    }

    func testConnectionRejectsFileOperationsUnlessTheTightServerAdvertisedThem() async throws {
        try await MainActor.run {
            let settings = VNCConnection.Settings(isDebugLoggingEnabled: false, hostname: "localhost", port: 5900,
                isShared: true, isScalingEnabled: true, useDisplayLink: false,
                inputMode: .forwardKeyboardShortcutsIfNotInUseLocally, isClipboardRedirectionEnabled: true,
                colorDepth: .depth24Bit, frameEncodings: .default)
            let connection = VNCConnection(settings: settings, logger: VNCPrintLogger())
            connection.connectionState = .connected
            XCTAssertThrowsError(try connection.requestFileList(directory: "/"))
            connection.supportsTightFileTransfer = true
            connection.supportsTightFileDownload = true
            connection.supportsTightFileUpload = true
            XCTAssertNoThrow(try connection.requestFileList(directory: "/"))
            XCTAssertNoThrow(try connection.requestFileDownload(path: "/remote.txt"))
            XCTAssertNoThrow(try connection.requestFileUpload(path: "/remote.txt"))
            XCTAssertNoThrow(try connection.sendFileUploadData(Data([1, 2, 3])))
            XCTAssertNoThrow(try connection.finishFileUpload(modificationTime: 42))
            let queued = (0..<5).compactMap { _ in connection.clientToServerMessageQueue.dequeue()?.data }
            XCTAssertEqual(queued.count, 5)
            XCTAssertTrue(queued.allSatisfy { [130, 131, 132, 133].contains($0.first ?? 0) })
        }
    }

    func testReadOnlyTightServerAllowsListAndDownloadButRejectsUpload() async throws {
        try await MainActor.run {
            let settings = VNCConnection.Settings(isDebugLoggingEnabled: false, hostname: "localhost", port: 5900,
                isShared: true, isScalingEnabled: true, useDisplayLink: false,
                inputMode: .forwardKeyboardShortcutsIfNotInUseLocally, isClipboardRedirectionEnabled: true,
                colorDepth: .depth24Bit, frameEncodings: .default)
            let connection = VNCConnection(settings: settings, logger: VNCPrintLogger())
            connection.connectionState = .connected
            connection.supportsTightFileDownload = true
            XCTAssertTrue(connection.canDownloadFiles)
            XCTAssertFalse(connection.canUploadFiles)
            XCTAssertFalse(connection.canTransferFiles)
            XCTAssertNoThrow(try connection.requestFileList(directory: "/"))
            XCTAssertNoThrow(try connection.requestFileDownload(path: "/remote.txt"))
            XCTAssertThrowsError(try connection.requestFileUpload(path: "/remote.txt"))
            XCTAssertThrowsError(try connection.sendFileUploadData(Data([1])))
            XCTAssertThrowsError(try connection.finishFileUpload(modificationTime: 42))
            let queued = (0..<2).compactMap { _ in connection.clientToServerMessageQueue.dequeue()?.data }
            XCTAssertEqual(queued.count, 2)
            XCTAssertEqual(queued.map(\.first), [130, 131])
        }
    }

    private func capability(_ code: UInt32, _ vendor: String, _ signature: String) -> Data {
        var data = Data()
        data.append(code, bigEndian: true)
        data.append(contentsOf: vendor.utf8)
        data.append(contentsOf: signature.utf8)
        return data
    }

    private func word(_ value: UInt32) -> Data {
        var value = value.bigEndian
        return withUnsafeBytes(of: &value) { Data($0) }
    }
}

private final class TightPeer: NetworkConnectionReading, NetworkConnectionWriting {
    private var bytes: Data
    private(set) var written = Data()

    init(_ bytes: Data) { self.bytes = bytes }

    func read(minimumLength: Int, maximumLength: Int) async throws -> Data {
        guard maximumLength > 0, !bytes.isEmpty else { throw VNCError.protocol(.invalidData) }
        let count = min(maximumLength, bytes.count)
        let result = Data(bytes.prefix(count))
        bytes = Data(bytes.dropFirst(count))
        return result
    }

    func write(data: Data) async throws { written.append(data) }
}
