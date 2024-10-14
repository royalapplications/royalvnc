// TODO: FoundationEssentials
import Foundation

extension VNCFramebufferView {
	func frameSizeExceedsFramebufferSize(_ frameSize: CGSize) -> Bool {
		return frameSize.width >= framebufferSize.width &&
			   frameSize.height >= framebufferSize.height
	}
	
	func handleScrollWheel(scrollDelta: CGPoint,
						   hasPreciseScrollingDeltas: Bool,
						   mousePosition: CGPoint) {
		if hasPreciseScrollingDeltas {
			handlePreciseScrollingDelta(scrollDelta,
										mousePosition: mousePosition)
		} else {
			handleImpreciseScrollingDelta(scrollDelta,
										  mousePosition: mousePosition)
		}
	}
	
	func handleImpreciseScrollingDelta(_ scrollDelta: CGPoint,
									   mousePosition: CGPoint) {
		guard let connection = self.connection else { return }
		
		if scrollDelta.x < 0 {
			connection.mouseWheelRight(mousePosition)
		} else if scrollDelta.x > 0 {
			connection.mouseWheelLeft(mousePosition)
		}
		
		if scrollDelta.y < 0 {
			connection.mouseWheelDown(mousePosition)
		} else if scrollDelta.y > 0 {
			connection.mouseWheelUp(mousePosition)
		}
	}
	
	func handlePreciseScrollingDelta(_ scrollDelta: CGPoint,
									 mousePosition: CGPoint) {
		accumulatedScrollDeltaX += scrollDelta.x
		accumulatedScrollDeltaY += scrollDelta.y
		
//		#if DEBUG
//		connection.logger.logInfo("Accumulated Scroll Delta: {x: \(accumulatedScrollDeltaX); y: \(accumulatedScrollDeltaY)}")
//		#endif
		
		if abs(accumulatedScrollDeltaX) >= scrollStep {
			while abs(accumulatedScrollDeltaX) >= scrollStep {
				if accumulatedScrollDeltaX < 0 {
					connection?.mouseWheelRight(mousePosition)
					
					accumulatedScrollDeltaX += scrollStep
				} else if accumulatedScrollDeltaX > 0 {
					connection?.mouseWheelLeft(mousePosition)
					
					accumulatedScrollDeltaX -= scrollStep
				}
			}
			
			accumulatedScrollDeltaX = 0
		}
		
		if abs(accumulatedScrollDeltaY) >= scrollStep {
			while abs(accumulatedScrollDeltaY) >= scrollStep {
				if accumulatedScrollDeltaY < 0 {
					connection?.mouseWheelDown(mousePosition)
					
					accumulatedScrollDeltaY += scrollStep
				} else if accumulatedScrollDeltaY > 0 {
					connection?.mouseWheelUp(mousePosition)
					
					accumulatedScrollDeltaY -= scrollStep
				}
			}
			
			accumulatedScrollDeltaY = 0
		}
	}
}
