#if os(Linux) || os(Windows)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(Glibc)
import Glibc
#elseif canImport(WinSDK)
import WinSDK
#endif

import Dispatch

// TODO: All of this is very hacky and NOT fully fleshed out!
final class SocketNetworkConnection: NetworkConnection {
    let settings: NetworkConnectionSettings

    private var socket: Socket?
    private var queue: DispatchQueue?

    private(set) var statusUpdateHandler: NetworkConnectionStatusUpdateHandler?

    private(set) var status: NetworkConnectionStatus = .unknown("None") {
        didSet {
            statusUpdateHandler?(status)
        }
    }

    init(settings: NetworkConnectionSettings) {
#if canImport(WinSDK)
        do {
            try Self.intializeWinsock()
        } catch {
            fatalError("Initializing Winsock failed: \(error.humanReadableDescription)")
        }
#endif

        self.settings = settings
    }
    
    func setStatusUpdateHandler(_ statusUpdateHandler: NetworkConnectionStatusUpdateHandler?) {
        self.statusUpdateHandler = statusUpdateHandler
    }
    
    var isReady: Bool {
        switch status {
            case .ready:
                true
            default:
                false
        }
    }
    
    func cancel() {
        // TODO
        // fatalError("Not implemented")
    }

    func start(queue: DispatchQueue) {
        self.status = .preparing
        self.queue = queue

        queue.async { [weak self] in
            guard let self else { return }

            do {
                let addressInfo = try AddressInfo(host: settings.host,
                                                               port: settings.port)

                let socket = try Socket(addressInfo: addressInfo)

                try socket.connect()

                self.socket = socket
                self.status = .ready
            } catch {
                self.status = .failed(error)
            }
        }
    }
}

// MARK: - Winsock Initialization
#if canImport(WinSDK)
private extension SocketNetworkConnection {
    static func intializeWinsock() throws {
        try intializeWinsock(2, 2)
    }
    
    static func intializeWinsock(_ versionA: UInt8, _ versionB: UInt8) throws {
        func makeWord(_ a: UInt8, _ b: UInt8) -> UInt16 {
            return UInt16(a) | (UInt16(b) << 8)
        }
        
        let wVersionRequested = makeWord(versionA, versionB)
        
        var lpWSAData = WSADATA()
        let status = WSAStartup(wVersionRequested, &lpWSAData)
        
        guard status == 0 else {
            throw Errors.winsockInitError(underlyingErrorCode: status)
        }
    }
}
#endif

// MARK: - Reading
extension SocketNetworkConnection: NetworkConnectionReading {
	func read(minimumLength: Int,
              maximumLength: Int) async throws -> Data {
        guard let queue else {
            throw Errors.noQueue
        }

        guard let socket else {
            throw Socket.Errors.socketCreationFailed(underlyingErrorCode: nil)
        }

        let bufferSize = maximumLength

		return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                var buffer = [UInt8](repeating: 0, count: bufferSize)
                let bytesRead = socket.receive(buffer: &buffer)

                // Handle connection closure
                if bytesRead == 0 {
                    // TODO
                    continuation.resume(throwing: Errors.connectionClosed)

                    return
                }

                // Handle errors during receiving
                if bytesRead < 0 {
                    // let errorNumber = errno
                    // print("Error: \(errorNumber.hexString())")

                    continuation.resume(throwing: VNCError.protocol(.noData))

                    return
                }

                // Slice the buffer to get only the received data
                let receivedData = Array(buffer.prefix(.init(bytesRead)))
                let receivedLength = receivedData.count

                // Validate received data length
                guard receivedLength >= minimumLength,
                      receivedLength <= maximumLength else {
                    continuation.resume(throwing: VNCError.protocol(.invalidData))

                    return
                }

                continuation.resume(returning: Data(receivedData))
            }
        }
	}
}

// MARK: - Writing
extension SocketNetworkConnection: NetworkConnectionWriting {
	func write(data: Data) async throws {
        guard let queue else {
            throw Errors.noQueue
        }

        guard let socket else {
            throw Socket.Errors.socketCreationFailed(underlyingErrorCode: nil)
        }

		return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let bytesToSend = [UInt8](data)
                let bytesSent = socket.send(buffer: bytesToSend)
                
                if bytesSent < 0 {
                    continuation.resume(throwing: Errors.sendFailed)
                } else {
                    continuation.resume()
                }
            }
        }
	}
}

// MARK: - Errors
private extension SocketNetworkConnection {
    // MARK: - Enum for Socket Errors
    enum Errors: LocalizedError {
        case sendFailed
        case noQueue
        case connectionClosed
        case winsockInitError(underlyingErrorCode: Int32)

        var errorDescription: String? {
            switch self {
                case .sendFailed:
                    "Send failed"
                case .noQueue:
                    "No Dispatch Queue"
                case .connectionClosed:
                    "Connection closed"
                case .winsockInitError(let underlyingErrorCode):
                    "WSAStartup failed (\(underlyingErrorCode))"
            }
        }
    }
}
#endif
