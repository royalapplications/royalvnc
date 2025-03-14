#if canImport(CoreGraphics)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import CoreGraphics

public extension VNCRegion {
    init(cgRect: CGRect) {
        self.location = .init(cgPoint: cgRect.origin)
        self.size = .init(cgSize: cgRect.size)
    }
    
	var cgRect: CGRect {
        .init(origin: location.cgPoint,
              size: size.cgSize)
	}
	
	func flipped(bounds: VNCRegion) -> Self {
		let selfCG = self.cgRect
		
		return .init(x: .init(selfCG.minX),
					 y: .init(bounds.cgRect.maxY - selfCG.maxY),
					 width: .init(selfCG.width),
					 height: .init(selfCG.height))
	}
}

public extension CGRect {
	var vncRegion: VNCRegion {
		.init(cgRect: self)
	}
}
#endif
