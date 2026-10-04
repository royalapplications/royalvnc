import Foundation

import Dispatch

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

final class VNCClipboardMonitor {
	let clipboard: VNCClipboard
	let monitoringInterval: TimeInterval
	let tolerance: TimeInterval

	weak var delegate: VNCClipboardMonitorDelegate?

    private let lifecycleLock = NSLock()
    private var monitoring = false
    var isMonitoring: Bool {
        lifecycleLock.lock(); defer { lifecycleLock.unlock() }
        return monitoring
    }

#if !canImport(FoundationEssentials)
	private var timer: Timer?
#endif

	private var lastChangeCount = 0
    private var monitoringGeneration = UUID()

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
        // Publish cancellation and the new generation atomically. Callers may
        // arrive from a transport task while the main queue installs a timer.
        lifecycleLock.lock()
        let generation = UUID()
        monitoringGeneration = generation
        monitoring = false
#if !canImport(FoundationEssentials)
        let previousTimer = timer
        timer = nil
#endif
        lifecycleLock.unlock()

#if !canImport(FoundationEssentials)
        Self.invalidateOnMain(previousTimer)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.lifecycleLock.lock()
            defer { self.lifecycleLock.unlock() }
            guard self.monitoringGeneration == generation else { return }
            self.lastChangeCount = self.clipboard.changeCount - 1
            let timer = Timer.scheduledTimer(withTimeInterval: self.monitoringInterval,
                                             repeats: true) { [weak self] timer in
                self?.timerDidFire(timer)
            }
            timer.tolerance = self.tolerance
            self.timer = timer
            self.monitoring = true
        }
#endif
    }

    func stopMonitoring() {
        lifecycleLock.lock()
        monitoringGeneration = UUID()
        monitoring = false
#if !canImport(FoundationEssentials)
        let previousTimer = timer
        timer = nil
#endif
        lifecycleLock.unlock()
#if !canImport(FoundationEssentials)
        Self.invalidateOnMain(previousTimer)
#endif
    }

}

#if !canImport(FoundationEssentials)
private extension VNCClipboardMonitor {
    static func invalidateOnMain(_ timer: Timer?) {
        guard let timer else { return }
        if Thread.isMainThread {
            timer.invalidate()
        } else {
            // Capture only the timer: this is also called during deinit.
            DispatchQueue.main.async(execute: DispatchWorkItem { timer.invalidate() })
        }
    }

    func timerDidFire(_ timer: Timer) {
        lifecycleLock.lock()
        let isCurrent = timer === self.timer
        lifecycleLock.unlock()
        guard isCurrent, let delegate else { return }

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
#endif
