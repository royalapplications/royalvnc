#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// MARK: - Server to Client Messages
extension VNCConnection {
	func startReceiveLoop() {
        logger.logDebug("Starting receive loop")
        
        receiveTask = Task(priority: taskPriority) {
			while !state.disconnectRequested,
                  connection.isReady {
				do {
					try await receive()
				} catch {
					handleBreakingError(error)
				}
			}
		}
	}
}

private extension VNCConnection {
	func receive() async throws {
		guard !state.disconnectRequested else {
			// Just ignore, since disconnect has already been requested
			return
		}
		
        guard connection.isReady else {
			throw VNCError.connection(.notReady)
		}
		
		let serverToClientMessage = try await VNCProtocol.ServerToClientMessage.receive(connection: connection)
		
		try await didReceive(messageType: serverToClientMessage.messageType)
	}
	
	func didReceive(messageType: UInt8) async throws {
		switch messageType {
			case VNCProtocol.FramebufferUpdate.messageType:
				try await handleFramebufferUpdateMessage()
				
			case VNCProtocol.SetColourMapEntries.messageType:
				try await handleSetColourMapEntriesMessage()
				
			case VNCProtocol.ServerCutText.messageType:
				try await handleServerCutTextMessage()
				
			case VNCProtocol.Bell.messageType:
				try await handleBellMessage()
				
			case VNCProtocol.EndOfContinuousUpdates.messageType:
				try await handleEndOfContinuousUpdatesMessage()
				
			default:
				throw VNCError.protocol(.unsupportedServerToClientMessage(messageType: messageType))
		}
	}
	
	func handleFramebufferUpdateMessage() async throws {
		guard let framebuffer = framebuffer else {
			throw VNCError.protocol(.framebufferUpdateReceivedWithoutFramebuffer)
		}
		
		logger.logDebug("Receiving Framebuffer Update")
		
		let framebufferUpdate = try await VNCProtocol.FramebufferUpdate.receive(connection: connection,
																				framebuffer: framebuffer,
																				encodings: encodings,
																				logger: logger)
		
		logger.logDebug("Received Framebuffer Update: \(framebufferUpdate)")
		
		try await sendFramebufferUpdateRequest()
	}
	
	func handleSetColourMapEntriesMessage() async throws {
		guard let framebuffer = framebuffer else {
			throw VNCError.protocol(.setColourMapEntriesReceivedWithoutFramebuffer)
		}
		
		logger.logDebug("Receiving Colour Map Entries")
		
		let colourMapEntries = try await VNCProtocol.SetColourMapEntries.receive(connection: connection,
																				 logger: logger)
		
		logger.logDebug("Received Colour Map Entries")
		
		framebuffer.updateColorMap(colourMapEntries)
	}
	
	func handleServerCutTextMessage() async throws {
		logger.logDebug("Receiving Clipboard Text from Server")
		
		let serverCutText = try await VNCProtocol.ServerCutText.receive(connection: connection,
																		logger: logger)
		
		let text = serverCutText.text
		
		logger.logDebug("Received Clipboard Text from Server")
		
		guard settings.isClipboardRedirectionEnabled else { return }
		
		clipboard.text = text
	}
	
	func handleBellMessage() async throws {
		logger.logDebug("Receiving Bell Message from Server")
		
		_ = try await VNCProtocol.Bell.receive(connection: connection,
											   logger: logger)
		
		logger.logDebug("Received Bell Message from Server")
		
		systemSound.play()
	}
	
	func handleEndOfContinuousUpdatesMessage() async throws {
		let first = !state.areContinuousUpdatesSupported
		
		state.areContinuousUpdatesSupported = true
		
		if first {
			state.areContinuousUpdatesEnabled = true
			
			logger.logDebug("Enabling Continuous Updates")
		} else {
			state.areContinuousUpdatesEnabled = false
			
			logger.logDebug("Disabling Continuous Updates")
			
			try await sendFramebufferUpdateRequest()
		}
	}
}
