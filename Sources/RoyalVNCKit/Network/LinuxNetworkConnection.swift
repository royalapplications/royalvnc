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

    private var socketFD: Int32?
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

    deinit {
        guard let socketFD else { return }

        close(socketFD)
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

            var hints = addrinfo(
                ai_flags: AI_PASSIVE,
                ai_family: AF_INET,
                ai_socktype: .init(SOCK_STREAM.rawValue),
                ai_protocol: 0,
                ai_addrlen: 0,
                ai_addr: nil,
                ai_canonname: nil,
                ai_next: nil
            )

            var addrinfoResult: UnsafeMutablePointer<addrinfo>?

            let host = self.settings.host
            let port = self.settings.port
            
            // Resolve the address
            let getaddrinfoStatus = getaddrinfo(
                host,
                "\(port)",
                &hints, 
                &addrinfoResult
            )
            
            guard getaddrinfoStatus == 0 else {
                self.status = .failed(SocketError.dnsResolutionFailed)

                return
            }

            guard let addrinfoResult else {
                self.status = .failed(SocketError.addressInfoEmpty)

                return
            }

            defer {
                freeaddrinfo(addrinfoResult)
            }

            let socketFD = socket(
                addrinfoResult.pointee.ai_family,
                addrinfoResult.pointee.ai_socktype,
                addrinfoResult.pointee.ai_protocol
            )

            guard socketFD >= 0 else {
                self.status = .failed(SocketError.socketCreationFailed)

                return
            }

            let connectResult = connect(
                socketFD,
                addrinfoResult.pointee.ai_addr,
                addrinfoResult.pointee.ai_addrlen
            )

            guard connectResult >= 0 else {
                self.status = .failed(SocketError.connectionFailed(code: connectResult))
                
                return
            }

            self.socketFD = socketFD
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

        guard let socketFD else {
            throw SocketError.socketCreationFailed
        }

        let bufferSize = maximumLength

		return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                var buffer = [UInt8](repeating: 0, count: bufferSize)
        
                let bytesRead = recv(
                    socketFD,
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

        guard let socketFD else {
            throw SocketError.socketCreationFailed
        }

		return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let bytesToSend = [UInt8](data)
                
                let bytesSent = send(
                    socketFD,
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
        case socketCreationFailed
        case connectionFailed(code: Int32)
        case sendFailed
        case receiveFailed
        case dnsResolutionFailed
        case addressInfoEmpty
        case noQueue
        case connectionClosed

        var errorDescription: String? {
            switch self {
                case .socketCreationFailed:
                    "Socket creation failed"
                case .connectionFailed(let code):
                    "Connection failed: \(code)"
                case .sendFailed:
                    "Send failed"
                case .receiveFailed:
                    "Receive failed"
                case .dnsResolutionFailed:
                    "DNS resolution failed"
                case .addressInfoEmpty:
                    "Address info is empty"
                case .noQueue:
                    "No Dispatch Queue"
                case .connectionClosed:
                    "Connection closed"
            }
        }
    }
}
#endif
