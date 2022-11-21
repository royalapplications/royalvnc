import Foundation

struct Queue<T> {
	private var list = [T]()
	
	mutating func enqueue(_ element: T) {
		list.append(element)
	}
	
	mutating func dequeue() -> T? {
		guard !isEmpty else { return nil }
		
		return list.removeFirst()
	}
	
	mutating func clear() {
		list.removeAll()
	}
	
	func peek() -> T? {
		guard !isEmpty else { return nil }
		
		return list[0]
	}
	
	var isEmpty: Bool {
		return list.isEmpty
	}
}
