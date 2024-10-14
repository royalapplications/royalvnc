#if os(Linux)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import Dispatch

final class LinuxNetworkConnection: NetworkConnection {
    init(settings: NetworkConnectionSettings) {
        fatalError("Not implemented")
    }

    var status: NetworkConnectionStatus {
        fatalError("Not implemented")
    }
    
    func setStatusUpdateHandler(_ statusUpdateHandler: NetworkConnectionStatusUpdateHandler?) {
        fatalError("Not implemented")
    }
    
    var isReady: Bool {
        fatalError("Not implemented")
    }
    
    func cancel() {
        fatalError("Not implemented")
    }

    func start(queue: DispatchQueue) {
        fatalError("Not implemented")
    }
}

extension LinuxNetworkConnection: NetworkConnectionReading {
	func read(minimumLength: Int,
              maximumLength: Int) async throws -> Data {
		fatalError("Not implemented")
	}
}

extension LinuxNetworkConnection: NetworkConnectionWriting {
	func write(data: Data) async throws {
		fatalError("Not implemented")
	}
}
#endif
