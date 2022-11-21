import Foundation
import Network

// MARK: - Connect/Disconnect
public extension VNCConnection {
	@objc
	func connect() {
		beginConnecting()
	}
	
	@objc
	func disconnect() {
		beginDisconnecting()
	}
}

public extension VNCConnection {
	@objc
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
	@objc
	func mouseMove(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ ],
						  nonNormalizedPosition: mousePosition)
	}
	
	@objc
	func mouseDown(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ .button1 ],
						  nonNormalizedPosition: mousePosition)
	}
	
	@objc
	func rightMouseDown(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ .button3 ],
						  nonNormalizedPosition: mousePosition)
	}
	
	@objc
	func middleMouseDown(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ .button2 ],
						  nonNormalizedPosition: mousePosition)
	}
	
	@objc
	func mouseUp(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ ],
						  nonNormalizedPosition: mousePosition)
	}
	
	@objc
	func mouseWheelUp(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button4 ],
							   nonNormalizedPosition: mousePosition)
	}
	
	@objc
	func mouseWheelDown(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button5 ],
							   nonNormalizedPosition: mousePosition)
	}
	
	@objc
	func mouseWheelLeft(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button6 ],
							   nonNormalizedPosition: mousePosition)
	}
	
	@objc
	func mouseWheelRight(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button7 ],
							   nonNormalizedPosition: mousePosition)
	}
}

// MARK: - Keyboard Input
public extension VNCConnection {
	func keyDown(_ key: VNCKeyCode) {
		enqueueKeyEvent(key: key,
						isDown: true)
	}
	
	@objc(keyDown:)
	func _objc_keyDown(_ key: UInt32) {
		keyDown(.init(key))
	}
	
	func keyUp(_ key: VNCKeyCode) {
		enqueueKeyEvent(key: key,
						isDown: false)
	}
	
	@objc(keyUp:)
	func _objc_keyUp(_ key: UInt32) {
		keyUp(.init(key))
	}
}
