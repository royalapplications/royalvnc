#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

enum TightSecurity {
    enum Authentication: Equatable { case none, vnc }

    static func negotiate(connection: NetworkConnectionReading & NetworkConnectionWriting) async throws -> Authentication {
        let tunnelCount = try await connection.readUInt32()
        let tunnels = try await TightInteractionCapabilities.receiveCapabilities(connection: connection, count: tunnelCount)

        if tunnelCount > 0 {
            guard tunnels.contains(where: { $0.code == 0 && $0.vendor == "TGHT" && $0.signature == "NOTUNNEL" }) else {
                throw VNCError.protocol(.notImplemented(feature: "Tight security tunnel"))
            }
            try await TightInteractionCapabilities.sendCode(0, connection: connection)
        }

        let authenticationCount = try await connection.readUInt32()
        let authenticationTypes = try await TightInteractionCapabilities.receiveCapabilities(
            connection: connection, count: authenticationCount)

        guard authenticationCount > 0 else { return .none }

        if let vnc = authenticationTypes.first(where: {
            $0.code == 2 && $0.vendor == "STDV" && $0.signature == "VNCAUTH_"
        }) {
            try await TightInteractionCapabilities.sendCode(vnc.code, connection: connection)
            return .vnc
        }
        if let none = authenticationTypes.first(where: {
            $0.code == 1 && $0.vendor == "STDV" && $0.signature == "NOAUTH__"
        }) {
            try await TightInteractionCapabilities.sendCode(none.code, connection: connection)
            return .none
        }
        throw VNCError.protocol(.notImplemented(feature: "Tight security authentication"))
    }
}
