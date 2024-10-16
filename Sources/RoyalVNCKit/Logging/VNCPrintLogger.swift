#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public class VNCPrintLogger: VNCLogger {
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

private extension VNCPrintLogger {
	func log(_ message: String) {
		print(message)
	}
}
