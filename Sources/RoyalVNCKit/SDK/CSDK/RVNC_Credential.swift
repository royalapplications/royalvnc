#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@_implementationOnly import RoyalVNCKitC

extension VNCPasswordCredential {
    func retainedPointer() -> rvnc_password_credential_t {
        .retainedPointerFrom(self)
    }
    
    func unretainedPointer() -> rvnc_password_credential_t {
        .unretainedPointerFrom(self)
    }
    
    static func autoreleasePointer(_ pointer: rvnc_password_credential_t) {
        pointer.autorelease(VNCPasswordCredential.self)
    }
    
    static func fromPointer(_ pointer: rvnc_password_credential_t) -> Self {
        pointer.unretainedInstance()
    }
}

extension VNCUsernamePasswordCredential {
    func retainedPointer() -> rvnc_username_password_credential_t {
        .retainedPointerFrom(self)
    }
    
    func unretainedPointer() -> rvnc_username_password_credential_t {
        .unretainedPointerFrom(self)
    }
    
    static func autoreleasePointer(_ pointer: rvnc_username_password_credential_t) {
        pointer.autorelease(VNCUsernamePasswordCredential.self)
    }
    
    static func fromPointer(_ pointer: rvnc_username_password_credential_t) -> Self {
        pointer.unretainedInstance()
    }
}

@_cdecl("rvnc_password_credential_create")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_password_credential_create(_ password: UnsafePointer<CChar>) -> rvnc_password_credential_t {
    let passwordStr = String(cString: password)
    let credential = VNCPasswordCredential(password: passwordStr)
    
    return credential.retainedPointer()
}

@_cdecl("rvnc_password_credential_destroy")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_password_credential_destroy(_ credential: rvnc_password_credential_t) {
    VNCPasswordCredential.autoreleasePointer(credential)
}

@_cdecl("rvnc_username_password_credential_create")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_username_password_credential_create(_ username: UnsafePointer<CChar>, _ password: UnsafePointer<CChar>) -> rvnc_username_password_credential_t {
    let usernameStr = String(cString: username)
    let passwordStr = String(cString: password)
    
    let credential = VNCUsernamePasswordCredential(username: usernameStr,
                                                   password: passwordStr)
    
    return credential.retainedPointer()
}

@_cdecl("rvnc_username_password_credential_destroy")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_username_password_credential_destroy(_ credential: rvnc_username_password_credential_t) {
    VNCUsernamePasswordCredential.autoreleasePointer(credential)
}
