#if canImport(CFNetwork)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import CFNetwork
import CoreFoundation
import Dispatch

/// Apple socket streams can enable TLS on an open stream, preserving the TCP
/// connection required by VeNCrypt. This transport is intentionally separate
/// from `NWConnection`, whose parameters cannot be changed after it starts.
final class CFStreamNetworkConnection: TLSUpgradableNetworkConnection {
	let settings: NetworkConnectionSettings

	private var readStream: CFReadStream?
	private var writeStream: CFWriteStream?
	private var lifecycleQueue = DispatchQueue(label: "com.royalapps.royalvnc.cfstream.lifecycle.placeholder")
	private let readQueue = DispatchQueue(label: "com.royalapps.royalvnc.cfstream.read")
	private let writeQueue = DispatchQueue(label: "com.royalapps.royalvnc.cfstream.write")
	private var didUpgradeToTLS = false

	private(set) var statusUpdateHandler: NetworkConnectionStatusUpdateHandler?
	private(set) var status: NetworkConnectionStatus = .setup {
		didSet { statusUpdateHandler?(status) }
	}

	init(settings: NetworkConnectionSettings) {
		self.settings = settings
	}

	var isReady: Bool {
		if case .ready = status { return true }
		return false
	}

	func setStatusUpdateHandler(_ statusUpdateHandler: NetworkConnectionStatusUpdateHandler?) {
		self.statusUpdateHandler = statusUpdateHandler
	}

	func start(queue: DispatchQueue) {
		self.lifecycleQueue = queue
		status = .preparing

		queue.async { [weak self] in
			guard let self else { return }

			var readStream: Unmanaged<CFReadStream>?
			var writeStream: Unmanaged<CFWriteStream>?
			CFStreamCreatePairWithSocketToHost(
				kCFAllocatorDefault,
				settings.host as CFString,
				UInt32(settings.port),
				&readStream,
				&writeStream
			)

			guard let read = readStream?.takeRetainedValue(),
				  let write = writeStream?.takeRetainedValue(),
				  CFReadStreamOpen(read),
				  CFWriteStreamOpen(write) else {
				self.status = .failed(VNCError.connection(.failed(nil)))
				return
			}

			self.readStream = read
			self.writeStream = write
			self.status = .ready
		}
	}

	func cancel() {
		let group = DispatchGroup()
		group.enter()
		readQueue.async { [weak self] in
			guard let self else { group.leave(); return }
			if let readStream { CFReadStreamClose(readStream) }
			readStream = nil
			group.leave()
		}
		group.enter()
		writeQueue.async { [weak self] in
			guard let self else { group.leave(); return }
			if let writeStream { CFWriteStreamClose(writeStream) }
			writeStream = nil
			group.leave()
		}
		group.notify(queue: lifecycleQueue) { [weak self] in
			self?.status = .cancelled
		}
	}

	func upgradeToTLS(serverName: String) async throws {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			readQueue.async { [weak self] in
				guard let self, let readStream, !didUpgradeToTLS else {
					continuation.resume(throwing: VNCError.protocol(.invalidData))
					return
				}

				let settings: [CFString: Any] = [
					kCFStreamSSLPeerName: serverName,
					kCFStreamSSLValidatesCertificateChain: true,
					kCFStreamSSLLevel: kCFStreamSocketSecurityLevelNegotiatedSSL
				]

				guard CFReadStreamSetProperty(readStream, CFStreamPropertyKey(kCFStreamPropertySSLSettings), settings as CFDictionary) else {
					continuation.resume(throwing: VNCError.connection(.failed(nil)))
					return
				}

				didUpgradeToTLS = true
				continuation.resume()
			}
		}
	}

	func read(minimumLength: Int, maximumLength: Int) async throws -> Data {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
			readQueue.async { [weak self] in
				guard let self, let readStream else {
					continuation.resume(throwing: VNCError.connection(.closed))
					return
				}

				var buffer = [UInt8](repeating: 0, count: maximumLength)
				var received = 0

				repeat {
					let count = buffer.withUnsafeMutableBufferPointer {
						CFReadStreamRead(readStream, $0.baseAddress?.advanced(by: received), maximumLength - received)
					}
					guard count > 0 else {
						continuation.resume(throwing: VNCError.protocol(.noData))
						return
					}
					received += count
				} while received < minimumLength

				continuation.resume(returning: Data(buffer.prefix(received)))
			}
		}
	}

	func write(data: Data) async throws {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			writeQueue.async { [weak self] in
				guard let self, let writeStream else {
					continuation.resume(throwing: VNCError.connection(.closed))
					return
				}

				let bytes = [UInt8](data)
				var offset = 0
				while offset < bytes.count {
					let count = bytes.withUnsafeBufferPointer {
						CFWriteStreamWrite(writeStream, $0.baseAddress?.advanced(by: offset), bytes.count - offset)
					}
					guard count > 0 else {
						continuation.resume(throwing: VNCError.connection(.failed(nil)))
						return
					}
					offset += count
				}

				continuation.resume()
			}
		}
	}
}
#endif
