#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import Dispatch

#if canImport(Network)
import Network
#endif

#if canImport(ObjectiveC)
@objc(VNCConnection)
#endif
public class VNCConnection: NSObjectOrAnyObject {
	// MARK: - Public Properties
#if canImport(ObjectiveC)
	@objc
#endif
	public let settings: Settings
    
    public let context: UnsafeMutableRawPointer?
	
#if canImport(ObjectiveC)
	@objc
#endif
	public weak var delegate: VNCConnectionDelegate?
	
#if canImport(ObjectiveC)
	@objc
#endif
	public var framebuffer: VNCFramebuffer?
	
#if canImport(ObjectiveC)
	@objc
#endif
	public internal(set) var connectionState = ConnectionState.disconnected
	
#if canImport(ObjectiveC)
	@objc
#endif
	public let logger: VNCLogger
	
	// MARK: - Private Properties
	private let queue = DispatchQueue(label: "com.royalapps.royalvnc.connectionqueue",
									  attributes: .concurrent)
	
	private let sharedZStream: ZlibStream
	
	// MARK: - Internal Properties
    let taskPriority = TaskPriority.high
    
	var receiveTask: Task<(), Error>?
	var sendTask: Task<(), Error>?
	
	let maxSupportedProtocolVersion = VNCProtocol.ProtocolVersion(majorVersion: 3,
																  minorVersion: 8)
	
	let state = State()
	let systemSound = VNCSystemSound()
	
	let clipboard: VNCClipboard
	let clipboardMonitor: VNCClipboardMonitor
	
	var clientToServerMessageQueue = Queue<VNCSendableMessage>()
	
    lazy var connection: some NetworkConnection = {
        let connectionSettings = NetworkConnectionSettings(connectionTimeout: 15,
                                                           host: settings.hostname,
                                                           port: settings.port)
        
#if canImport(Network)
        let connection = NWConnection(settings: connectionSettings)
#else
		let connection = LinuxNetworkConnection(settings: connectionSettings)
#endif
        
        connection.setStatusUpdateHandler(connectionStatusDidChange)
		
		return connection
	}()
	
	lazy var encodings: Encodings = {
		let rawEncoding = VNCProtocol.RawEncoding()
		let hextileEncoding = VNCProtocol.HextileEncoding(rawEncoding: rawEncoding)
		
		let compressionLevelEncodingType = VNCPseudoEncodingType.compressionLevel6.rawValue
		let compressionLevelEncoding = VNCProtocol.CompressionLevelEncoding(encodingType: compressionLevelEncodingType)
		
		let encs: Encodings = [
			// Frame Encodings
			VNCFrameEncodingType.copyRect.rawValue: VNCProtocol.CopyRectEncoding(),
			VNCFrameEncodingType.zlib.rawValue: VNCProtocol.ZlibEncoding(zStream: sharedZStream),
			VNCFrameEncodingType.zrle.rawValue: VNCProtocol.ZRLEEncoding(zStream: sharedZStream),
			VNCFrameEncodingType.hextile.rawValue: hextileEncoding,
			VNCFrameEncodingType.coRRE.rawValue: VNCProtocol.RREEncoding(),
			VNCFrameEncodingType.rre.rawValue: VNCProtocol.RREEncoding(),
			VNCFrameEncodingType.raw.rawValue: rawEncoding,
			
			// Pseudo Encodings
			VNCPseudoEncodingType.lastRect.rawValue: VNCProtocol.LastRectEncoding(),
			VNCPseudoEncodingType.continuousUpdates.rawValue: VNCProtocol.ContinuousUpdatesEncoding(),
			VNCPseudoEncodingType.extendedDesktopSize.rawValue: VNCProtocol.ExtendedDesktopSizeEncoding(),
			VNCPseudoEncodingType.desktopSize.rawValue: VNCProtocol.DesktopSizeEncoding(),
			VNCPseudoEncodingType.desktopName.rawValue: VNCProtocol.DesktopNameEncoding(),
			VNCPseudoEncodingType.cursor.rawValue: VNCProtocol.CursorEncoding(),
			compressionLevelEncodingType: compressionLevelEncoding
		]
		
		// Sanity Check
		do {
			let encodingTypes = encs.values.map({ $0.encodingType })
			
			try encodingTypes.validate()
		} catch {
            // If the sanity check fails here, it's a programming error
			fatalError(error.debugDescription)
		}
		
		return encs
	}()
	
	func orderedEncodingTypes() throws -> [VNCEncodingType] {
		// Frame Encodings (Required)
		var encs: [VNCEncodingType] = [
			VNCFrameEncodingType.copyRect.rawValue
		]
		
		// Frame Encodings (Customizable)
		var customizedFrameEncodings = settings.frameEncodings.map({ $0.rawValue })
		
		// TODO: Remove once we support ZRLE for non-24-bit pixel formats
		if let pixelFormat = state.pixelFormat,
		   customizedFrameEncodings.contains(VNCFrameEncodingType.zrle.rawValue),
		   !VNCProtocol.ZRLEEncoding.supportsPixelFormat(pixelFormat) {
			customizedFrameEncodings.removeAll(where: { $0 == VNCFrameEncodingType.zrle.rawValue })
		}
		
		encs.append(contentsOf: customizedFrameEncodings)
		
		// Frame Encodings (Required)
		encs.append(VNCFrameEncodingType.raw.rawValue)
		
		// Pseudo Encodings
		encs.append(contentsOf: [
			VNCPseudoEncodingType.lastRect.rawValue,
			VNCPseudoEncodingType.continuousUpdates.rawValue,
			VNCPseudoEncodingType.extendedDesktopSize.rawValue,
			VNCPseudoEncodingType.desktopSize.rawValue,
			VNCPseudoEncodingType.desktopName.rawValue,
			VNCPseudoEncodingType.cursor.rawValue,
			// TODO: Implement
//			VNCPseudoEncodingType.extendedClipboard.rawValue,
			VNCPseudoEncodingType.compressionLevel6.rawValue
		])
		
		let uniqueEncs = encs.uniqued()
		
		// Sanity Check
        // If the sanity check fails here, it could be a programming error, but it could also be an error by the SDK user if he/she specified encodings with invalid values in settings. So we bubble the error up but don't crash.
		try uniqueEncs.validate()
		
		return uniqueEncs
	}
	
	// MARK: - Public Initializers
    public init(settings: Settings,
                logger: VNCLogger,
                context: UnsafeMutableRawPointer?) {
        self.settings = settings
        
        logger.isDebugLoggingEnabled = settings.isDebugLoggingEnabled
        
        self.logger = logger
        
        self.context = context
        
        self.sharedZStream = .init()
        
        let clipboard = VNCClipboard()
        
        let clipboardMonitor = VNCClipboardMonitor(clipboard: clipboard,
                                                   monitoringInterval: 0.5,
                                                   tolerance: 0.15)
        
        self.clipboard = clipboard
        
        self.clipboardMonitor = clipboardMonitor
        
        super.init()
        
        self.clipboardMonitor.delegate = self
    }
    
#if canImport(ObjectiveC)
	@objc
#endif
    public convenience init(settings: Settings,
                            logger: VNCLogger) {
        self.init(settings: settings,
                  logger: logger,
                  context: nil)
	}
	
#if canImport(ObjectiveC)
	@objc
#endif
	public convenience init(settings: Settings) {
        self.init(settings: settings,
                  context: nil)
	}
    
    public convenience init(settings: Settings,
                            context: UnsafeMutableRawPointer?) {
#if canImport(OSLog)
        let logger = VNCOSLogLogger()
#else
        let logger = VNCPrintLogger()
#endif
        
        self.init(settings: settings,
                  logger: logger,
                  context: context)
    }
	
	deinit {
		let _self = self
		
		_self.clipboardMonitor.delegate = nil
		
		stopMonitoringClipboard()
	}
}

// MARK: - Internal Connection State API
extension VNCConnection {
	func beginConnecting() {
		updateConnectionState(.connecting)
		
		connection.start(queue: queue)
	}
	
	func beginDisconnecting(error: Error? = nil) {
		guard !state.disconnectRequested else { return }
		
		state.disconnectRequested = true
		updateConnectionState(.disconnecting)
		
		connection.setStatusUpdateHandler(nil)
		connection.cancel()
		
		if let error = error {
			updateConnectionState(.disconnected(error: error))
		} else {
			updateConnectionState(.disconnected)
		}
	}
	
	func handleBreakingError(_ error: Error) {
		beginDisconnecting(error: error)
	}
	
	func updateConnectionState(_ newConnectionState: ConnectionState) {
		self.connectionState = newConnectionState
		
		switch newConnectionState.status {
			case .connecting:
				break
				
			case .connected:
				startMonitoringClipboard()
				
			case .disconnecting:
				stopMonitoringClipboard()
				
			case .disconnected:
				stopMonitoringClipboard()
		}
		
		notifyDelegateAboutConnectionStateChange(newConnectionState)
	}
}

// MARK: - Connection State Change Handling
private extension VNCConnection {
	func connectionStatusDidChange(_ newState: NetworkConnectionStatus) {
		switch newState {
			case .setup:
				logger.logDebug("Connection State - Setup")
				
			case .preparing:
				logger.logDebug("Connection State - Preparing")
				
			case .ready:
				logger.logDebug("Connection State - Ready")
				
				connectionDidBecomeReady()
				
			case .waiting(let error):
				logger.logDebug("Connection State - Waiting with error: \(error)")
				
				connectionDidFail(error: .connection(.failed(error)))
				
			case .failed(let error):
				logger.logDebug("Connection State - Failed with error: \(error)")
				
				connectionDidFail(error: .connection(.failed(error)))
			
			case .cancelled:
				logger.logDebug("Connection State - Cancelled")
				
				connectionDidFail(error: .connection(.cancelled))
				
            case .unknown(let underlyingState):
				logger.logDebug("Connection State - Unknown (\(underlyingState))")
		}
	}
	
	func connectionDidBecomeReady() {
		Task {
			do {
				try await handshake()
				try await sendFramebufferUpdateRequest()
			} catch {
				handleBreakingError(error)
                
                return
			}
			
			updateConnectionState(.connected)
			
			startReceiveLoop()
			startSendLoop()
		}
	}
	
	func connectionDidFail(error: VNCError) {
		handleBreakingError(error)
	}
}
