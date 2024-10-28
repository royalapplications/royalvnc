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
#endif

func platformSleep(forTimeInterval timeInterval: TimeInterval) {
#if canImport(WinSDK)
    let timeIntervalMS = UInt32(timeInterval * 1000.0)
    
    Sleep(timeIntervalMS)
#elseif canImport(Glibc)
    let timeIntervalMicroseconds = UInt32(timeInterval * 1000000.0)
    
    usleep(timeIntervalMicroseconds)
#else
    Thread.sleep(forTimeInterval: timeInterval)
#endif
}

func readPassword(prompt: String) -> String? {
#if canImport(Darwin)
    var buffer = [CChar](repeating: 0,
                         count: 4096)
    
    guard let passwordC = readpassphrase(prompt,
                                         &buffer,
                                         buffer.count,
                                         0) else {
        return nil
    }
    
    let password = String(cString: passwordC)
    
    return password
#else
    // TODO: Implement password input for other platforms
    print(prompt, terminator: "")
    
    let password = readLine(strippingNewline: true)
    
    return password
#endif
}
