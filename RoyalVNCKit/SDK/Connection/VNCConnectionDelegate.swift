import Foundation

@objc(VNCConnectionDelegate)
public protocol VNCConnectionDelegate: AnyObject {
	@objc
	func connection(_ connection: VNCConnection,
					stateDidChange connectionState: VNCConnection.ConnectionState)
	
	@objc
	func connection(_ connection: VNCConnection,
					credentialFor authenticationType: VNCAuthenticationType,
					completion: @escaping (_ credential: VNCCredential?) -> Void)
	
	@objc
	func connection(_ connection: VNCConnection,
					didCreateFramebuffer framebuffer: VNCFramebuffer)
	
	@objc
	func connection(_ connection: VNCConnection,
					didResizeFramebuffer framebuffer: VNCFramebuffer)
	
	@objc
	func connection(_ connection: VNCConnection,
					framebuffer: VNCFramebuffer,
					didUpdateRegion updatedRegion: CGRect)
	
	@objc
	func connection(_ connection: VNCConnection,
					didUpdateCursor cursor: VNCCursor)
}
