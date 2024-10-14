// TODO: FoundationEssentials
import Foundation

#if canImport(ObjectiveC)
@objc(VNCConnectionDelegate)
#endif
public protocol VNCConnectionDelegate: AnyObject {
#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					stateDidChange connectionState: VNCConnection.ConnectionState)
	
#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					credentialFor authenticationType: VNCAuthenticationType,
					completion: @escaping (_ credential: VNCCredential?) -> Void)
	
#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					didCreateFramebuffer framebuffer: VNCFramebuffer)
	
#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					didResizeFramebuffer framebuffer: VNCFramebuffer)
	
#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					framebuffer: VNCFramebuffer,
					didUpdateRegion updatedRegion: CGRect)
	
#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					didUpdateCursor cursor: VNCCursor)
}
