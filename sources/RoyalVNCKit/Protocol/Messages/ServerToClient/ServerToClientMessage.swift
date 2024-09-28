import Foundation

extension VNCProtocol {
	struct ServerToClientMessage: VNCMessage {
		let messageType: UInt8
	}
}

extension VNCProtocol.ServerToClientMessage {
	static func receive(connection: NetworkConnectionReading) async throws -> Self {
		let messageType = try await connection.readUInt8()
		
		return .init(messageType: messageType)
	}
}
