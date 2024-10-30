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

final class AddressInfo {
    enum Errors: LocalizedError {
        case dnsResolutionFailed
        case addressInfoEmpty

        var errorDescription: String? {
            switch self {
                case .dnsResolutionFailed:
                    "DNS resolution failed"
                case .addressInfoEmpty:
                    "Address info is empty"
            }
        }
    }

    let addrInfo: UnsafeMutablePointer<addrinfo>

    init(host: String,
         port: UInt16) throws(Errors) {
        let sockstream = SOCK_STREAM

#if canImport(Glibc)
        let socktype = Int32(sockstream.rawValue)
#elseif canImport(WinSDK)
        let socktype = sockstream
#endif

        var hints = addrinfo(
            ai_flags: AI_PASSIVE,
            ai_family: AF_INET,
            ai_socktype: socktype,
            ai_protocol: 0,
            ai_addrlen: 0,
            ai_addr: nil,
            ai_canonname: nil,
            ai_next: nil
        )

        var addrInfo: UnsafeMutablePointer<addrinfo>?

        // Resolve the address
        let getaddrinfoStatus = getaddrinfo(
            host,
            "\(port)",
            &hints, 
            &addrInfo
        )
        
        guard getaddrinfoStatus == 0 else {
            throw .dnsResolutionFailed
        }

        guard let addrInfo else {
            throw .addressInfoEmpty
        }

        self.addrInfo = addrInfo
    }

    deinit {
        freeaddrinfo(addrInfo)
    }
}
#endif