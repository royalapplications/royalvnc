import Foundation
import XCTest
@testable import RoyalVNCKit

final class SocketNetworkConnectionTests: XCTestCase {
    func testPartialWritesPreserveCompleteRFBKeyMessage() throws {
        let packet: [UInt8] = [4, 1, 0, 0, 0, 0, 0, 64]
        var delivered: [UInt8] = []
        var calls = 0
        try SocketNetworkConnection.writeAll(data: Data(packet)) { remaining in
            calls += 1
            let count = min(3, remaining.count)
            delivered.append(contentsOf: remaining.prefix(count))
            return count
        }
        XCTAssertEqual(delivered, packet)
        XCTAssertEqual(calls, 3)
    }

    func testZeroOrFailedWriteAfterPrefixDoesNotReportSuccessOrSpin() {
        for failure in [0, -1] {
            var calls = 0
            XCTAssertThrowsError(try SocketNetworkConnection.writeAll(data: Data([4, 1, 0, 0])) { _ in
                calls += 1
                return calls == 1 ? 2 : failure
            })
            XCTAssertEqual(calls, 2)
        }
    }

    func testEmptyWriteDoesNotCallSocket() throws {
        try SocketNetworkConnection.writeAll(data: Data()) { _ in
            XCTFail("Empty payload must not invoke send")
            return -1
        }
    }
}
