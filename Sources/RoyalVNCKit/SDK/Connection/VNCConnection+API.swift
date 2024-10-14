#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// MARK: - Connect/Disconnect
public extension VNCConnection {
#if canImport(ObjectiveC)
	@objc
#endif
	func connect() {
		beginConnecting()
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	func disconnect() {
		beginDisconnecting()
	}
}

public extension VNCConnection {
#if canImport(ObjectiveC)
    @objc
#endif
	func updateColorDepth(_ colorDepth: Settings.ColorDepth) {
		guard let framebuffer = framebuffer else { return }
		
		let newPixelFormat = VNCProtocol.PixelFormat(depth: colorDepth.rawValue)
		
		state.pixelFormat = newPixelFormat
		
		let sendPixelFormatMessage = VNCProtocol.SetPixelFormat(pixelFormat: newPixelFormat)
		
		clientToServerMessageQueue.enqueue(sendPixelFormatMessage)
		
		recreateFramebuffer(size: framebuffer.size,
							screens: framebuffer.screens,
							pixelFormat: newPixelFormat)
	}
}

// MARK: - Mouse Input
public extension VNCConnection {
#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseMove(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ ],
						  nonNormalizedPosition: mousePosition)
	}
#else
	func mouseMove(x: Double, y: Double) {
		enqueueMouseEvent(buttons: [ ],
						  nonNormalizedX: x,
						  nonNormalizedY: y)
	}
#endif

#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseDown(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ .button1 ],
						  nonNormalizedPosition: mousePosition)
	}
#else
	func mouseDown(x: Double, y: Double) {
		enqueueMouseEvent(buttons: [ .button1 ],
						  nonNormalizedX: x,
						  nonNormalizedY: y)
	}
#endif

#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
    @objc
#endif
	func rightMouseDown(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ .button3 ],
						  nonNormalizedPosition: mousePosition)
	}
#else
	func rightMouseDown(x: Double, y: Double) {
		enqueueMouseEvent(buttons: [ .button3 ],
						  nonNormalizedX: x,
						  nonNormalizedY: y)
	}
#endif

#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
    @objc
#endif
	func middleMouseDown(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ .button2 ],
						  nonNormalizedPosition: mousePosition)
	}
#else
	func middleMouseDown(x: Double, y: Double) {
		enqueueMouseEvent(buttons: [ .button2 ],
						  nonNormalizedX: x,
						  nonNormalizedY: y)
	}
#endif

#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseUp(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ ],
						  nonNormalizedPosition: mousePosition)
	}
#else
	func mouseUp(x: Double, y: Double) {
		enqueueMouseEvent(buttons: [ ],
						  nonNormalizedX: x,
						  nonNormalizedY: y)
	}
#endif

#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseWheelUp(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button4 ],
							   nonNormalizedPosition: mousePosition)
	}
#else
	func mouseWheelUp(x: Double, y: Double) {
		enqueueMousePressEvent(buttons: [ .button4 ],
							   nonNormalizedX: x,
							   nonNormalizedY: y)
	}
#endif
	
#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseWheelDown(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button5 ],
							   nonNormalizedPosition: mousePosition)
	}
#else
	func mouseWheelDown(x: Double, y: Double) {
		enqueueMousePressEvent(buttons: [ .button5 ],
							   nonNormalizedX: x,
							   nonNormalizedY: y)
	}
#endif

#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseWheelLeft(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button6 ],
							   nonNormalizedPosition: mousePosition)
	}
#else
	func mouseWheelLeft(x: Double, y: Double) {
		enqueueMousePressEvent(buttons: [ .button6 ],
							   nonNormalizedX: x,
							   nonNormalizedY: y)
	}
#endif

#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseWheelRight(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button7 ],
							   nonNormalizedPosition: mousePosition)
	}
#else
	func mouseWheelRight(x: Double, y: Double) {
		enqueueMousePressEvent(buttons: [ .button7 ],
							   nonNormalizedX: x,
							   nonNormalizedY: y)
	}
#endif
}

// MARK: - Keyboard Input
public extension VNCConnection {
	func keyDown(_ key: VNCKeyCode) {
		enqueueKeyEvent(key: key,
						isDown: true)
	}
	
#if canImport(ObjectiveC)
	@objc(keyDown:)
#endif
	func _objc_keyDown(_ key: UInt32) {
		keyDown(.init(key))
	}
	
	func keyUp(_ key: VNCKeyCode) {
		enqueueKeyEvent(key: key,
						isDown: false)
	}

#if canImport(ObjectiveC)
	@objc(keyUp:)
#endif
	func _objc_keyUp(_ key: UInt32) {
		keyUp(.init(key))
	}
}
