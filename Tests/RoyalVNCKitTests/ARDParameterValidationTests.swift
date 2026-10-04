import Foundation
import XCTest
@testable import RoyalVNCKit

final class ARDParameterValidationTests: XCTestCase {
    func testInvalidNumericParametersAreRejectedWhileReceivingChallenge() async throws {
        // Receiving these frames must fail before any credential request or DH
        // computation. In particular, p=0 traps in BigUInt and p=1 can loop.
        let invalid: [(UInt16, UInt8, UInt8)] = [
            (5, 0, 8), (5, 1, 8), (2, 2, 2), (5, 24, 8),
            (0, 23, 8), (1, 23, 8), (22, 23, 8), (23, 23, 8),
            (5, 23, 0), (5, 23, 1), (5, 23, 22), (5, 23, 23)
        ]
        for (generator, prime, peer) in invalid {
            let reader = ARDParameterReader(data: frame(generator: generator, prime: [0, prime], peer: [0, peer]))
            do {
                _ = try await VNCProtocol.ARDAuthentication.receive(connection: reader)
                XCTFail("Accepted invalid public DH parameters: g=\(generator), p=\(prime), peer=\(peer)")
            } catch {
                XCTAssertEqual(reader.bytesRead, 8)
            }
        }
    }

    func testInvalidWidthsAreRejectedBeforeReadingPublicValues() async throws {
        for width: UInt16 in [0, 513, UInt16.max] {
            let reader = ARDParameterReader(data: Data([0, 5, UInt8(width >> 8), UInt8(width & 255)]))
            do {
                _ = try await VNCProtocol.ARDAuthentication.receive(connection: reader)
                XCTFail("Accepted unsupported DH width")
            } catch {
                XCTAssertEqual(reader.bytesRead, 4)
                XCTAssertEqual(reader.readRequests, 2, "Reject the width without requesting a parameter body")
            }
        }
    }

    func testLeadingZeroParametersAnd4096BitWidthArePreserved() async throws {
        for width in [2, 64, 128, 256, 512] {
            // Padding tests representation, not the strength of these tiny values.
            let prime = Array(repeating: UInt8(0), count: width - 1) + [23]
            let peer = Array(repeating: UInt8(0), count: width - 1) + [8]
            let reader = ARDParameterReader(data: frame(generator: 5, prime: prime, peer: peer))
            let challenge = try await VNCProtocol.ARDAuthentication.receive(connection: reader)
            XCTAssertEqual(challenge.keySize, UInt16(width))
            XCTAssertEqual(challenge.prime, Data(prime))
            XCTAssertEqual(challenge.peerKey, Data(peer))
            XCTAssertEqual(reader.bytesRead, 4 + 2 * width)
        }
    }

    func testTruncatedChallengeFailsWithoutComputation() async throws {
        var data = frame(generator: 5, prime: [0, 23], peer: [0, 8])
        data.removeLast()
        let reader = ARDParameterReader(data: data)
        do {
            _ = try await VNCProtocol.ARDAuthentication.receive(connection: reader)
            XCTFail("Accepted truncated public value")
        } catch {
            XCTAssertEqual(reader.bytesRead, data.count, "The buffered reader consumes the partial value before detecting EOF")
        }
    }

    func testDirectAgreementRejectsInvalidParametersWithoutEnteringMath() {
        for prime: UInt8 in [0, 1, 2, 24] {
            XCTAssertNil(VNCProtocol.ARDAuthentication.DiffieHellmanKeyAgreement(
                prime: Data([prime]), generator: Data([5]), peerKey: Data([8]), keyLength: 1))
        }
        for width in [-1, 0, 513, Int.max] {
            XCTAssertNil(VNCProtocol.ARDAuthentication.DiffieHellmanKeyAgreement(
                prime: Data([23]), generator: Data([5]), peerKey: Data([8]), keyLength: width))
        }
        XCTAssertNil(VNCProtocol.ARDAuthentication.DiffieHellmanKeyAgreement(
            prime: Data([23]), generator: Data([5]), peerKey: Data([0, 8]), keyLength: 1))
    }

    private func frame(generator: UInt16, prime: [UInt8], peer: [UInt8]) -> Data {
        let width = UInt16(prime.count)
        return Data([UInt8(generator >> 8), UInt8(generator & 255), UInt8(width >> 8), UInt8(width & 255)] + prime + peer)
    }
}

private final class ARDParameterReader: NetworkConnectionReading {
    private var remaining: Data
    private(set) var bytesRead = 0
    private(set) var readRequests = 0

    init(data: Data) { remaining = data }

    func read(minimumLength: Int, maximumLength: Int) async throws -> Data {
        readRequests += 1
        guard remaining.count >= minimumLength else { throw VNCError.protocol(.invalidData) }
        let count = min(remaining.count, maximumLength)
        let result = Data(remaining.prefix(count))
        remaining.removeFirst(count)
        bytesRead += count
        return result
    }
}
