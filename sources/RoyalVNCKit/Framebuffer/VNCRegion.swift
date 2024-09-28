// swiftlint:disable identifier_name

import Foundation

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
	
	public init(cgRect: CGRect) {
		self.location = .init(cgPoint: cgRect.origin)
		self.size = .init(cgSize: cgRect.size)
	}
}

extension VNCRegion: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(location)
		hasher.combine(size)
	}
}

public extension VNCRegion {
	var cgRect: CGRect {
        .init(origin: location.cgPoint,
              size: size.cgSize)
	}
	
	static let zero: Self = .init(location: .zero,
								  size: .zero)
	
	func flipped(bounds: VNCRegion) -> Self {
		let selfCG = self.cgRect
		
		return .init(x: .init(selfCG.minX),
					 y: .init(bounds.cgRect.maxY - selfCG.maxY),
					 width: .init(selfCG.width),
					 height: .init(selfCG.height))
	}
	
	var x: UInt16 { location.x }
	var y: UInt16 { location.y }
	
	var width: UInt16 { size.width }
	var height: UInt16 { size.height }
}

public extension CGRect {
	var vncRegion: VNCRegion {
		.init(cgRect: self)
	}
}

extension VNCRegion: CustomStringConvertible {
	public var description: String {
		"\(location); \(size)"
	}
}

// swiftlint:enable identifier_name
