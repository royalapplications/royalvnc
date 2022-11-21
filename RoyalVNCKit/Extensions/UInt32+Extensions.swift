import Foundation

extension UInt32 {
	func uint8Value(bigEndian: Bool) -> [UInt8] {
		let value = bigEndian
			? self.bigEndian
			: self
		
		let uint8s: [UInt8] = withUnsafeBytes(of: value) {
			.init($0)
		}
		
		return uint8s
	}
}
