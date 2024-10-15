#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import RoyalVNCKit

let logger = PrintLogger()

let settings = VNCConnection.Settings(isDebugLoggingEnabled: true,
                                      hostname: "localhost",
                                      port: 5900,
                                      isShared: true,
                                      isScalingEnabled: true,
                                      useDisplayLink: false,
                                      inputMode: .none,
                                      isClipboardRedirectionEnabled: false,
                                      colorDepth: .depth24Bit,
                                      frameEncodings: .default)

let connection = VNCConnection(settings: settings,
                               logger: logger)

let connectionDelegate = ConnectionDelegate()
connection.delegate = connectionDelegate

print("Connecting...")

connection.connect()

// Start an endless loop
while true {
    
}
