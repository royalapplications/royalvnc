import Foundation
import XCTest
@testable import RoyalVNCKit

final class ARDDiffieHellmanEncodingTests: XCTestCase {
    func testLeadingZeroAgreementUsesAdvertisedWidthForAllDHValues() throws {
        // Tiny parameters exercise encoding only; they are not network security settings.
        let agreement = try XCTUnwrap(VNCProtocol.ARDAuthentication.DiffieHellmanKeyAgreement(
            prime: Data([0, 23]), generator: Data([5]), peerKey: Data([0, 8]), keyLength: 2))
        for value in [agreement.privateKey, agreement.publicKey, agreement.secretKey] {
            XCTAssertEqual(value.count, 2)
            XCTAssertEqual(value.first, 0)
        }
        let privateValue = UInt64(try XCTUnwrap(agreement.privateKey.last))
        XCTAssertTrue((1..<23).contains(privateValue))
        // Calculate independently of BigNum to verify that padding preserves the value.
        XCTAssertEqual(agreement.publicKey, Data([0, UInt8(integerPower(5, privateValue, modulus: 23))]))
        XCTAssertEqual(agreement.secretKey, Data([0, UInt8(integerPower(8, privateValue, modulus: 23))]))
    }

    func testKnownDHVectorSerializesPublicAndSharedValuesAtFixedWidth() throws {
        // g=5, p=23; Alice x=6/public=8, Bob x=15/public=19, shared=2.
        let prime = try XCTUnwrap(BigNum(data: Data([0, 23])))
        let generator = try XCTUnwrap(BigNum(data: Data([5])))
        let alicePrivate = try XCTUnwrap(BigNum(data: Data([0, 6])))
        let bobPrivate = try XCTUnwrap(BigNum(data: Data([0, 15])))
        let alicePublic = BigNum()
        let bobPublic = BigNum()
        XCTAssertTrue(BigNum.modExp(y: alicePublic, g: generator, x: alicePrivate, p: prime))
        XCTAssertTrue(BigNum.modExp(y: bobPublic, g: generator, x: bobPrivate, p: prime))
        XCTAssertEqual(alicePublic.fixedWidthBigEndianData(length: 2), Data([0, 8]))
        XCTAssertEqual(bobPublic.fixedWidthBigEndianData(length: 2), Data([0, 19]))
        let aliceSecret = BigNum()
        let bobSecret = BigNum()
        XCTAssertTrue(BigNum.modExp(y: aliceSecret, g: bobPublic, x: alicePrivate, p: prime))
        XCTAssertTrue(BigNum.modExp(y: bobSecret, g: alicePublic, x: bobPrivate, p: prime))
        XCTAssertEqual(aliceSecret.fixedWidthBigEndianData(length: 2), Data([0, 2]))
        XCTAssertEqual(bobSecret.fixedWidthBigEndianData(length: 2), Data([0, 2]))
    }

    func testFixedWidthRejectsOverflowAndInvalidWidths() throws {
        let value = try XCTUnwrap(BigNum(data: Data([1, 0])))
        XCTAssertNil(value.fixedWidthBigEndianData(length: 1))
        XCTAssertNil(value.fixedWidthBigEndianData(length: 0))
        XCTAssertNil(value.fixedWidthBigEndianData(length: -1))
        XCTAssertEqual(value.fixedWidthBigEndianData(length: 2), Data([1, 0]))
        for width in [0, -1] {
            XCTAssertNil(VNCProtocol.ARDAuthentication.DiffieHellmanKeyAgreement(
                prime: Data([0, 23]), generator: Data([5]), peerKey: Data([0, 8]), keyLength: width))
        }
    }

    private func integerPower(_ base: UInt64, _ exponent: UInt64, modulus: UInt64) -> UInt64 {
        var result: UInt64 = 1
        for _ in 0..<exponent { result = result * base % modulus }
        return result
    }
}
