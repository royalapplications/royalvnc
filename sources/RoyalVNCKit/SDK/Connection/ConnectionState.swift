import Foundation

public extension VNCConnection {
	@objc(VNCConnectionStatus)
	enum Status: Int {
		case disconnected
		case connecting
		case connected
		case disconnecting
	}
	
	@objc(VNCConnectionState)
	class ConnectionState: NSObject {
		@objc
		public let status: Status
		
		@objc
		public let error: Error?
		
		static let disconnected: ConnectionState = .init(status: .disconnected,
														 error: nil)
		
		static let disconnecting: ConnectionState = .init(status: .disconnecting,
														  error: nil)
		
		static let connecting: ConnectionState = .init(status: .connecting,
													   error: nil)
		
		static let connected: ConnectionState = .init(status: .connected,
													  error: nil)
		
		init(status: Status,
			 error: Error?) {
			self.status = status
			self.error = error
		}
		
		static func disconnected(error: Error) -> ConnectionState {
			.init(status: .disconnected,
				  error: error)
		}
	}
}
