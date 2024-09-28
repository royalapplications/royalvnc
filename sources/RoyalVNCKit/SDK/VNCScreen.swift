import Foundation
import CoreGraphics

#if canImport(ObjectiveC)
@objc(VNCScreen)
#endif
public class VNCScreen: NSObject {
#if canImport(ObjectiveC)
    @objc
#endif
	public let id: UInt32
	
	public let frame: VNCRegion
	
	init(id: UInt32,
		 frame: VNCRegion) {
		self.id = id
		self.frame = frame
	}
}

public extension VNCScreen {
#if canImport(ObjectiveC)
    @objc
#endif
	var cgFrame: CGRect {
		frame.cgRect
	}
}

// MARK: - Equatable overrides for NSObject
extension VNCScreen {
	public override func isEqual(_ object: Any?) -> Bool {
		guard let otherScreen = object as? VNCScreen else {
			return false
		}
		
		let equal = self.id == otherScreen.id &&
				    self.frame == otherScreen.frame
		
		return equal
	}
	
	public override var hash: Int {
		var hasher = Hasher()
		hasher.combine(id)
		hasher.combine(frame)
		
		return hasher.finalize()
	}
}

extension VNCScreen {
	convenience init(screen: VNCProtocol.Screen) {
		let id = screen.id
		let frame = VNCRegion(x: screen.xPosition, y: screen.yPosition,
							  width: screen.width, height: screen.height)
		
		self.init(id: id, frame: frame)
	}
}
