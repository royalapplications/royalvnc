import Foundation
import XCTest

@testable import RoyalVNCKit

final class ExtendedClipboardTests: XCTestCase {
	func testCapabilitiesMessageUsesNegativeLengthAndTextFormat() {
		let data = VNCProtocol.ClientCutText.Extended.capabilities.data

		XCTAssertEqual(data, Data([
			6, 0, 0, 0,
			0xff, 0xff, 0xff, 0xf8,
			0x01, 0x00, 0x00, 0x01,
			0x00, 0x00, 0x00, 0x00
		]))
	}

	func testCapabilitiesAreParsedAndValidateTheirDeclaredLength() async throws {
		let payload = Data([
			0x01, 0x00, 0x00, 0x01,
			0x00, 0x10, 0x00, 0x00
		])
		let connection = ReadingConnection(data: payload)
		let message = try await VNCProtocol.ServerCutText.ExtendedServerCutText.receive(
			connection: connection,
			logger: VNCPrintLogger(),
			length: 8
		)

		XCTAssertEqual(message.serverCapabilities?.format.rawValue, 1)
		XCTAssertEqual(message.serverCapabilities?.action.rawValue, 1 << 24)
	}

	func testByteReadsHandleSlicedData() async throws {
		let connection = ReadingConnection(data: Data([42]))
		let value = try await connection.readUInt8()

		XCTAssertEqual(value, 42)
	}
}

private final class ReadingConnection: NetworkConnectionReading {
	private var remaining: Data

	init(data: Data) {
		remaining = data
	}

	func read(minimumLength: Int, maximumLength: Int) async throws -> Data {
		guard remaining.count >= minimumLength else {
			throw VNCError.protocol(.invalidData)
		}

		let count = min(remaining.count, maximumLength)
		let result = remaining.prefix(count)
		remaining.removeFirst(count)

		return result
	}
}
