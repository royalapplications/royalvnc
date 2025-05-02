#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WinSDK)
import WinSDK
#elseif canImport(Android)
import Android
#endif

import RoyalVNCKit

// Get hostname either from args or stdin
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

// Create logger
let logger = VNCPrintLogger()

// Create settings
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

// Create connection
let connection = VNCConnection(settings: settings,
                               logger: logger)

// Create connection delegate
let connectionDelegate = ConnectionDelegate()

// Set connection delegate in connection
connection.delegate = connectionDelegate

// Connect
connection.connect()

// Run loop until connection is disconnected
while true {
    let connectionStatus = connection.connectionState.status

    if connectionStatus == .disconnected {
        break
    }

    platformSleep(forTimeInterval: 0.5)
}
