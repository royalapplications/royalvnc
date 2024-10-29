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
    func mouseMove(x: Double, y: Double) {
        enqueueMouseEvent(nonNormalizedX: x,
                          nonNormalizedY: y)
    }
    
    func mouseButtonDown(_ button: VNCMouseButton,
                         x: Double, y: Double) {
        updateMouseButtonState(button: button,
                               isDown: true)
        
        enqueueMouseEvent(nonNormalizedX: x,
                          nonNormalizedY: y)
    }
    
    func mouseButtonUp(_ button: VNCMouseButton,
                       x: Double, y: Double) {
        updateMouseButtonState(button: button,
                               isDown: false)
        
        enqueueMouseEvent(nonNormalizedX: x,
                          nonNormalizedY: y)
    }
    
    func mouseWheel(_ wheel: VNCMouseWheel,
                    x: Double, y: Double,
                    steps: UInt32) {
        for _ in 0..<steps {
            updateMouseButtonState(wheel: wheel,
                                   isDown: true)
            
            enqueueMouseEvent(nonNormalizedX: x,
                              nonNormalizedY: y)
            
            updateMouseButtonState(wheel: wheel,
                                   isDown: false)
        }
    }
}

extension VNCConnection {
    func updateMouseButtonState(button: VNCMouseButton,
                                isDown: Bool) {
        updateMouseButtonState(mousePointerButton: button.mousePointerButton,
                               isDown: isDown)
    }
    
    func updateMouseButtonState(wheel: VNCMouseWheel,
                                isDown: Bool) {
        updateMouseButtonState(mousePointerButton: wheel.mousePointerButton,
                               isDown: isDown)
    }
    
    func updateMouseButtonState(mousePointerButton: VNCProtocol.MousePointerButton,
                                isDown: Bool) {
        if isDown {
            mouseButtonState.insert(mousePointerButton)
        } else {
            mouseButtonState.remove(mousePointerButton)
        }
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
