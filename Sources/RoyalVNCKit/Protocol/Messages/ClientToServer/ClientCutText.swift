#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension VNCProtocol {
	struct ClientCutText: VNCSendableMessage {
		let messageType: UInt8 = 6

		static let stringEncoding: String.Encoding = .isoLatin1

		let text: String
	}
}

extension VNCProtocol.ClientCutText {
	/// An Extended Clipboard message. Its negative length distinguishes it from
	/// the legacy Latin-1 ClientCutText payload.
	struct Extended: VNCSendableMessage {
		let messageType: UInt8 = 6
		let payload: Data

		/// The only capability announced until the corresponding request,
		/// notification and provide flows are implemented. Advertising fewer
		/// capabilities makes peers retain their legacy clipboard behaviour.
		static let capabilities = Self(payload: Self.capabilitiesPayload)

		private static let capabilitiesPayload: Data = {
			var payload = Data(capacity: 8)
			let flags: UInt32 = (1 << 24) | 1 // CAPS + UTF-8 text

			payload.append(flags, bigEndian: true)
			payload.append(UInt32(0), bigEndian: true)

			return payload
		}()

		var data: Data {
			precondition(payload.count <= Int32.max,
						 "An Extended Clipboard payload must fit in a signed 32-bit length")

			let length = Int32(-payload.count)
			var data = Data(capacity: 8 + payload.count)

			data.append(messageType)
			data.appendPadding(length: 3)
			data.append(length, bigEndian: true)
			data.append(payload)

			return data
		}

		func send(connection: NetworkConnectionWriting) async throws {
			try await connection.write(data: data)
		}
	}

	var data: Data {
		var latin1TextData = text.data(using: Self.stringEncoding) ?? .init()
		var textLength = latin1TextData.count

		if textLength > UInt32.max {
			textLength = .init(UInt32.max)
			latin1TextData = .init(latin1TextData.subdata(in: 0..<textLength))
		}

		let length = 8 + textLength

		var data = Data(capacity: length)

		data.append(messageType)
		data.appendPadding(length: 3)

		data.append(UInt32(textLength), bigEndian: true)
		data.append(contentsOf: latin1TextData)

		guard data.count == length else {
			fatalError("VNCProtocol.ClientCutText data.count (\(data.count)) != \(length)")
		}

		return data
	}

	func send(connection: NetworkConnectionWriting) async throws {
		try await connection.write(data: data)
	}
}
