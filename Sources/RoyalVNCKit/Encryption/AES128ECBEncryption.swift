#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(CommonCrypto)
import CommonCrypto
#endif

struct AES128ECBEncryption {
    static func encrypt(data: Data,
                        key: Data) -> Data? {
#if canImport(CommonCrypto)
        let cipherBufferSize = data.count + kCCBlockSizeAES128
        var cipherBuffer = Data(repeating: 0, count: cipherBufferSize)
        
        var cipherData: Data?
        
        cipherBuffer.withUnsafeMutableBytes { cipherBufferBytesPtr in
            guard let cipherBufferPtr = cipherBufferBytesPtr.baseAddress else { return }
            
            data.withUnsafeBytes { dataBytesPtr in
                guard let dataPtr = dataBytesPtr.baseAddress else { return }
                
                key.withUnsafeBytes { keyBytesPtr in
                    guard let keyPtr = keyBytesPtr.baseAddress else { return }
                    
                    var cryptor: CCCryptorRef?
                    
                    let createStatus = CCCryptorCreateWithMode(.init(kCCEncrypt),
                                                               .init(kCCModeECB),
                                                               .init(kCCAlgorithmAES128),
                                                               .init(ccNoPadding),
                                                               nil,
                                                               keyPtr,
                                                               key.count,
                                                               nil,
                                                               0,
                                                               0,
                                                               .zero,
                                                               &cryptor)
                    
                    defer {
                        if let cryptor = cryptor {
                            CCCryptorRelease(cryptor)
                        }
                    }
                    
                    guard createStatus == kCCSuccess,
                          let cryptor = cryptor else {
                        return
                    }
                    
                    var actualLength = 0
                    
                    let updateStatus = CCCryptorUpdate(cryptor,
                                                       dataPtr,
                                                       data.count,
                                                       cipherBufferPtr,
                                                       cipherBufferSize,
                                                       &actualLength)
                    
                    guard updateStatus == kCCSuccess else {
                        return
                    }
                    
                    var finalCipherBuffer = Data(bytes: cipherBufferPtr,
                                                 count: actualLength)
                    
                    finalCipherBuffer.withUnsafeMutableBytes { finalCipherBufferBytesPtr in
                        guard let finalCipherBufferPtr = finalCipherBufferBytesPtr.baseAddress else { return }
                        
                        let finalStatus = CCCryptorFinal(cryptor,
                                                         finalCipherBufferPtr,
                                                         actualLength,
                                                         &actualLength)
                        
                        guard finalStatus == kCCSuccess else {
                            return
                        }
                    }
                    
                    cipherData = finalCipherBuffer
                }
            }
        }
        
        return cipherData
#else
        // TODO: swift-crypto does not seem to support AES ECB Mode
        fatalError("TODO: swift-crypto does not seem to support AES ECB Mode")
#endif
    }
}
