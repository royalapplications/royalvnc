import Foundation

#if os(iOS)
import AVFoundation
#elseif os(macOS)
import AppKit
#endif

struct VNCSystemSound { }

extension VNCSystemSound {
	func play() {
#if os(macOS)
        NSSound.beep()
#elseif os(iOS)
        // With vibration
        let systemSoundID: SystemSoundID = 1013
        
        AudioServicesPlaySystemSound(systemSoundID)
#else
        // TODO: Implement beep on Linux/Windows/etc.
#endif
	}
}
