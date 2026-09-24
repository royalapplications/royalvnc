#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Capabilities appended to ServerInit when the Tight security type was
/// negotiated. Unknown capabilities are retained so callers can safely ignore
/// extensions they do not implement.
struct TightInteractionCapabilities: Equatable {
    struct Capability: Equatable {
        let code: UInt32
        let vendor: String
        let signature: String

        init(data: Data, offset: Int) throws {
            guard offset >= 0, data.count - offset >= 16 else { throw invalid() }
            code = data.withUnsafeBytes {
                UInt32(bigEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self))
            }
            guard let vendor = String(data: data[offset + 4..<offset + 8], encoding: .ascii),
                  let signature = String(data: data[offset + 8..<offset + 16], encoding: .ascii) else {
                throw invalid()
            }
            self.vendor = vendor
            self.signature = signature
        }
    }

    let serverMessages: [Capability]
    let clientMessages: [Capability]
    let encodings: [Capability]

    static let maximumCapabilitiesPerCategory = 256
    private static let capabilityBytes = 16

    static func decode(_ data: Data) throws -> Self {
        guard data.count >= 8 else { throw invalid() }
        let serverCount = Int(try readUInt16(data, offset: 0))
        let clientCount = Int(try readUInt16(data, offset: 2))
        let encodingCount = Int(try readUInt16(data, offset: 4))
        let padding = try readUInt16(data, offset: 6)
        guard padding == 0,
              serverCount <= maximumCapabilitiesPerCategory,
              clientCount <= maximumCapabilitiesPerCategory,
              encodingCount <= maximumCapabilitiesPerCategory else { throw invalid() }

        let totalCount = serverCount + clientCount + encodingCount
        guard totalCount <= (Int.max - 8) / capabilityBytes,
              data.count == 8 + totalCount * capabilityBytes else { throw invalid() }

        var offset = 8
        func readCapabilities(_ count: Int) throws -> [Capability] {
            var result: [Capability] = []
            result.reserveCapacity(count)
            for _ in 0..<count {
                result.append(try Capability(data: data, offset: offset))
                offset += capabilityBytes
            }
            return result
        }

        return try Self(serverMessages: readCapabilities(serverCount),
                        clientMessages: readCapabilities(clientCount),
                        encodings: readCapabilities(encodingCount))
    }

    static func receive(connection: NetworkConnectionReading) async throws -> Self {
        let header = try await connection.read(length: 8)
        guard header.count == 8 else { throw invalid() }
        let counts = (try readUInt16(header, offset: 0),
                      try readUInt16(header, offset: 2),
                      try readUInt16(header, offset: 4))
        guard Int(counts.0) <= maximumCapabilitiesPerCategory,
              Int(counts.1) <= maximumCapabilitiesPerCategory,
              Int(counts.2) <= maximumCapabilitiesPerCategory else { throw invalid() }
        let totalCount = Int(counts.0) + Int(counts.1) + Int(counts.2)
        let tail = try await connection.read(length: totalCount * capabilityBytes)
        guard tail.count == totalCount * capabilityBytes else { throw invalid() }
        var data = header
        data.append(tail)
        return try decode(data)
    }

    static func receiveCapabilities(connection: NetworkConnectionReading, count: UInt32) async throws -> [Capability] {
        guard count <= UInt32(maximumCapabilitiesPerCategory) else { throw invalid() }
        guard count > 0 else { return [] }
        let byteCount = Int(count) * capabilityBytes
        let data = try await connection.read(length: byteCount)
        guard data.count == byteCount else { throw invalid() }
        return try (0..<Int(count)).map { try Capability(data: data, offset: $0 * capabilityBytes) }
    }

    static func sendCode(_ code: UInt32, connection: NetworkConnectionWriting) async throws {
        var value = code.bigEndian
        let data = withUnsafeBytes(of: &value) { Data($0) }
        try await connection.write(data: data)
    }

    var supportsTightFileDownload: Bool {
        func contains(_ capabilities: [Capability], code: UInt32, signature: String) -> Bool {
            capabilities.contains { $0.code == code && $0.vendor == "TGHT" && $0.signature == signature }
        }
        return contains(serverMessages, code: 130, signature: "FTS_LSDT") &&
            contains(serverMessages, code: 131, signature: "FTS_DNDT") &&
            contains(clientMessages, code: 130, signature: "FTC_LSRQ") &&
            contains(clientMessages, code: 131, signature: "FTC_DNRQ")
    }

    var supportsTightFileUpload: Bool {
        func contains(_ capabilities: [Capability], code: UInt32, signature: String) -> Bool {
            capabilities.contains { $0.code == code && $0.vendor == "TGHT" && $0.signature == signature }
        }
        return contains(clientMessages, code: 132, signature: "FTC_UPRQ") &&
            contains(clientMessages, code: 133, signature: "FTC_UPDT")
    }

    var supportsTightFileTransfer: Bool {
        supportsTightFileDownload && supportsTightFileUpload
    }

    private init(serverMessages: [Capability], clientMessages: [Capability], encodings: [Capability]) {
        self.serverMessages = serverMessages
        self.clientMessages = clientMessages
        self.encodings = encodings
    }

    private static func readUInt16(_ data: Data, offset: Int) throws -> UInt16 {
        guard offset >= 0, data.count - offset >= 2 else { throw invalid() }
        return data.withUnsafeBytes {
            UInt16(bigEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt16.self))
        }
    }

    private static func invalid() -> VNCError { .protocol(.invalidData) }
}
