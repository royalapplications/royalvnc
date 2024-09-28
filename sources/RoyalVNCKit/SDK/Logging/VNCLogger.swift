import Foundation

@objc(VNCLogger)
public protocol VNCLogger: AnyObject {
	@objc
	var isDebugLoggingEnabled: Bool { get set }
	
	@objc
	func logDebug(_ message: String)
	
	@objc
	func logInfo(_ message: String)
	
	@objc
	func logWarning(_ message: String)
	
	@objc
	func logError(_ message: String)
}

private struct VNCLoggerConstants {
	static let prefixDebug = "DEBUG"
	static let prefixInfo = "INFO"
	static let prefixWarning = "WARNING"
	static let prefixError = "ERROR"
}

extension VNCLogger {
	func debugMessage(_ message: String) -> String {
		prefixedMessage(message,
						prefix: VNCLoggerConstants.prefixDebug)
	}
	
	func infoMessage(_ message: String) -> String {
		prefixedMessage(message,
						prefix: VNCLoggerConstants.prefixInfo)
	}
	
	func warningMessage(_ message: String) -> String {
		prefixedMessage(message,
						prefix: VNCLoggerConstants.prefixWarning)
	}
	
	func errorMessage(_ message: String) -> String {
		prefixedMessage(message,
						prefix: VNCLoggerConstants.prefixError)
	}
	
	func prefixedMessage(_ message: String,
						 prefix: String) -> String {
		"\(prefix) - \(message)"
	}
}
