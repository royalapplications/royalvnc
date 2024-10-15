#if canImport(OSLog)
import Foundation
import OSLog

public class OSLogLogger: VNCLogger {
    public var isDebugLoggingEnabled = false
	
	private let logger = Logger.main
    
    public init() { }
	
    public func logDebug(_ message: String) {
		guard isDebugLoggingEnabled else { return }
		
		logger.info("\(message)")
	}
	
    public func logInfo(_ message: String) {
		logger.notice("\(message)")
	}
	
    public func logWarning(_ message: String) {
		logger.warning("\(message)")
	}
	
    public func logError(_ message: String) {
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
#endif
