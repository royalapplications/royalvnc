#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import Dispatch

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
		logger.logDebug("Received server message type \(messageType)")
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

            case 130:
                try await handleTightFileListMessage()

            case 131:
                try await handleTightFileDownloadMessage()

            case 132, 133:
                try await handleTightFileFailureMessage(messageType: messageType)

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

		/*
		// Write out the framebuffer for testing purposes
		try framebuffer.writeSurface()
		*/

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

		DispatchQueue.main.async { [weak self] in
			self?.handleClipboardMessage(serverCutText)
		}
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
		state.areContinuousUpdatesEnabled = false

		if first {
			logger.logDebug("Continuous Updates supported (server sent EndOfContinuousUpdates)")
		} else {
			logger.logDebug("Disabling Continuous Updates")
		}

		try await sendFramebufferUpdateRequest()
	}

    func handleTightFileListMessage() async throws {
        guard supportsTightFileDownload else { throw VNCError.protocol(.unsupportedServerToClientMessage(messageType: 130)) }
        let header = try await connection.read(length: 7)
        guard header.count == 7 else { throw VNCError.protocol(.invalidData) }
        let count = Int(header.withUnsafeBytes {
            UInt16(bigEndian: $0.loadUnaligned(fromByteOffset: 1, as: UInt16.self))
        })
        let compressedLength = Int(header.withUnsafeBytes {
            UInt16(bigEndian: $0.loadUnaligned(fromByteOffset: 5, as: UInt16.self))
        })
        guard count <= TightFileTransfer.maximumListingBytes / 8,
              compressedLength <= TightFileTransfer.maximumListingBytes else {
            throw VNCError.protocol(.invalidData)
        }
        let tail = try await connection.read(length: count * 8 + compressedLength)
        guard tail.count == count * 8 + compressedLength else { throw VNCError.protocol(.invalidData) }
        var body = header
        body.append(tail)
        let entries = try TightFileTransfer.decodeFileList(body).map(VNCRemoteFile.init)
        deliverFileTransferEvent(.fileList(entries))
    }

    func handleTightFileDownloadMessage() async throws {
        guard supportsTightFileDownload else { throw VNCError.protocol(.unsupportedServerToClientMessage(messageType: 131)) }
        let header = try await connection.read(length: 5)
        guard header.count == 5 else { throw VNCError.protocol(.invalidData) }
        let realLength = Int(header.withUnsafeBytes {
            UInt16(bigEndian: $0.loadUnaligned(fromByteOffset: 1, as: UInt16.self))
        })
        let compressedLength = Int(header.withUnsafeBytes {
            UInt16(bigEndian: $0.loadUnaligned(fromByteOffset: 3, as: UInt16.self))
        })
        guard realLength <= TightFileTransfer.maximumChunkBytes,
              compressedLength <= TightFileTransfer.maximumChunkBytes else {
            throw VNCError.protocol(.invalidData)
        }
        let trailerLength = realLength == 0 && compressedLength == 0 ? 4 : 0
        guard (realLength == 0) == (compressedLength == 0) else { throw VNCError.protocol(.invalidData) }
        let tail = try await connection.read(length: compressedLength + trailerLength)
        guard tail.count == compressedLength + trailerLength else { throw VNCError.protocol(.invalidData) }
        var body = header
        body.append(tail)
        let chunk = try TightFileTransfer.decodeDownloadChunk(body)
        if let modificationTime = chunk.modificationTime {
            deliverFileTransferEvent(.downloadFinished(modificationTime: modificationTime))
        } else {
            deliverFileTransferEvent(.downloadData(chunk.data))
        }
    }

    func handleTightFileFailureMessage(messageType: UInt8) async throws {
        guard supportsTightFileTransfer else { throw VNCError.protocol(.unsupportedServerToClientMessage(messageType: messageType)) }
        try await connection.readPadding()
        let length = Int(try await connection.readUInt16())
        guard length <= TightFileTransfer.maximumPathBytes else { throw VNCError.protocol(.invalidData) }
        let data = try await connection.read(length: length)
        guard data.count == length, let reason = String(data: data, encoding: .utf8) else {
            throw VNCError.protocol(.invalidData)
        }
        deliverFileTransferEvent(.failed(reason))
    }

    func deliverFileTransferEvent(_ event: VNCFileTransferEvent) {
        DispatchQueue.main.async { [weak self] in self?.fileTransferHandler?(event) }
    }
}
