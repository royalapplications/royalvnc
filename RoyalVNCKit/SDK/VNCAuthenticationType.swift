import Foundation

@objc(VNCAuthenticationType)
public enum VNCAuthenticationType: Int {
	case vnc
	case appleRemoteDesktop
	case ultraVNCMSLogonII
}

public extension VNCAuthenticationType {
	var requiresUsername: Bool {
		switch self {
			case .vnc:
				return false
			case .appleRemoteDesktop:
				return true
			case .ultraVNCMSLogonII:
				return true
		}
	}
	
	var requiresPassword: Bool {
		switch self {
			case .vnc:
				return true
			case .appleRemoteDesktop:
				return true
			case .ultraVNCMSLogonII:
				return true
		}
	}
}

@objc(VNCAuthenticationTypeUtils)
// swiftlint:disable:next type_name
public class _ObjC_VNCAuthenticationTypeUtils: NSObject {
	@objc
	public static func authenticationTypeRequiresUsername(_ authenticationType: VNCAuthenticationType) -> Bool {
		authenticationType.requiresUsername
	}
	
	@objc
	public static func authenticationTypeRequiresPassword(_ authenticationType: VNCAuthenticationType) -> Bool {
		authenticationType.requiresPassword
	}
}
