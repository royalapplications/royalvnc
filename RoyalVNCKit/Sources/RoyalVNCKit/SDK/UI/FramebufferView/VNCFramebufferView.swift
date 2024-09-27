import Foundation

@objc(VNCFramebufferView)
public protocol VNCFramebufferView: AnyObject {
	@objc
	var framebufferSize: CGSize { get }
	
	@objc
	var connection: VNCConnection? { get }
	
	@objc
	var settings: VNCConnection.Settings { get }
	
	@objc
	var scaleRatio: CGFloat { get }
	
	@objc
	var contentRect: CGRect { get }
	
	@objc
	var scrollStep: CGFloat { get }
	
	@objc
	var accumulatedScrollDeltaX: CGFloat { get set }
	
	@objc
	var accumulatedScrollDeltaY: CGFloat { get set }
	
	@objc
	func connection(_ connection: VNCConnection,
					framebuffer: VNCFramebuffer,
					didUpdateRegion updatedRegion: CGRect)
	
	@objc
	func connection(_ connection: VNCConnection,
					didUpdateCursor cursor: VNCCursor)
}
