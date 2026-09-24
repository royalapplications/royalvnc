import Dispatch
import XCTest
@testable import RoyalVNCKit

final class QueueTests: XCTestCase {
    func testEmptyPeekAndDequeueReturnWithoutReentrantLocking() {
        let queue = Queue<Int>()
        XCTAssertTrue(queue.isEmpty)
        XCTAssertNil(queue.peek())
        XCTAssertNil(queue.dequeue())
    }

    func testConcurrentEnqueueAndDequeuePreserveEveryElementOnce() {
        let queue = Queue<Int>()
        DispatchQueue.concurrentPerform(iterations: 2_000) { value in
            queue.enqueue(value)
        }

        var values = Set<Int>()
        while let value = queue.dequeue() {
            XCTAssertTrue(values.insert(value).inserted)
        }
        XCTAssertEqual(values.count, 2_000)
        XCTAssertTrue(queue.isEmpty)
    }
}
