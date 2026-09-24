#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension VNCProtocol {
    struct TightFileTransferMessage: VNCSendableMessage {
        let data: Data
        var messageType: UInt8 { data.first ?? 0 }

        func send(connection: NetworkConnectionWriting) async throws {
            try await connection.write(data: data)
        }
    }
}
