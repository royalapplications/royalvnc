#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(WinSDK)
import WinSDK
#endif

#if canImport(Glibc)
import Glibc
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
