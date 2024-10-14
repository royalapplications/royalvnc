#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// MARK: - Delegate Notifications
extension VNCConnection {
	func notifyDelegateAboutConnectionStateChange(_ newConnectionState: ConnectionState) {
		delegate?.connection(self,
							 stateDidChange: newConnectionState)
	}
	
	func notifyDelegateAboutFramebufferCreation(_ framebuffer: VNCFramebuffer) {
		delegate?.connection(self,
							 didCreateFramebuffer: framebuffer)
	}
	
	func notifyDelegateAboutFramebufferResize(_ framebuffer: VNCFramebuffer) {
		delegate?.connection(self,
							 didResizeFramebuffer: framebuffer)
	}
	
	func notifyDelegateAboutFramebuffer(_ framebuffer: VNCFramebuffer,
										updatedRegion: VNCRegion) {
		delegate?.connection(self,
							 framebuffer: framebuffer,
							 didUpdateRegion: updatedRegion.cgRect)
	}
	
	func notifyDelegateAboutUpdatedCursor(_ cursor: VNCCursor) {
		delegate?.connection(self,
							 didUpdateCursor: cursor)
	}
	
	func askDelegateForPasswordCredential(authenticationType: VNCAuthenticationType) async throws -> VNCPasswordCredential {
		guard let passwordCredential = try await askDelegateForCredential(authenticationType: authenticationType) as? VNCPasswordCredential else {
			throw VNCError.authentication(.noAuthenticationDataProvided)
		}
		
		return passwordCredential
	}
	
	func askDelegateForUsernamePasswordCredential(authenticationType: VNCAuthenticationType) async throws -> VNCUsernamePasswordCredential {
		guard let usernamePasswordCredential = try await askDelegateForCredential(authenticationType: authenticationType) as? VNCUsernamePasswordCredential else {
			throw VNCError.authentication(.noAuthenticationDataProvided)
		}
		
		return usernamePasswordCredential
	}
}

private extension VNCConnection {
	func askDelegateForCredential(authenticationType: VNCAuthenticationType) async throws -> VNCCredential {
		guard let delegate = delegate else {
			throw VNCError.authentication(.noAuthenticationDataProvided)
		}
		
		guard let credential: VNCCredential? = await withCheckedContinuation({ [weak self] continuation in
			guard let self else {
				continuation.resume(returning: nil)
				
				return
			}
			
			delegate.connection(self,
								credentialFor: authenticationType) { credential in
				continuation.resume(returning: credential)
			}
		}) else {
			throw VNCError.authentication(.noAuthenticationDataProvided)
		}
		
		guard let credential = credential else {
			throw VNCError.authentication(.noAuthenticationDataProvided)
		}
		
		return credential
	}
}
