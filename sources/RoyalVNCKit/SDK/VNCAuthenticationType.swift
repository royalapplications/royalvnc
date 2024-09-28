import Foundation

#if canImport(ObjectiveC)
@objc(VNCAuthenticationType)
#endif
public enum VNCAuthenticationType: Int {
	case vnc
	case appleRemoteDesktop
	case ultraVNCMSLogonII
}

public extension VNCAuthenticationType {
	var requiresUsername: Bool {
		switch self {
			case .vnc:
				false
			case .appleRemoteDesktop:
				true
			case .ultraVNCMSLogonII:
				true
		}
	}
	
	var requiresPassword: Bool {
		switch self {
			case .vnc:
				true
			case .appleRemoteDesktop:
				true
			case .ultraVNCMSLogonII:
				true
		}
	}
}

#if canImport(ObjectiveC)
@objc(VNCAuthenticationTypeUtils)
#endif
// swiftlint:disable:next type_name
public class _ObjC_VNCAuthenticationTypeUtils: NSObject {
#if canImport(ObjectiveC)
    @objc
#endif
	public static func authenticationTypeRequiresUsername(_ authenticationType: VNCAuthenticationType) -> Bool {
		authenticationType.requiresUsername
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	public static func authenticationTypeRequiresPassword(_ authenticationType: VNCAuthenticationType) -> Bool {
		authenticationType.requiresPassword
	}
}
