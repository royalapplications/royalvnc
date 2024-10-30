// swiftlint:disable identifier_name

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@_implementationOnly import libtommath

final class BigNum {
	private let num: UnsafeMutablePointer<BIGNUM>
	private let backingDataPointer: UnsafeMutablePointer<UInt8>?
	
	init() {
		self.num = BN_new()
		self.backingDataPointer = nil
	}
	
	init?(data: Data) {
		let dataLength = data.count
		
		let backingDataPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dataLength)
		data.copyBytes(to: backingDataPtr, count: dataLength)
		
		guard let num = BN_bin2bn(backingDataPtr, .init(dataLength), nil) else {
			backingDataPtr.deallocate()
			
			return nil
		}
		
		self.num = num
		self.backingDataPointer = backingDataPtr
	}
	
	deinit {
		backingDataPointer?.deallocate()
		
		BN_free(num)
	}
}

extension BigNum {
	var isZero: Bool {
		let isItNum = BN_is_zero(num)
		let isIt = isItNum != 0
		
		return isIt
	}
	
	var bytesCount: Int32 {
		let count = BN_num_bytes(num)
		
		return count
	}
	
	var bitsCount: Int32 {
		let count = BN_num_bits(num)
		
		return count
	}
	
	func rand(range: BigNum) -> Bool {
		let successNum = BN_rand_range(num, range.num)
		let success = successNum != 0
		
		return success
	}
	
	static func modExp(y: BigNum,
					   g: BigNum,
					   x: BigNum,
					   p: BigNum) -> Bool {
		let successNum = BN_mod_exp(y.num,
									g.num,
									x.num,
									p.num)
		
		let success = successNum != 0
		
		return success
	}
	
	func bigEndianData() -> Data? {
		let expectedLength = bytesCount
		
		var data = Data(count: .init(expectedLength))
		
		let actualLength = data.withUnsafeMutableBytes { dataBufferPtr in
			guard let dataPtr = dataBufferPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
				return 0
			}
			
			let convertedLength = BN_bn2bin(num, dataPtr)
			
			return .init(convertedLength)
		}
		
		guard actualLength == expectedLength else {
			return nil
		}
		
		return data
	}
}

// swiftlint:enable identifier_name
