#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension VNCProtocol {
	struct MouseButton: OptionSet {
		init(rawValue: UInt8) {
			self.rawValue = rawValue
		}
		
		let rawValue: UInt8
		
		/// Left
		static let button1 = MouseButton(rawValue: 1 << 0)
		
		/// Middle
		static let button2 = MouseButton(rawValue: 1 << 1)
		
		/// Right
		static let button3 = MouseButton(rawValue: 1 << 2)
		
		/// Wheel Up
		static let button4 = MouseButton(rawValue: 1 << 3)
		
		/// Wheel Down
		static let button5 = MouseButton(rawValue: 1 << 4)
		
		/// Wheel Left
		static let button6 = MouseButton(rawValue: 1 << 5)
		
		/// Wheel Right
		static let button7 = MouseButton(rawValue: 1 << 6)
	}
}
