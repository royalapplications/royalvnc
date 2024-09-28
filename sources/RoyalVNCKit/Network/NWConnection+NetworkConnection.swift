import Foundation
import Network

extension NWConnection: NetworkConnection { }

extension NWConnection: NetworkConnectionReading {
	func readPadding() async throws {
		try await readPadding(length: 1)
	}
	
	func readPadding(length: Int) async throws {
		_ = try await readBuffered(length: length)
	}
	
	func readUInt8() async throws -> UInt8 {
		let data = try await read(minimumLength: 1, maximumLength: 1)
		let value = data[0]
		
		return value
	}
	
	func readBool() async throws -> Bool {
		let uint8Value = try await readUInt8()
		let boolValue = uint8Value != 0
		
		return boolValue
	}
	
	func readUInt16() async throws -> UInt16 {
		let length = MemoryLayout<UInt16>.size
		let data = try await read(length: length)
		
		guard data.count == length else {
			throw VNCError.protocol(.invalidData)
		}
		
		let bigEndianValue = data.withUnsafeBytes {
			$0.load(as: UInt16.self)
		}
		
		let value = CFByteOrderGetCurrent() == .init(CFByteOrderLittleEndian.rawValue)
			? UInt16(bigEndian: bigEndianValue)
			: bigEndianValue
		
		return value
	}
	
	func readInt16() async throws -> Int16 {
		let length = MemoryLayout<Int16>.size
		let data = try await read(length: length)
		
		guard data.count == length else {
			throw VNCError.protocol(.invalidData)
		}
		
		let bigEndianValue = data.withUnsafeBytes {
			$0.load(as: Int16.self)
		}
		
		let value = CFByteOrderGetCurrent() == .init(CFByteOrderLittleEndian.rawValue)
			? Int16(bigEndian: bigEndianValue)
			: bigEndianValue
		
		return value
	}
	
	func readUInt32() async throws -> UInt32 {
		let length = MemoryLayout<UInt32>.size
		let data = try await read(length: length)
		
		guard data.count == length else {
			throw VNCError.protocol(.invalidData)
		}
		
		let bigEndianValue = data.withUnsafeBytes {
			$0.load(as: UInt32.self)
		}
		
		let value = CFByteOrderGetCurrent() == .init(CFByteOrderLittleEndian.rawValue)
			? UInt32(bigEndian: bigEndianValue)
			: bigEndianValue
		
		return value
	}
	
	func readInt32() async throws -> Int32 {
		let length = MemoryLayout<Int32>.size
		let data = try await read(length: length)
		
		guard data.count == length else {
			throw VNCError.protocol(.invalidData)
		}
		
		let bigEndianValue = data.withUnsafeBytes {
			$0.load(as: Int32.self)
		}
		
		let value = CFByteOrderGetCurrent() == .init(CFByteOrderLittleEndian.rawValue)
			? Int32(bigEndian: bigEndianValue)
			: bigEndianValue
		
		return value
	}
	
	func readString(encoding: String.Encoding) async throws -> String {
		let length = try await readUInt32()
		
		let stringValue = try await readString(encoding: encoding,
											   length: .init(length))
		
		return stringValue
	}
	
	func readString(encoding: String.Encoding,
					length: Int) async throws -> String {
		guard length > 0 else {
			return ""
		}
		
		let data = try await readBuffered(length: .init(length))
		
		guard let stringValue = String(data: data,
									   encoding: encoding) else {
			throw VNCError.protocol(.invalidData)
		}
		
		let trimmedStringValue: String
		
		if !stringValue.isEmpty,
		   let firstNullCharacterIndex = stringValue.firstIndex(of: "\0") {
			trimmedStringValue = String(stringValue[stringValue.startIndex..<firstNullCharacterIndex])
		} else {
			trimmedStringValue = stringValue
		}
		
		return trimmedStringValue
	}
	
	func readBuffered(length: Int) async throws -> Data {
		return try await readBuffered(length: length,
									  minimumChunkSize: 1,
									  maximumChunkSize: length)
	}
	
	func readBuffered(length: Int,
					  minimumChunkSize: Int,
					  maximumChunkSize: Int) async throws -> Data {
		var data = Data(capacity: length)
		
		var remainingBytesToRead = length
		
		while remainingBytesToRead > 0 {
			let bytesToRead = maximumChunkSize > remainingBytesToRead
				? remainingBytesToRead
				: maximumChunkSize
			
			let chunk = try await read(minimumLength: minimumChunkSize,
									   maximumLength: bytesToRead)
			
			let receivedBytes = chunk.count
			
			data.append(chunk)
			
			remainingBytesToRead -= receivedBytes
		}
		
		guard !data.isEmpty else {
			throw VNCError.protocol(.noData)
		}
		
		guard data.count == length else {
			throw VNCError.protocol(.invalidData)
		}
		
		return data
	}
	
	func read(length: Int) async throws -> Data {
		return try await read(minimumLength: length,
							  maximumLength: length)
	}
	
	func read(minimumLength: Int, maximumLength: Int) async throws -> Data {
		return try await withCheckedThrowingContinuation { continuation in
			receive(minimumIncompleteLength: minimumLength, maximumLength: maximumLength) { content, _, isComplete, error in
				guard !isComplete else {
					continuation.resume(throwing: VNCError.connection(.closed))
					
					return
				}
				
				guard error == nil else {
					continuation.resume(throwing: error!)
					
					return
				}
				
				guard let content else {
					continuation.resume(throwing: VNCError.protocol(.noData))
					
					return
				}
				
				let receivedLength = content.count
				
				guard receivedLength >= minimumLength,
					  receivedLength <= maximumLength else {
					continuation.resume(throwing: VNCError.protocol(.invalidData))
					
					return
				}
				
				continuation.resume(returning: content)
			}
		}
	}
}

extension NWConnection: NetworkConnectionWriting {
	func write(value: UInt8) async throws {
		let data = Data([ value ])
		
		return try await write(data: data)
	}
	
	func write(data: Data) async throws {
		return try await withCheckedThrowingContinuation { continuation in
			send(content: data, completion: .contentProcessed({ error in
				if let error = error {
					continuation.resume(throwing: error)
				} else {
					continuation.resume()
				}
			}))
		}
	}
}
