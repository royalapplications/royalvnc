#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

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

#if !os(Linux) && !os(Windows)
#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					framebuffer: VNCFramebuffer,
					didUpdateRegion updatedRegion: CGRect)
#else
	func connection(_ connection: VNCConnection,
					framebuffer: VNCFramebuffer,
					didUpdateRegion updatedRegion: VNCRegion)
#endif

#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					didUpdateCursor cursor: VNCCursor)
}
