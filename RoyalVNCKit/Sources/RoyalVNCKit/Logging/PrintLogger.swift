import Foundation

class PrintLogger: VNCLogger {
	var isDebugLoggingEnabled = false
	
	func logDebug(_ message: String) {
		guard isDebugLoggingEnabled else { return }
		
		log(debugMessage(message))
	}
	
	func logInfo(_ message: String) {
		log(infoMessage(message))
	}
	
	func logWarning(_ message: String) {
		log(warningMessage(message))
	}
	
	func logError(_ message: String) {
		log(errorMessage(message))
	}
}

private extension PrintLogger {
	func log(_ message: String) {
		print(message)
	}
}
