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

final class Socket {
    enum Errors: LocalizedError {
        case socketCreationFailed(underlyingErrorCode: Int32?)
        case connectFailed(underlyingErrorCode: Int32)

        var errorDescription: String? {
            switch self {
                case .socketCreationFailed(let underlyingErrorCode):
                    let underlyingErrorCodeStr: String

                    if let underlyingErrorCode {
                        underlyingErrorCodeStr = "\(underlyingErrorCode)"
                    } else {
                        underlyingErrorCodeStr = "N/A"
                    }
                    
                    return "Socket creation failed (\(underlyingErrorCodeStr))"
                case .connectFailed(let underlyingErrorCode):
                    return "Connect failed (\(underlyingErrorCode))"
            }
        }
    }

    let addressInfo: AddressInfo

#if canImport(Glibc)
    let nativeSocket: Int32
#elseif canImport(WinSDK)
    let nativeSocket: SOCKET
#endif

    init(addressInfo: AddressInfo) throws(Errors) {
        let nativeSocket = socket(
            addressInfo.addrInfo.pointee.ai_family,
            addressInfo.addrInfo.pointee.ai_socktype,
            addressInfo.addrInfo.pointee.ai_protocol
        )

#if canImport(Glibc)
        guard nativeSocket >= 0 else {
            throw .socketCreationFailed(underlyingErrorCode: nil)
        }
#elseif canImport(WinSDK)
        guard nativeSocket != INVALID_SOCKET else {
            let lastError = WSAGetLastError()

            throw .socketCreationFailed(underlyingErrorCode: lastError)
        }
#endif

        self.addressInfo = addressInfo
        self.nativeSocket = nativeSocket
    }

    func connect() throws(Errors) {
        let connectResult: Int32

#if canImport(Glibc)
        connectResult = Glibc.connect(
            nativeSocket,
            addressInfo.addrInfo.pointee.ai_addr,
            addressInfo.addrInfo.pointee.ai_addrlen
        )
#elseif canImport(WinSDK)
        connectResult = WinSDK.connect(
            nativeSocket,
            addressInfo.addrInfo.pointee.ai_addr,
            .init(addressInfo.addrInfo.pointee.ai_addrlen)
        )
#endif

        guard connectResult >= 0 else {
            throw .connectFailed(underlyingErrorCode: connectResult)
        }
    }

    deinit {
#if canImport(Glibc)
        close(nativeSocket)
#elseif canImport(WinSDK)
        closesocket(nativeSocket)
#endif
    }
}
#endif