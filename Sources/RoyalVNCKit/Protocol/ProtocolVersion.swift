#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension VNCProtocol {
	struct ProtocolVersion {
		let data: Data
		let protocolVersion: String
		
		let majorVersion: UInt32
		let minorVersion: UInt32
		
		fileprivate init?(data: Data) {
			guard let protocolVersion = String(data: data, encoding: .utf8) else {
				return nil
			}
			
			let trimmedProtocolVersion = protocolVersion
				.trimmingCharacters(in: .newlines)
			
			guard let parsedProtocolVersion = Self.parseProtocolVersion(trimmedProtocolVersion) else {
				return nil
			}
			
			self.data = data
			self.protocolVersion = trimmedProtocolVersion
			
			let majorVersion = parsedProtocolVersion.0
			let minorVersion = parsedProtocolVersion.1
			
			self.majorVersion = majorVersion
			self.minorVersion = minorVersion
		}
		
		init(majorVersion: UInt32,
			 minorVersion: UInt32) {
			let protocolVersion = String(format: "RFB %03d.%03d", majorVersion, minorVersion)
			
			self.data = Self.dataWith(protocolVersion: protocolVersion)
			self.protocolVersion = protocolVersion
			
			self.majorVersion = majorVersion
			self.minorVersion = minorVersion
		}
	}
}

extension VNCProtocol.ProtocolVersion {
	static func dataWith(protocolVersion: String) -> Data {
		var fixedProtocolVersion = protocolVersion
		
		if !protocolVersion.hasSuffix("\n") {
			fixedProtocolVersion = "\(protocolVersion)\n"
		}
		
		let paddedProtocolVersion = fixedProtocolVersion.padding(toLength: 12,
																 withPad: "\0",
																 startingAt: protocolVersion.count)
		
		let data = paddedProtocolVersion.data(using: .utf8)!
		
		return data
	}
	
	static func receive(connection: NetworkConnectionReading) async throws -> Self {
		let data = try await connection.readBuffered(length: 12)
		
		guard let protocolVersion = Self(data: data) else {
			throw VNCError.protocol(.invalidData)
		}
		
		return protocolVersion
	}
	
	static func send(connection: NetworkConnectionWriting,
					 protocolVersion: Self) async throws {
		let data = protocolVersion.data
		
		try await connection.write(data: data)
	}
	
	var is3Point8OrHigher: Bool {
		let isIt = majorVersion >= 3 && minorVersion >= 8
		
		return isIt
	}
	
	var isAppleRemoteDesktop: Bool {
		let isIt = majorVersion == 3 && minorVersion == 889
		
		return isIt
	}
}

private extension VNCProtocol.ProtocolVersion {
	static func parseProtocolVersion(_ protocolVersion: String) -> (UInt32, UInt32)? {
		let trimmed = protocolVersion
			.trimmingCharacters(in: .newlines)
			.replacingOccurrences(of: "RFB ", with: "")
		
		let split = trimmed.split(separator: ".")
		
		guard split.count == 2 else {
			return nil
		}
		
		let majorStr = split[0]
		let minorStr = split[1]
		
		guard let majorVersion: UInt32 = .init(majorStr) else {
			return nil
		}
		
		guard let minorVersion: UInt32 = .init(minorStr) else {
			return nil
		}
		
		return (majorVersion, minorVersion)
	}
}
