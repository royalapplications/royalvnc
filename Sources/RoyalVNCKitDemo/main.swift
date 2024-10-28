#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import RoyalVNCKit

let args = CommandLine.arguments
let hostname: String

if args.count >= 2 {
    hostname = args[1]
} else {
    print("Enter hostname: ", terminator: "")
    hostname = readLine(strippingNewline: true) ?? ""
}

guard !hostname.isEmpty else {
    print("No hostname given")
    
    exit(1)
}

let settings = VNCConnection.Settings(isDebugLoggingEnabled: true,
                                      hostname: hostname,
                                      port: 5900,
                                      isShared: true,
                                      isScalingEnabled: true,
                                      useDisplayLink: false,
                                      inputMode: .none,
                                      isClipboardRedirectionEnabled: false,
                                      colorDepth: .depth24Bit,
                                      frameEncodings: .default)

let connection = VNCConnection(settings: settings)

let connectionDelegate = ConnectionDelegate()
connection.delegate = connectionDelegate

print("Connecting...")

connection.connect()

// Start an endless loop
while true {
    platformSleep(forTimeInterval: 0.5)
}
