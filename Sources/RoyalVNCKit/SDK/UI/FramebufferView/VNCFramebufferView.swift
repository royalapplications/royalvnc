#if os(macOS) || os(iOS)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(ObjectiveC)
@objc(VNCFramebufferView)
#endif
public protocol VNCFramebufferView: AnyObject {
#if canImport(ObjectiveC)
    @objc
#endif
	var framebufferSize: CGSize { get }

#if canImport(ObjectiveC)
    @objc
#endif
	var connection: VNCConnection? { get }

#if canImport(ObjectiveC)
    @objc
#endif
	var settings: VNCConnection.Settings { get }

#if canImport(ObjectiveC)
    @objc
#endif
	var scaleRatio: CGFloat { get }

#if canImport(ObjectiveC)
    @objc
#endif
	var contentRect: CGRect { get }

#if canImport(ObjectiveC)
    @objc
#endif
	var scrollStep: CGFloat { get }

#if canImport(ObjectiveC)
    @objc
#endif
	var accumulatedScrollDeltaX: CGFloat { get set }

#if canImport(ObjectiveC)
    @objc
#endif
	var accumulatedScrollDeltaY: CGFloat { get set }

#if canImport(ObjectiveC)
    @objc
#endif
    func connection(_ connection: VNCConnection,
                    didUpdateFramebuffer framebuffer: VNCFramebuffer,
                    x: UInt16, y: UInt16,
                    width: UInt16, height: UInt16)

#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					didUpdateCursor cursor: VNCCursor)
}
#endif
