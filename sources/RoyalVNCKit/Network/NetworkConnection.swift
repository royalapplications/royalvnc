import Foundation

protocol NetworkConnection: NetworkConnectionReading, NetworkConnectionWriting { }

protocol NetworkConnectionReading {
	func readPadding() async throws
	func readPadding(length: Int) async throws
	
	func read(length: Int) async throws -> Data
	
	func readUInt8() async throws -> UInt8
	func readBool() async throws -> Bool
	
	func readUInt16() async throws -> UInt16
	func readInt16() async throws -> Int16
	
	func readUInt32() async throws -> UInt32
	func readInt32() async throws -> Int32
	
	func readString(encoding: String.Encoding) async throws -> String
	
	func readString(encoding: String.Encoding,
					length: Int) async throws -> String
	
	func readBuffered(length: Int) async throws -> Data
	
	func readBuffered(length: Int,
					  minimumChunkSize: Int,
					  maximumChunkSize: Int) async throws -> Data
	
	func read(minimumLength: Int,
			  maximumLength: Int) async throws -> Data
}

protocol NetworkConnectionWriting {
	func write(value: UInt8) async throws
	
	func write(data: Data) async throws
}
