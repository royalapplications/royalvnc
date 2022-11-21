import Foundation

extension Array where Element: Hashable {
	func uniqued() -> Array {
		var unique = Set<Element>()
		
		return filter { element in
			return unique.insert(element).inserted
		}
	}
}
