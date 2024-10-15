#if !canImport(FoundationEssentials)
import Foundation

public class NSLogLogger: VNCLogger {
    public var isDebugLoggingEnabled = false
    
    public init() { }
	
    public func logDebug(_ message: String) {
		guard isDebugLoggingEnabled else { return }
		
		log(debugMessage(message))
	}
	
    public func logInfo(_ message: String) {
		log(infoMessage(message))
	}
	
    public func logWarning(_ message: String) {
		log(warningMessage(message))
	}
	
    public func logError(_ message: String) {
		log(errorMessage(message))
	}
}

private extension NSLogLogger {
	func log(_ message: String) {
		NSLog(message)
	}
}
#endif
