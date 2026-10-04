import Foundation
import XCTest
@testable import RoyalVNCKit

final class ARDCredentialBoundsTests: XCTestCase {
    private func agreement() throws -> VNCProtocol.ARDAuthentication.DiffieHellmanKeyAgreement {
        // Tiny public DH parameters are a local buffer-boundary fixture only.
        try XCTUnwrap(.init(prime: Data([23]), generator: Data([5]), peerKey: Data([8]), keyLength: 1))
    }

    func testOversizedMultibyteFieldsAreRejectedWithoutCharacterIndexing() throws {
        let agreement = try agreement()
        for value in [String(repeating: "å", count: 32), String(repeating: "🙂", count: 16)] {
            XCTAssertNil(VNCProtocol.ARDAuthentication.Authentication(agreement: agreement, username: value, password: "fixture"))
            XCTAssertNil(VNCProtocol.ARDAuthentication.Authentication(agreement: agreement, username: "fixture", password: value))
        }
    }

    func testUtf8BoundaryIsAcceptedAndOneMoreByteIsRejected() throws {
        let agreement = try agreement()
        let boundary = String(repeating: "å", count: 31) + "a"
        let valid = try XCTUnwrap(VNCProtocol.ARDAuthentication.Authentication(agreement: agreement, username: boundary, password: boundary))
        XCTAssertEqual(valid.cipherText.count, 128)
        XCTAssertNil(VNCProtocol.ARDAuthentication.Authentication(agreement: agreement, username: boundary + "a", password: "fixture"))
        XCTAssertNil(VNCProtocol.ARDAuthentication.Authentication(agreement: agreement, username: "fixture", password: boundary + "a"))
    }

    func testEmbeddedNullIsRejectedInsteadOfChangingCredentialMeaning() throws {
        let agreement = try agreement()
        XCTAssertNil(VNCProtocol.ARDAuthentication.Authentication(agreement: agreement, username: "fi\0xture", password: "fixture"))
        XCTAssertNil(VNCProtocol.ARDAuthentication.Authentication(agreement: agreement, username: "fixture", password: "fi\0xture"))
    }
}
