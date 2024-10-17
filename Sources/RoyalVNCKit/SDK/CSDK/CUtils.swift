#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(WinSDK)
import WinSDK
#endif

#if canImport(Glibc)
import Glibc
#endif

extension String {
    func duplicateCString() -> UnsafeMutablePointer<CChar>? {
        return strdup(self)
    }
}
