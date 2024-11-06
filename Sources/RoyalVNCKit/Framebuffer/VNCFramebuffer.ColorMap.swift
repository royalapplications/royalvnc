#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension VNCFramebuffer {
	struct ColorMap {
		let colors: [LocalPixel]
        let colorsCount: Int
		
		init(entries: VNCProtocol.SetColourMapEntries) {
			var colors = [LocalPixel]()
			
			for idx in Int(entries.firstColour)..<entries.colors.count {
				let entry = entries.colors[idx]
				let localPixel = LocalPixel(red: entry.redUInt8,
											green: entry.greenUInt8,
											blue: entry.blueUInt8)
				
				colors.append(localPixel)
			}
			
			self.colors = colors
            self.colorsCount = colors.count
		}
	}
}

extension VNCFramebuffer.ColorMap {
	func colorAt(_ index: Int) -> VNCFramebuffer.LocalPixel? {
		guard index >= 0,
			  index < colorsCount else {
			return nil
		}
		
		let color = colors[index]
		
		return color
	}
}
