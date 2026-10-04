#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// MARK: - CryptoSwift Implementation
@_implementationOnly import CryptoSwift

final class BigNum {
    private var bigInt: BigUInteger

    init() {
        self.bigInt = .init()
    }

    init?(data: Data) {
        self.bigInt = .init(data)
    }
    
    private init(_ bigInt: BigUInteger) {
        self.bigInt = bigInt
    }
}

extension BigNum {
    static func randomNumber(lessThan limit: BigNum) -> BigNum {
        .init(BigUInteger.randomInteger(lessThan: limit.bigInt))
    }
    
    static func randomNumber(lessThan limit: UInt64) -> BigNum {
        .init(BigUInteger.randomInteger(lessThan: .init(limit)))
    }
}

extension BigNum {
    var isZero: Bool {
        let isIt = self.bigInt == 0
        
        return isIt
    }

    var bytesCount: Int32 {
        let count = self.bigInt.serialize().count
        
        return .init(count)
    }

    var bitsCount: Int32 {
        let count = self.bigInt.bitWidth

        return .init(count)
    }

    func rand(range: BigNum) -> Bool {
        self.bigInt = CS.BigUInt.randomInteger(lessThan: range.bigInt)
        
        return true
    }

    static func modExp(y: BigNum,
                       g: BigNum,
                       x: BigNum,
                       p: BigNum) -> Bool {
        y.bigInt = g.bigInt.power(x.bigInt, modulus: p.bigInt)
        
        return true
    }
    
    func power(exponent: BigNum, modulus: BigNum) -> BigNum {
        let result = bigInt.power(exponent.bigInt,
                                  modulus: modulus.bigInt)
        
        return .init(result)
    }

    func bigEndianData() -> Data? {
        let data = self.bigInt.serialize()
        
        return data
    }
    
    func fixedWidthBigEndianData(length: Int) -> Data? {
        guard length > 0,
              let minimalData = bigEndianData(),
              minimalData.count <= length else {
            return nil
        }

        guard minimalData.count < length else {
            return minimalData
        }

        var paddedData = Data(repeating: 0,
                              count: length - minimalData.count)
        
        paddedData.append(minimalData)

        return paddedData
    }
    
    func isLessThan(_ value: UInt64) -> Bool {
        bigInt < value
    }

    var isOdd: Bool { bigInt & 1 == 1 }

    func isValidDiffieHellmanPublicValue(modulus: BigNum) -> Bool {
        guard modulus.bigInt >= 5 else { return false }
        return bigInt > 1 && bigInt < modulus.bigInt - 1
    }
}


// MARK: - libtommath Implementation
//@_implementationOnly import libtommath
//
//final class BigNum {
//	private let num: UnsafeMutablePointer<BIGNUM>
//	private let backingDataPointer: UnsafeMutablePointer<UInt8>?
//
//	init() {
//		self.num = BN_new()
//		self.backingDataPointer = nil
//	}
//
//	init?(data: Data) {
//		let dataLength = data.count
//
//		let backingDataPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dataLength)
//		data.copyBytes(to: backingDataPtr, count: dataLength)
//
//		guard let num = BN_bin2bn(backingDataPtr, .init(dataLength), nil) else {
//			backingDataPtr.deallocate()
//
//			return nil
//		}
//
//		self.num = num
//		self.backingDataPointer = backingDataPtr
//	}
//
//	deinit {
//		backingDataPointer?.deallocate()
//
//		BN_free(num)
//	}
//}
//
//extension BigNum {
//	var isZero: Bool {
//		let isItNum = BN_is_zero(num)
//		let isIt = isItNum != 0
//
//		return isIt
//	}
//
//	var bytesCount: Int32 {
//		let count = BN_num_bytes(num)
//
//		return count
//	}
//
//	var bitsCount: Int32 {
//		let count = BN_num_bits(num)
//
//		return count
//	}
//
//	func rand(range: BigNum) -> Bool {
//		let successNum = BN_rand_range(num, range.num)
//		let success = successNum != 0
//
//		return success
//	}
//
//	static func modExp(y: BigNum,
//					   g: BigNum,
//					   x: BigNum,
//					   p: BigNum) -> Bool {
//		let successNum = BN_mod_exp(y.num,
//									g.num,
//									x.num,
//									p.num)
//
//		let success = successNum != 0
//
//		return success
//	}
//
//	func bigEndianData() -> Data? {
//		let expectedLength = bytesCount
//
//		var data = Data(count: .init(expectedLength))
//
//		let actualLength = data.withUnsafeMutableBytes { dataBufferPtr in
//			guard let dataPtr = dataBufferPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
//				return 0
//			}
//
//			let convertedLength = BN_bn2bin(num, dataPtr)
//
//			return .init(convertedLength)
//		}
//
//		guard actualLength == expectedLength else {
//			return nil
//		}
//
//		return data
//	}
//}
