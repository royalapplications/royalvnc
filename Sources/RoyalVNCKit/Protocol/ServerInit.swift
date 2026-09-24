#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension VNCProtocol {
	struct ServerInit {
		let framebufferWidth: UInt16
		let framebufferHeight: UInt16

		let pixelFormat: PixelFormat

		let name: String
		let tightCapabilities: TightInteractionCapabilities?
	}
}

extension VNCProtocol.ServerInit {
	static func receive(connection: NetworkConnectionReading,
						isTightSecurityEnabled: Bool) async throws -> Self {
		let frameBufferWidth = try await connection.readUInt16()
		let frameBufferHeight = try await connection.readUInt16()

		let pixelFormat = try await VNCProtocol.PixelFormat.receive(connection: connection)

		let name = try await connection.readString(encoding: .utf8)
		let tightCapabilities = isTightSecurityEnabled
			? try await TightInteractionCapabilities.receive(connection: connection)
			: nil

		return .init(framebufferWidth: frameBufferWidth,
					 framebufferHeight: frameBufferHeight,
					 pixelFormat: pixelFormat,
					 name: name,
					 tightCapabilities: tightCapabilities)
	}
}
