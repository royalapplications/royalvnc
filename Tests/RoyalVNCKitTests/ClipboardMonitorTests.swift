import XCTest
@testable import RoyalVNCKit

#if os(macOS) || os(iOS)
final class ClipboardMonitorTests: XCTestCase {
    nonisolated private static func lifecycleWorkItem(_ monitor: VNCClipboardMonitor,
                                                      group: DispatchGroup) -> DispatchWorkItem {
        // Create outside a main-actor closure so Swift does not attach a main
        // executor precondition to work intentionally run on background queues.
        DispatchWorkItem {
            monitor.startMonitoring()
            monitor.stopMonitoring()
            group.leave()
        }
    }

    func testConcurrentStartsAndStopsLeaveMonitoringStopped() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async {
                let monitor = VNCClipboardMonitor(
                    clipboard: VNCClipboard(), monitoringInterval: 60, tolerance: 0)
                let group = DispatchGroup()
                for _ in 0..<100 {
                    group.enter()
                    DispatchQueue.global().async(execute: Self.lifecycleWorkItem(monitor, group: group))
                }
                group.notify(queue: .main) {
                    XCTAssertFalse(monitor.isMonitoring)
                    monitor.stopMonitoring()
                    continuation.resume()
                }
            }
        }
    }

    func testActiveTimerDoesNotRetainClipboardMonitor() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async {
                var monitor: VNCClipboardMonitor? = VNCClipboardMonitor(
                    clipboard: VNCClipboard(), monitoringInterval: 60, tolerance: 0)
                monitor?.startMonitoring()
                DispatchQueue.main.async { [weak weakMonitor = monitor] in
                    XCTAssertTrue(monitor?.isMonitoring == true)
                    monitor = nil
                    XCTAssertNil(weakMonitor, "The run-loop timer must not retain its owner")
                    weakMonitor?.stopMonitoring()
                    continuation.resume()
                }
            }
        }
    }

    func testDeferredStartActivatesMonitoring() async {
        await checkLifecycle(stopBeforeStart: false)
    }

    func testStopCancelsDeferredStart() async {
        await checkLifecycle(stopBeforeStart: true)
    }

    private func checkLifecycle(stopBeforeStart: Bool) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async {
                let monitor = VNCClipboardMonitor(clipboard: VNCClipboard(),
                    monitoringInterval: 60, tolerance: 0)
                monitor.startMonitoring()
                if stopBeforeStart { monitor.stopMonitoring() }
                DispatchQueue.main.async {
                    XCTAssertEqual(monitor.isMonitoring, !stopBeforeStart)
                    monitor.stopMonitoring()
                    XCTAssertFalse(monitor.isMonitoring)
                    continuation.resume()
                }
            }
        }
    }
}
#endif
