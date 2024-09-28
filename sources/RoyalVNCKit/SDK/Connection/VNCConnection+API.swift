import Foundation

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
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseMove(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ ],
						  nonNormalizedPosition: mousePosition)
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseDown(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ .button1 ],
						  nonNormalizedPosition: mousePosition)
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	func rightMouseDown(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ .button3 ],
						  nonNormalizedPosition: mousePosition)
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	func middleMouseDown(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ .button2 ],
						  nonNormalizedPosition: mousePosition)
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseUp(_ mousePosition: CGPoint) {
		enqueueMouseEvent(buttons: [ ],
						  nonNormalizedPosition: mousePosition)
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseWheelUp(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button4 ],
							   nonNormalizedPosition: mousePosition)
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseWheelDown(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button5 ],
							   nonNormalizedPosition: mousePosition)
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	func mouseWheelLeft(_ mousePosition: CGPoint) {
		enqueueMousePressEvent(buttons: [ .button6 ],
							   nonNormalizedPosition: mousePosition)
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
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
