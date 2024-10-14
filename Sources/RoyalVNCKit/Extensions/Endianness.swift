#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// TODO: CoreFoudnation
import CoreFoundation

enum Endianness {
    case little
    case big
}

extension Endianness {
    static var current: Endianness {
        let byteOrder = CFByteOrderGetCurrent()
        
        let endianess: Endianness = byteOrder == .init(CFByteOrderLittleEndian.rawValue)
            ? .little
            : .big
        
        return endianess
    }
}
