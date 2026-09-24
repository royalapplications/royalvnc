#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension VNCProtocol {
    struct ServerCutText: VNCReceivableMessage {
        static let messageType: UInt8 = 3
        static let stringEncoding: String.Encoding = .isoLatin1
        let messageType: UInt8
        let text: String?
        let extended: ExtendedClipboard?

        static func receive(connection: NetworkConnectionReading, logger: VNCLogger) async throws -> Self {
            try await connection.readPadding(length: 3)
            let length = try await connection.readInt32()
            // Widen before negation, including on platforms with 32-bit Int.
            let magnitude = Int64(length).magnitude
            guard magnitude <= ExtendedClipboard.maximumPacketBytes else { throw VNCError.protocol(.invalidData) }
            let count = Int(magnitude)
            let data = count == 0 ? Data() : try await connection.readBuffered(length: count)
            guard data.count == count else { throw VNCError.protocol(.invalidData) }
            if length < 0 {
                let message = try ExtendedClipboard.decode(data)
                return .init(messageType: messageType, text: message.textValue, extended: message)
            }
            guard let text = String(data: data, encoding: stringEncoding) else { throw VNCError.protocol(.invalidData) }
            return .init(messageType: messageType, text: text, extended: nil)
        }
    }
}
