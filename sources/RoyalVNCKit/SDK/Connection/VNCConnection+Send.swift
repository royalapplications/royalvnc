import Foundation
import Network

// MARK: - Client to Server Messages
extension VNCConnection {
	func startSendLoop() {
        logger.logDebug("Starting send loop")
        
		sendTask = Task(priority: taskPriority) {
			while !state.disconnectRequested,
					connection.state == .ready {
				do {
					try await send()
				} catch {
					handleBreakingError(error)
				}
			}
		}
	}
	
	func sendFramebufferUpdateRequest() async throws {
		guard let framebuffer = framebuffer else { return }
		guard !state.areContinuousUpdatesEnabled else { return }
		
		let incremental = state.incrementalUpdatesEnabled
		
		let fullFramebufferRegion = VNCRegion(location: .zero,
											  size: framebuffer.size)
		
		// Request next update
		try await sendFramebufferUpdateRequest(incremental: incremental,
											   region: fullFramebufferRegion)
		
		if !incremental {
			state.incrementalUpdatesEnabled = true
		}
	}
	
	func sendEnableContinuousUpdates() async throws {
		guard let framebuffer = framebuffer else { return }
		guard state.areContinuousUpdatesEnabled else { return }
		
		let fullFramebufferRegion = VNCRegion(location: .zero,
											  size: framebuffer.size)
		
		try await sendEnableContinuousUpdates(enable: true,
											  region: fullFramebufferRegion)
	}
}

private extension VNCConnection {
	func send() async throws {
		guard !state.disconnectRequested,
			  connection.state == .ready,
			  let message = clientToServerMessageQueue.dequeue() else {
			try await Task.sleep(seconds: 0.01)
			
			return
		}
		
		try await sendMessage(message)
	}
	
	func sendFramebufferUpdateRequest(incremental: Bool,
									  region: VNCRegion) async throws {
		let framebufferUpdateRequest = VNCProtocol.FramebufferUpdateRequest(incremental: incremental,
																			xPosition: region.location.x,
																			yPosition: region.location.y,
																			width: region.size.width,
																			height: region.size.height)
		
		try await sendMessage(framebufferUpdateRequest)
	}
	
	func sendEnableContinuousUpdates(enable: Bool,
									 region: VNCRegion) async throws {
		let message = VNCProtocol.EnableContinuousUpdates(enable: enable,
														  xPosition: region.x,
														  yPosition: region.y,
														  width: region.width,
														  height: region.height)
		
		try await sendMessage(message)
	}
	
	func sendMessage(_ message: VNCSendableMessage) async throws {
		try await message.send(connection: connection)
	}
}
