#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(CoreGraphics)
import CoreGraphics
#endif

// MARK: - Queue Management
extension VNCConnection {
	func enqueueKeyEvent(key: VNCKeyCode,
						 isDown: Bool) {
		guard settings.inputMode != .none else { return }
		
		let isARD = state.isAppleRemoteDesktop
		let keyCode = key.rawValue(forAppleRemoteDesktop: isARD)
		
		let keyEvent = VNCProtocol.KeyEvent(isDown: isDown,
											key: keyCode)
		
		logger.logDebug("Enqueuing Key \(keyEvent.description)")
		
		enqueueClientToServerMessage(keyEvent)
	}
    
#if canImport(CoreGraphics)
    func enqueueMousePressEvent(buttons: VNCProtocol.MouseButton,
                                nonNormalizedPosition: CGPoint) {
        enqueueMousePressEvent(buttons: buttons,
                               nonNormalizedX: nonNormalizedPosition.x,
                               nonNormalizedY: nonNormalizedPosition.y)
    }
#endif
    
    func enqueueMousePressEvent(buttons: VNCProtocol.MouseButton,
                                nonNormalizedX: Double,
                                nonNormalizedY: Double) {
        guard settings.inputMode != .none else { return }
        
        let normalizedPosition = normalizedMousePosition(x: nonNormalizedX,
                                                         y: nonNormalizedY)
        
        enqueueMouseEvent(buttons: buttons,
                          position: normalizedPosition)
        
        enqueueMouseEvent(buttons: [ ],
                          position: normalizedPosition)
    }
	
#if canImport(CoreGraphics)
	func enqueueMouseEvent(buttons: VNCProtocol.MouseButton,
						   nonNormalizedPosition: CGPoint) {
        enqueueMouseEvent(buttons: buttons,
                          nonNormalizedX: nonNormalizedPosition.x,
                          nonNormalizedY: nonNormalizedPosition.y)
	}
#endif
    
    func enqueueMouseEvent(buttons: VNCProtocol.MouseButton,
                           nonNormalizedX: Double,
                           nonNormalizedY: Double) {
        guard settings.inputMode != .none else { return }
        
        let normalizedPosition = normalizedMousePosition(x: nonNormalizedX,
                                                         y: nonNormalizedY)
        
        enqueueMouseEvent(buttons: buttons,
                          position: normalizedPosition)
    }
	
	func enqueueMouseEvent(buttons: VNCProtocol.MouseButton,
						   position: VNCProtocol.MousePosition) {
		guard settings.inputMode != .none else { return }
		
		let pointerEvent = VNCProtocol.PointerEvent(buttons: buttons,
													position: position)
		
		enqueueClientToServerMessage(pointerEvent)
	}
	
	func enqueueClientCutTextMessage(_ text: String) {
		let clientCutTextMessage = VNCProtocol.ClientCutText(text: text)
		
		enqueueClientToServerMessage(clientCutTextMessage)
	}
	
	func enqueueClientToServerMessage(_ message: VNCSendableMessage) {
		clientToServerMessageQueue.enqueue(message)
	}
    
#if canImport(CoreGraphics)
	func normalizedMousePosition(cgPoint: CGPoint) -> VNCProtocol.MousePosition {
        normalizedMousePosition(x: cgPoint.x,
                                y: cgPoint.y)
	}
#endif
    
    func normalizedMousePosition(x: Double,
                                 y: Double) -> VNCProtocol.MousePosition {
        var normalizedX = Int(x)
        var normalizedY = Int(y)
        
        let framebufferWidth = Int(framebuffer?.size.width ?? 0)
        let framebufferHeight = Int(framebuffer?.size.height ?? 0)
        
        if normalizedY < 0 {
            normalizedY = 0
        } else if normalizedY > framebufferHeight {
            normalizedY = framebufferHeight
        }
        
        if normalizedX < 0 {
            normalizedX = 0
        } else if normalizedX > framebufferWidth {
            normalizedX = framebufferWidth
        }
        
        let normalizedPosition = VNCProtocol.MousePosition(x: .init(normalizedX),
                                                           y: .init(normalizedY))
        
        return normalizedPosition
    }
}
