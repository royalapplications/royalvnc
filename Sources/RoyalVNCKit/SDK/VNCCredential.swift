import Foundation

#if canImport(ObjectiveC)
@objc(VNCCredential)
#endif
public protocol VNCCredential: AnyObject { }

#if canImport(ObjectiveC)
@objc(VNCPasswordCredential)
#endif
public class VNCPasswordCredential: NSObjectOrAnyObject, VNCCredential {
#if canImport(ObjectiveC)
    @objc
#endif
	public let password: String
	
#if canImport(ObjectiveC)
    @objc
#endif
	public init(password: String) {
		self.password = password
	}
}

#if canImport(ObjectiveC)
@objc(VNCUsernamePasswordCredential)
#endif
public class VNCUsernamePasswordCredential: NSObjectOrAnyObject, VNCCredential {
#if canImport(ObjectiveC)
    @objc
#endif
	public let username: String
	
#if canImport(ObjectiveC)
    @objc
#endif
	public let password: String
	
#if canImport(ObjectiveC)
    @objc
#endif
	public init(username: String,
				password: String) {
		self.username = username
		self.password = password
	}
}
