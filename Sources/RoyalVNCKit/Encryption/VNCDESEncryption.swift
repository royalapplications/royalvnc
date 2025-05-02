#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@_implementationOnly import d3des

struct VNCDESEncryption {
	static func encrypt(data: Data,
						key: String) -> Data? {
		var data = data
		var paddedKey = paddedKey(key)

		let success = encrypt(data: &data,
							  paddedKey: &paddedKey)

		guard success else {
			return nil
		}

		return data
	}
}

private extension VNCDESEncryption {
	static func encrypt(data: inout Data,
						paddedKey: inout Data) -> Bool {
		let success = data.withUnsafeMutableBytes { encryptedDataPtr in
			guard let encryptedDataBytes = encryptedDataPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
				return false
			}

			return paddedKey.withUnsafeMutableBytes { paddedKeyPtr in
				guard let paddedKeyBytes = paddedKeyPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
					return false
				}

				encrypt(dataBytes: encryptedDataBytes,
						paddedKeyBytes: paddedKeyBytes)

				return true
			}
		}

		return success
	}

	static func paddedKey(_ key: String) -> Data {
		let maxKeyLength = 8
		let actualKeyLength = key.count

		var paddedKey = Data(count: maxKeyLength)

		key.withCString { keyPtr in
			// key is simply password padded with nulls
			for idx in 0..<maxKeyLength {
				if idx < actualKeyLength {
					paddedKey[idx] = .init(keyPtr[idx])
				} else {
					paddedKey[idx] = 0
				}
			}
		}

		return paddedKey
	}

	static func encrypt(dataBytes: UnsafeMutablePointer<UInt8>,
						paddedKeyBytes: UnsafeMutablePointer<UInt8>) {
		let challengeSize = 16

		deskey(paddedKeyBytes, EN0)

		for challengeIdx in stride(from: 0, to: challengeSize, by: 8) {
			let bytesAtOffset = dataBytes.advanced(by: challengeIdx)

			des(bytesAtOffset, bytesAtOffset)
		}
	}
}
