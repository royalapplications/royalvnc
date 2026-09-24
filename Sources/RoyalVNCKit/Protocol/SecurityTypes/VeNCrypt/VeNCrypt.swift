#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Wire primitives for the VeNCrypt 0.2 security negotiation.
///
/// These deliberately stop before TLS is activated. A VeNCrypt subtype that
/// carries TLS must only be selected by a transport which can upgrade the
/// existing RFB stream without dropping or reordering bytes.
extension VNCProtocol {
	enum VeNCrypt {
		struct Version: Equatable, Sendable {
			let major: UInt8
			let minor: UInt8

			static let version0_2 = Self(major: 0, minor: 2)
		}

		struct Subtype: RawRepresentable, Equatable, Hashable, Sendable {
			let rawValue: UInt32

			init(rawValue: UInt32) {
				self.rawValue = rawValue
			}

			static let plain = Self(rawValue: 256)
			static let tlsNone = Self(rawValue: 257)
			static let tlsVNC = Self(rawValue: 258)
			static let tlsPlain = Self(rawValue: 259)
			static let x509None = Self(rawValue: 260)
			static let x509VNC = Self(rawValue: 261)
			static let x509Plain = Self(rawValue: 262)
			static let tlsSASL = Self(rawValue: 263)
			static let x509SASL = Self(rawValue: 264)
			static let ident = Self(rawValue: 265)
			static let tlsIdent = Self(rawValue: 266)
			static let x509Ident = Self(rawValue: 267)

			var requiresTLS: Bool {
				switch self {
					case .tlsNone, .tlsVNC, .tlsPlain, .x509None, .x509VNC,
						 .x509Plain, .tlsSASL, .x509SASL, .tlsIdent, .x509Ident:
						return true
					default:
						return false
				}
			}
		}
	}
}

extension VNCProtocol.VeNCrypt {
	/// Completes the plaintext VeNCrypt negotiation and upgrades the stream only
	/// after the server has accepted the selected subtype. The caller owns the
	/// upgrade operation because the underlying RFB connection must stay open.
	static func negotiate(
		connection: NetworkConnection,
		upgradeToTLS: (Subtype) async throws -> Void
	) async throws -> Subtype {
		let serverVersion = try await receiveVersion(connection: connection)
		guard serverVersion.major == 0, serverVersion.minor >= Version.version0_2.minor else {
			throw VNCError.protocol(.invalidData)
		}

		try await sendVersion(.version0_2, connection: connection)
		try await receiveVersionAcknowledgement(connection: connection)

		let offeredSubtypes = try await receiveSubtypes(connection: connection)
		guard let selectedSubtype = preferredAuthenticatedTLSSubtype(from: offeredSubtypes) else {
			throw VNCError.authentication(.clientCouldNotDecideOnSecurityType)
		}

		try await sendSubtype(selectedSubtype, connection: connection)
		try await receiveTLSSubtypeAcknowledgement(connection: connection)
		try await upgradeToTLS(selectedSubtype)

		return selectedSubtype
	}

	static func receiveVersion(connection: NetworkConnectionReading) async throws -> Version {
		Version(major: try await connection.readUInt8(),
				minor: try await connection.readUInt8())
	}

	static func sendVersion(_ version: Version,
						connection: NetworkConnectionWriting) async throws {
		try await connection.write(data: Data([version.major, version.minor]))
	}

	/// VeNCrypt's version acknowledgement is zero on success.
	static func receiveVersionAcknowledgement(connection: NetworkConnectionReading) async throws {
		guard try await connection.readUInt8() == 0 else {
			throw VNCError.protocol(.invalidData)
		}
	}

	static func receiveSubtypes(connection: NetworkConnectionReading) async throws -> [Subtype] {
		let count = Int(try await connection.readUInt8())
		var subtypes: [Subtype] = []
		subtypes.reserveCapacity(count)

		for _ in 0..<count {
			subtypes.append(Subtype(rawValue: try await connection.readUInt32()))
		}

		return subtypes
	}

	/// Returns the only VeNCrypt subtype that can be selected automatically
	/// once a certificate-validating TLS transport exists. Anonymous TLS and
	/// plaintext credentials require an explicit opt-in policy and are never
	/// silently selected.
	static func preferredAuthenticatedTLSSubtype(from offeredSubtypes: [Subtype]) -> Subtype? {
		offeredSubtypes.contains(.x509VNC) ? .x509VNC : nil
	}

	static func sendSubtype(_ subtype: Subtype,
						connection: NetworkConnectionWriting) async throws {
		var data = Data(capacity: MemoryLayout<UInt32>.size)
		data.append(subtype.rawValue, bigEndian: true)
		try await connection.write(data: data)
	}

	/// TLS and X509 subtype acknowledgement is one on success.
	static func receiveTLSSubtypeAcknowledgement(connection: NetworkConnectionReading) async throws {
		guard try await connection.readUInt8() == 1 else {
			throw VNCError.protocol(.invalidData)
		}
	}
}
