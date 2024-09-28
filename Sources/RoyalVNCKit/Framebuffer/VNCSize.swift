import Foundation

public struct VNCSize: Equatable {
	public let width: UInt16
	public let height: UInt16
	
	public init(width: UInt16,
				height: UInt16) {
		self.width = width
		self.height = height
	}
	
	public init(cgSize: CGSize) {
		self.width = .init(cgSize.width)
		self.height = .init(cgSize.height)
	}
}

extension VNCSize: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(width)
		hasher.combine(height)
	}
}

public extension VNCSize {
	var cgSize: CGSize {
        .init(width: CGFloat(width),
              height: CGFloat(height))
	}
	
	static let zero: Self = .init(width: 0,
								  height: 0)
}

public extension CGSize {
	var vncSize: VNCSize {
		.init(cgSize: self)
	}
}

extension VNCSize: CustomStringConvertible {
	public var description: String {
		"width: \(width), height: \(height)"
	}
}
