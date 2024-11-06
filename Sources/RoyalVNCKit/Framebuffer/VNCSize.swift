#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public struct VNCSize: Equatable {
	public let width: UInt16
	public let height: UInt16
	
	public init(width: UInt16,
				height: UInt16) {
		self.width = width
		self.height = height
	}
}

extension VNCSize: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(width)
		hasher.combine(height)
	}
}

public extension VNCSize {
	static let zero: Self = .init(width: 0,
								  height: 0)
}

extension VNCSize: CustomStringConvertible {
	public var description: String {
		"width: \(width), height: \(height)"
	}
}
