#if canImport(CFNetwork) && canImport(Darwin)
import Dispatch
import Darwin
import XCTest
@testable import RoyalVNCKit

final class CFStreamNetworkConnectionTests: XCTestCase {
    func testKeyboardWriteIsNotBlockedByPendingServerRead() async throws {
        let peer = try DelayedCFStreamPeer()
        defer { peer.stop() }

        let connection = CFStreamNetworkConnection(settings: NetworkConnectionSettings(
            connectionTimeout: 5, host: "127.0.0.1", port: peer.port
        ))
        defer { connection.cancel() }

        let ready = expectation(description: "CFStream connected")
        connection.setStatusUpdateHandler { status in
            if case .ready = status { ready.fulfill() }
        }
        connection.start(queue: DispatchQueue(label: "CFStreamNetworkConnectionTests.lifecycle"))
        await fulfillment(of: [ready], timeout: 5)

        let sendableConnection = SendableCFStreamConnection(connection)
        let readTask = Task { try await sendableConnection.value.read(minimumLength: 1, maximumLength: 1) }
        try await Task.sleep(for: .milliseconds(50))

        let start = ContinuousClock.now
        try await connection.write(data: Data([0x41]))
        let writeDuration = start.duration(to: .now)
        XCTAssertLessThan(writeDuration, .milliseconds(300),
                          "Keyboard writes should not wait for a blocked server read")

        let response = try await readTask.value
        XCTAssertEqual(response, Data([0x52]))
        await fulfillment(of: [peer.receivedClientData], timeout: 2)
    }
}

private final class DelayedCFStreamPeer: @unchecked Sendable {
    private let listener: Int32
    let port: UInt16
    let receivedClientData = XCTestExpectation(description: "Client data reached the VNC server")
    private let lock = NSLock()
    private var client: Int32 = -1

    init() throws {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
        var reuse: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        address.sin_port = 0
        let bindResult = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0, listen(fd, 1) == 0 else {
            let error = errno
            Darwin.close(fd)
            throw POSIXError(.init(rawValue: error) ?? .EIO)
        }
        var actual = sockaddr_in()
        var actualLength = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameResult = withUnsafeMutablePointer(to: &actual) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &actualLength) }
        }
        guard nameResult == 0 else {
            let error = errno
            Darwin.close(fd)
            throw POSIXError(.init(rawValue: error) ?? .EIO)
        }
        listener = fd
        port = UInt16(bigEndian: actual.sin_port)
        DispatchQueue.global().async { [weak self] in self?.serve() }
    }

    func stop() {
        lock.lock()
        let fd = client
        client = -1
        lock.unlock()
        if fd >= 0 { Darwin.shutdown(fd, SHUT_RDWR); Darwin.close(fd) }
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
        lock.lock(); client = fd; lock.unlock()

        // Let the client's first read block. A healthy transport still writes concurrently.
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(650)) {
            var byte: UInt8 = 0x52
            _ = Darwin.send(fd, &byte, 1, 0)
        }

        var received: UInt8 = 0
        let count = Darwin.recv(fd, &received, 1, 0)
        if count == 1 && received == 0x41 { receivedClientData.fulfill() }
    }
}
#endif

private struct SendableCFStreamConnection: @unchecked Sendable {
    let value: CFStreamNetworkConnection
    init(_ value: CFStreamNetworkConnection) { self.value = value }
}
