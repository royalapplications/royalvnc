#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import RoyalVNCKit

class ConnectionDelegate: VNCConnectionDelegate {
    func connection(_ connection: VNCConnection,
                    stateDidChange connectionState: VNCConnection.ConnectionState) {
        let connectionStateString: String
        
        switch connectionState.status {
            case .connecting:
                connectionStateString = "Connecting"
            case .connected:
                connectionStateString = "Connected"
            case .disconnecting:
                connectionStateString = "Disconnecting"
            case .disconnected:
                connectionStateString = "Disconnected"
        }
        
        connection.logger.logDebug("connection stateDidChange: \(connectionStateString)")
    }
    
    func connection(_ connection: VNCConnection,
                    credentialFor authenticationType: VNCAuthenticationType,
                    completion: @escaping ((any VNCCredential)?) -> Void) {
        let authenticationTypeString: String
        
        switch authenticationType {
            case .vnc:
                authenticationTypeString = "VNC"
            case .appleRemoteDesktop:
                authenticationTypeString = "Apple Remote Desktop"
            case .ultraVNCMSLogonII:
                authenticationTypeString = "UltraVNC MS Logon II"
        }
        
        connection.logger.logDebug("connection credentialFor: \(authenticationTypeString)")
        
        func readUsername() -> String? {
            print("Enter username: ", terminator: "")
            let username = readLine(strippingNewline: true)
            
            return username
        }
        
        func readPassword() -> String? {
            print("Enter password: ", terminator: "")
            
            // TODO: Hide while typing
            let password = readLine(strippingNewline: true)
            
            return password
        }
        
        if authenticationType.requiresUsername,
           authenticationType.requiresPassword {
            guard let username = readUsername() else {
                completion(nil)
                
                return
            }
            
            guard let password = readPassword() else {
                completion(nil)
                
                return
            }
            
            completion(VNCUsernamePasswordCredential(username: username,
                                                     password: password))
        } else if authenticationType.requiresPassword {
            guard let password = readPassword() else {
                completion(nil)
                
                return
            }
            
            completion(VNCPasswordCredential(password: password))
        } else {
            completion(nil)
        }
    }
    
    func connection(_ connection: VNCConnection,
                    didCreateFramebuffer framebuffer: VNCFramebuffer) {
        connection.logger.logDebug("connection didCreateFramebuffer")
    }
    
    func connection(_ connection: VNCConnection,
                    didResizeFramebuffer framebuffer: VNCFramebuffer) {
        connection.logger.logDebug("connection didResizeFramebuffer")
    }
    
#if os(Linux)
    func connection(_ connection: VNCConnection,
                    framebuffer: VNCFramebuffer,
                    didUpdateRegion updatedRegion: VNCRegion) {
        connection.logger.logDebug("connection framebuffer didUpdateRegion")
    }
#else
    func connection(_ connection: VNCConnection,
                    framebuffer: VNCFramebuffer,
                    didUpdateRegion updatedRegion: CGRect) {
        connection.logger.logDebug("connection framebuffer didUpdateRegion")
    }
#endif
    
    func connection(_ connection: VNCConnection,
                    didUpdateCursor cursor: VNCCursor) {
        connection.logger.logDebug("connection didUpdateCursor")
    }
}
