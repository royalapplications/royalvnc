#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public final class VNCCustomLogger: VNCLogger {
    public typealias LogHandler = (_ message: String) -> Void

    public let logDebugHandler: LogHandler
    public let logInfoHandler: LogHandler
    public let logWarningHandler: LogHandler
    public let logErrorHandler: LogHandler

    public var isDebugLoggingEnabled = false

    public init(logDebugHandler: @escaping LogHandler,
                logInfoHandler: @escaping LogHandler,
                logWarningHandler: @escaping LogHandler,
                logErrorHandler: @escaping LogHandler) {
        self.logDebugHandler = logDebugHandler
        self.logInfoHandler = logInfoHandler
        self.logWarningHandler = logWarningHandler
        self.logErrorHandler = logErrorHandler
    }

    public func logDebug(_ message: String) {
        guard isDebugLoggingEnabled else { return }

        logDebugHandler(message)
    }

    public func logInfo(_ message: String) {
        logInfoHandler(message)
    }

    public func logWarning(_ message: String) {
        logWarningHandler(message)
    }

    public func logError(_ message: String) {
        logErrorHandler(message)
    }
}
