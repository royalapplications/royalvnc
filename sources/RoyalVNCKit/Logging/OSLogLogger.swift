import Foundation
import OSLog

class OSLogLogger: VNCLogger {
	var isDebugLoggingEnabled = false
	
	private let logger = Logger.main
	
	func logDebug(_ message: String) {
		guard isDebugLoggingEnabled else { return }
		
		logger.info("\(message)")
	}
	
	func logInfo(_ message: String) {
		logger.notice("\(message)")
	}
	
	func logWarning(_ message: String) {
		logger.warning("\(message)")
	}
	
	func logError(_ message: String) {
		logger.error("\(message)")
	}
}

fileprivate extension Logger {
	private class ClassToGetBundle { }
	
	private static let bundle = Bundle(for: ClassToGetBundle.self)
	
	private static let subsystem = bundle.bundleIdentifier ?? "RoyalVNC"
	private static let category = bundle.infoDictionary?["CFBundleName"] as? String ?? "RoyalVNCKit"
	
	static let main = Logger(subsystem: subsystem, category: category)
}
