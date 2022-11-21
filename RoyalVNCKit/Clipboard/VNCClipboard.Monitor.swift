import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

class VNCClipboardMonitor {
	let clipboard: VNCClipboard
	let monitoringInterval: TimeInterval
	let tolerance: TimeInterval
	
	weak var delegate: VNCClipboardMonitorDelegate?
	
	private(set) var isMonitoring = false
	
	private var timer: Timer?
	private var lastChangeCount = 0
	
	init(clipboard: VNCClipboard,
		 monitoringInterval: TimeInterval,
		 tolerance: TimeInterval) {
		self.clipboard = clipboard
		self.monitoringInterval = monitoringInterval
		self.tolerance = tolerance
	}
	
	deinit {
		delegate = nil
		
		stopMonitoring()
	}
}

extension VNCClipboardMonitor {
	func startMonitoring() {
		stopMonitoring()
		
		// -1 to send clipboard to trigger notification immediately if something's on the pasteboard
		lastChangeCount = clipboard.changeCount - 1
		
		guard timer == nil else { // Already have a timer
			return
		}
		
		DispatchQueue.main.async { [weak self] in
			guard let strongSelf = self else { return }
			
			let timer = Timer.scheduledTimer(timeInterval: strongSelf.monitoringInterval,
											 target: strongSelf,
											 selector: #selector(strongSelf.timerDidFire(_:)),
											 userInfo: nil,
											 repeats: true)
			
			timer.tolerance = strongSelf.tolerance
			
			strongSelf.timer = timer
			strongSelf.isMonitoring = true
		}
	}
	
	func stopMonitoring() {
		timer?.invalidate()
		timer = nil
		
		lastChangeCount = 0
		isMonitoring = false
	}
}

private extension VNCClipboardMonitor {
	@objc
	func timerDidFire(_ timer: Timer) {
		guard let delegate = self.delegate,
			  timer == self.timer else {
			return
		}
		
		guard delegate.clipboardMonitorShouldMonitor(self) else { // Should not monitor
			return
		}
		
		let currentChangeCount = clipboard.changeCount
		
		guard currentChangeCount != lastChangeCount else { // No changes
			return
		}
		
		lastChangeCount = currentChangeCount
		
		guard let text = clipboard.text else { // No text
			return
		}
		
		delegate.clipboardMonitor(self,
								  didChangeText: text)
	}
}
