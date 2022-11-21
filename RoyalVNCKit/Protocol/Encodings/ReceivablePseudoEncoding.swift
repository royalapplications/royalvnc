import Foundation

protocol VNCReceivablePseudoEncoding: VNCPseudoEncoding {
	func receive(_ rectangle: VNCProtocol.Rectangle,
				 framebuffer: VNCFramebuffer,
				 connection: NetworkConnectionReading,
				 logger: VNCLogger) async throws
}
