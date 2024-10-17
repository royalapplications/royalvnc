#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@_implementationOnly import RoyalVNCKitC

final class VNCCredential_C {
    let username: String?
    let password: String?
    
    init(username: String?,
         password: String?) {
        self.username = username
        self.password = password
    }
}

extension VNCCredential_C {
    func retainedPointer() -> rvnc_credential_t {
        .retainedPointerFrom(self)
    }
    
    func unretainedPointer() -> rvnc_credential_t {
        .unretainedPointerFrom(self)
    }
    
    static func autoreleasePointer(_ pointer: rvnc_credential_t) {
        pointer.autorelease(VNCCredential_C.self)
    }
    
    static func fromPointer(_ pointer: rvnc_credential_t) -> Self {
        pointer.unretainedInstance()
    }
}

@_cdecl("rvnc_credential_create")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_credential_create(_ username: UnsafePointer<CChar>?,
                                   _ password: UnsafePointer<CChar>?) -> rvnc_credential_t {
    let usernameStr: String?
    let passwordStr: String?
    
    if let username {
        usernameStr = String(cString: username)
    } else {
        usernameStr = nil
    }
    
    if let password {
        passwordStr = String(cString: password)
    } else {
        passwordStr = nil
    }
    
    let credential = VNCCredential_C(username: usernameStr,
                                     password: passwordStr)
    
    return credential.retainedPointer()
}
