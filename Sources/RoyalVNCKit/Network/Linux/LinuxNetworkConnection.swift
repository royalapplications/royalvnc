#if os(Linux)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import Glibc
import Dispatch

// TODO: All of this is very hacky and NOT fully fleshed out!
final class LinuxNetworkConnection: NetworkConnection {
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

            let addressInfo: AddressInfo

            do {
                addressInfo = try .init(host: settings.host,
                                        port: settings.port)
            } catch {
                self.status = .failed(error)

                return
            }

            let socket: Socket

            do {
                socket = try .init(addressInfo: addressInfo)
            } catch {
                self.status = .failed(error)

                return
            }

            let connectResult = connect(
                socket.nativeSocket,
                addressInfo.addrInfo.pointee.ai_addr,
                addressInfo.addrInfo.pointee.ai_addrlen
            )

            guard connectResult >= 0 else {
                self.status = .failed(SocketError.connectionFailed(code: connectResult))
                
                return
            }

            self.socket = socket
            self.status = .ready
        }
    }
}

extension LinuxNetworkConnection: NetworkConnectionReading {
	func read(minimumLength: Int,
              maximumLength: Int) async throws -> Data {
        guard let queue else {
            throw SocketError.noQueue
        }

        guard let socket else {
            throw Socket.Errors.socketCreationFailed(underlyingErrorCode: nil)
        }

        let bufferSize = maximumLength

		return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                var buffer = [UInt8](repeating: 0, count: bufferSize)
        
                let bytesRead = recv(
                    socket.nativeSocket,
                    &buffer,
                    bufferSize,
                    0
                )

                // Handle connection closure
                if bytesRead == 0 {
                    // TODO
                    continuation.resume(throwing: SocketError.connectionClosed)

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
                let receivedData = Array(buffer.prefix(bytesRead))
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

extension LinuxNetworkConnection: NetworkConnectionWriting {
	func write(data: Data) async throws {
        guard let queue else {
            throw SocketError.noQueue
        }

        guard let socket else {
            throw Socket.Errors.socketCreationFailed(underlyingErrorCode: nil)
        }

		return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let bytesToSend = [UInt8](data)
                
                let bytesSent = send(
                    socket.nativeSocket,
                    bytesToSend,
                    bytesToSend.count,
                    0
                )
                
                if bytesSent < 0 {
                    continuation.resume(throwing: SocketError.sendFailed)
                } else {
                    continuation.resume()
                }
            }
        }
	}
}

private extension LinuxNetworkConnection {
    // MARK: - Enum for Socket Errors
    enum SocketError: LocalizedError {
        case connectionFailed(code: Int32)
        case sendFailed
        case receiveFailed
        case noQueue
        case connectionClosed

        var errorDescription: String? {
            switch self {
                case .connectionFailed(let code):
                    "Connection failed: \(code)"
                case .sendFailed:
                    "Send failed"
                case .receiveFailed:
                    "Receive failed"
                case .noQueue:
                    "No Dispatch Queue"
                case .connectionClosed:
                    "Connection closed"
            }
        }
    }
}
#endif
