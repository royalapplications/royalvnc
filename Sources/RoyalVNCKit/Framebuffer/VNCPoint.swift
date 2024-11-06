#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public struct VNCPoint: Equatable {
	public let x: UInt16
	public let y: UInt16
	
	public init(x: UInt16,
				y: UInt16) {
		self.x = x
		self.y = y
	}
}

extension VNCPoint: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(x)
		hasher.combine(y)
	}
}

public extension VNCPoint {
	static let zero: Self = .init(x: 0,
								  y: 0)
}

extension VNCPoint: CustomStringConvertible {
	public var description: String {
		"x: \(x), y: \(y)"
	}
}
