#if os(Windows)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import ucrt
import WinSDK
import Dispatch

// TODO: All of this is very hacky and NOT fully fleshed out!
final class WindowsNetworkConnection: NetworkConnection {
    let settings: NetworkConnectionSettings

    private var socket: SOCKET?
    private var queue: DispatchQueue?

    private(set) var statusUpdateHandler: NetworkConnectionStatusUpdateHandler?

    private(set) var status: NetworkConnectionStatus = .unknown("None") {
        didSet {
            statusUpdateHandler?(status)
        }
    }

    init(settings: NetworkConnectionSettings) {
        self.settings = settings

        do {
            try intializeWinsock()
        } catch {
            fatalError("Initializing Winsock failed: \(error.humanReadableDescription)")
        }

    }

    deinit {
        guard let socket else { return }

        closesocket(socket)
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
                ai_socktype: SOCK_STREAM,
                ai_protocol: 0,
                ai_addrlen: 0,
                ai_canonname: nil,
                ai_addr: nil,
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
                self.status = .failed(WinsockError.dnsResolutionFailed)

                return
            }

            guard let addrinfoResult else {
                self.status = .failed(WinsockError.addressInfoEmpty)

                return
            }

            defer {
                freeaddrinfo(addrinfoResult)
            }

            let socket = WinSDK.socket(
                addrinfoResult.pointee.ai_family,
                addrinfoResult.pointee.ai_socktype,
                addrinfoResult.pointee.ai_protocol
            )

            guard socket != INVALID_SOCKET else {
                let lastError = WSAGetLastError()
                self.status = .failed(WinsockError.winsockError(code: lastError))

                return
            }

            let connectResult = connect(
                socket,
                addrinfoResult.pointee.ai_addr,
                .init(addrinfoResult.pointee.ai_addrlen)
            )

            guard connectResult >= 0 else {
                self.status = .failed(WinsockError.connectionFailed(code: connectResult))
                
                return
            }

            self.socket = socket
            self.status = .ready
        }
    }

    private func intializeWinsock() throws {
        try intializeWinsock(2, 2)
    }
    
    private func intializeWinsock(_ versionA: UInt8, _ versionB: UInt8) throws {
        func makeWord(_ a: UInt8, _ b: UInt8) -> UInt16 {
            return UInt16(a) | (UInt16(b) << 8)
        }
        
        let wVersionRequested = makeWord(versionA, versionB)
        
        var lpWSAData = WSADATA()
        let status = WSAStartup(wVersionRequested, &lpWSAData)
        
        guard status == 0 else {
            throw WinsockError.initError(statusValue: status)
        }
    }
}

extension WindowsNetworkConnection: NetworkConnectionReading {
	func read(minimumLength: Int,
              maximumLength: Int) async throws -> Data {
        guard let queue else {
            throw WinsockError.noQueue
        }

        guard let socket else {
            throw WinsockError.socketCreationFailed
        }

        let bufferSize = maximumLength

		return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                var buffer = [UInt8](repeating: 0, count: bufferSize)
        
                let bytesRead = recv(
                    socket,
                    &buffer,
                    .init(bufferSize),
                    0
                )

                // Handle connection closure
                if bytesRead == 0 {
                    // TODO
                    continuation.resume(throwing: WinsockError.connectionClosed)

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

extension WindowsNetworkConnection: NetworkConnectionWriting {
	func write(data: Data) async throws {
        guard let queue else {
            throw WinsockError.noQueue
        }

        guard let socket else {
            throw WinsockError.socketCreationFailed
        }

		return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let bytesToSend = [UInt8](data)
                
                let bytesSent = send(
                    socket,
                    bytesToSend,
                    .init(bytesToSend.count),
                    0
                )
                
                if bytesSent < 0 {
                    continuation.resume(throwing: WinsockError.sendFailed)
                } else {
                    continuation.resume()
                }
            }
        }
	}
}

private extension WindowsNetworkConnection {
    // MARK: - Enum for Socket Errors
    enum WinsockError: LocalizedError {
        case socketCreationFailed
        case connectionFailed(code: Int32)
        case sendFailed
        case receiveFailed
        case dnsResolutionFailed
        case addressInfoEmpty
        case noQueue
        case connectionClosed
        case initError(statusValue: Int32)
        case winsockError(code: Int32)

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
                case .initError(let statusValue):
                    "WSAStartup failed with \(statusValue)"
                case .winsockError(let code):
                    "Winsock error \(code)"            
            }
        }
    }
}
#endif
