#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension VNCProtocol {
	struct FramebufferUpdate: VNCReceivableMessage {
		static let messageType: UInt8 = 0

		let messageType: UInt8
		let rectangles: [VNCProtocol.Rectangle]
	}
}

extension VNCProtocol.FramebufferUpdate {
	static func receive(connection: NetworkConnectionReading,
						framebuffer: VNCFramebuffer,
						encodings: Encodings,
						logger: VNCLogger) async throws -> Self {
		try await connection.readPadding()
		let numberOfRectangles = try await connection.readUInt16()

		logger.logDebug("Got \(numberOfRectangles) rectangles to read from framebuffer update")

		framebuffer.beginBatchUpdates()
		defer { framebuffer.endBatchUpdates() }

#if DEBUG
		if numberOfRectangles == 65535 {
			logger.logDebug("Likely encountered a framebuffer update with LastRect")
		}
#endif

		var rectangles = [VNCProtocol.Rectangle]()

		for idx in 0..<numberOfRectangles {
			logger.logDebug("Reading rectangle header \(idx + 1)/\(numberOfRectangles)")

			let rectangle = try await VNCProtocol.Rectangle.receive(connection: connection)

			logger.logDebug("Got rectangle header \(idx + 1)/\(numberOfRectangles): \(rectangle)")

			let encodingType = rectangle.encodingType

			guard let encoding = encodings[.init(encodingType)] else {
				throw VNCError.protocol(.unsupportedEncoding(encodingType: .init(encodingType)))
			}

			if let frameEncoding = encoding as? VNCFrameEncoding {
				logger.logDebug("Decoding frame rectangle \(idx + 1)/\(numberOfRectangles)")

				try await frameEncoding.decodeRectangle(rectangle,
														framebuffer: framebuffer,
														connection: connection,
														logger: logger)

				logger.logDebug("Finished decoding frame rectangle \(idx + 1)/\(numberOfRectangles)")

				rectangles.append(rectangle)
			} else if let pseudoEncoding = encoding as? VNCPseudoEncoding {
				if pseudoEncoding as? VNCProtocol.LastRectEncoding != nil {
					break
				} else if let receivablePseudoEncoding = pseudoEncoding as? VNCReceivablePseudoEncoding {
					logger.logDebug("Decoding pseudo rectangle \(idx + 1)/\(numberOfRectangles)")

					try await receivablePseudoEncoding.receive(rectangle,
															   framebuffer: framebuffer,
															   connection: connection,
															   logger: logger)

					logger.logDebug("Finished decoding pseudo rectangle \(idx + 1)/\(numberOfRectangles)")
				} else {
					throw VNCError.protocol(.notImplemented(feature: "Pseudo Encoding: \(pseudoEncoding.encodingType)"))
				}
			}
		}

		return .init(messageType: Self.messageType,
					 rectangles: rectangles)
	}
}
