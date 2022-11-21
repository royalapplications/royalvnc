import Foundation

@objc(VNCCredential)
public protocol VNCCredential: AnyObject { }

@objc(VNCPasswordCredential)
public class VNCPasswordCredential: NSObject, VNCCredential {
	@objc
	public let password: String
	
	@objc
	public init(password: String) {
		self.password = password
	}
}

@objc(VNCUsernamePasswordCredential)
public class VNCUsernamePasswordCredential: NSObject, VNCCredential {
	@objc
	public let username: String
	
	@objc
	public let password: String
	
	@objc
	public init(username: String,
				password: String) {
		self.username = username
		self.password = password
	}
}
