import Foundation

extension VNCProtocol {
	struct EndOfContinuousUpdates: VNCMessage {
		static let messageType: UInt8 = 150
		
		let messageType: UInt8
	}
}
