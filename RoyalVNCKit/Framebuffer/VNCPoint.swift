// swiftlint:disable identifier_name

import Foundation

public struct VNCPoint: Equatable {
	public let x: UInt16
	public let y: UInt16
	
	public init(x: UInt16,
				y: UInt16) {
		self.x = x
		self.y = y
	}
	
	public init(cgPoint: CGPoint) {
		self.x = .init(cgPoint.x)
		self.y = .init(cgPoint.y)
	}
}

extension VNCPoint: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(x)
		hasher.combine(y)
	}
}

public extension VNCPoint {
	var cgPoint: CGPoint {
		return .init(x: CGFloat(x),
					 y: CGFloat(y))
	}
	
	static let zero: Self = .init(x: 0,
								  y: 0)
}

public extension CGPoint {
	var vncPoint: VNCPoint {
		return .init(cgPoint: self)
	}
}

extension VNCPoint: CustomStringConvertible {
	public var description: String {
		return "x: \(x), y: \(y)"
	}
}

// swiftlint:enable identifier_name
