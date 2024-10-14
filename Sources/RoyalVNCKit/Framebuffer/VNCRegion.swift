// swiftlint:disable identifier_name

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public struct VNCRegion: Equatable {
	public let location: VNCPoint
	public let size: VNCSize
	
	public init(location: VNCPoint,
				size: VNCSize) {
		self.location = location
		self.size = size
	}
	
	public init(x: UInt16, y: UInt16,
				width: UInt16, height: UInt16) {
		self.location = .init(x: x, y: y)
		self.size = .init(width: width, height: height)
	}
}

extension VNCRegion: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(location)
		hasher.combine(size)
	}
}

public extension VNCRegion {
	static let zero: Self = .init(location: .zero,
								  size: .zero)
	
	var x: UInt16 { location.x }
	var y: UInt16 { location.y }
	
	var width: UInt16 { size.width }
	var height: UInt16 { size.height }
}

extension VNCRegion: CustomStringConvertible {
	public var description: String {
		"\(location); \(size)"
	}
}

// swiftlint:enable identifier_name
