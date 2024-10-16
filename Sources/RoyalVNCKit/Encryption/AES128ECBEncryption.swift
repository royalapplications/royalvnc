#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(CommonCrypto)
import CommonCrypto
#elseif canImport(OpenSSL)
import OpenSSL
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
#elseif canImport(OpenSSL)
        // Ensure the key is 16 bytes for AES-128
        guard key.count == 16 else { return nil }

        // Create and initialize the context
        guard let ctx = EVP_CIPHER_CTX_new() else { 
            return nil
        }

        defer {
            EVP_CIPHER_CTX_free(ctx)
        }

        // Initialize the encryption operation with AES-128 in ECB mode
        let encInitResult: Int32 = key.withUnsafeBytes {
            guard let keyPtr = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return -1
            }

            let res = EVP_EncryptInit_ex(ctx, EVP_aes_128_ecb(), nil, keyPtr, nil)

            return res
        }

        guard encInitResult == 1 else {
            return nil
        }

        var outLen: Int32 = 0
        var finalLen: Int32 = 0

        let blockSizeAES128 = 16

        // Create a buffer for the ciphertext
        let cipherBufferLen = data.count + blockSizeAES128
        var cipherBuffer = Data(repeating: 0, count: cipherBufferLen)

        // Encrypt the data
        let encUpdateResult: Int32 = data.withUnsafeBytes { dataPtr in
            guard let dataPtrAddr = dataPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return -1
            }

            let res: Int32 = cipherBuffer.withUnsafeMutableBytes { cipherBufferPtr in
                guard let cipherBufferPtrAddr = cipherBufferPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    return -1
                }

                let innerRes = EVP_EncryptUpdate(ctx, cipherBufferPtrAddr, &outLen, dataPtrAddr, Int32(data.count))

                return innerRes    
            }

            return res
        }

        guard encUpdateResult == 1 else {
            return nil
        }

        guard outLen <= cipherBufferLen else {
            return nil
        }

        // Finalize the encryption
        let encFinalResult: Int32 = cipherBuffer.withUnsafeMutableBytes { cipherBufferPtr in
            guard let cipherBufferPtrAddr = cipherBufferPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return -1
            }

            let res = EVP_EncryptFinal_ex(ctx, &cipherBufferPtrAddr[Int(outLen)], &finalLen)

            return res
        }

        guard encFinalResult == 1 else {
            return nil
        }

        let encData = Data(cipherBuffer[0..<outLen])

        return encData
#else
        fatalError("TODO: AES 128 ECB Mode is not implemented on this platform")
#endif
    }
}
