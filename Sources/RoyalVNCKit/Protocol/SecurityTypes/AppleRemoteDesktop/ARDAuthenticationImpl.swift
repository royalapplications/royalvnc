#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(Security)
import Security
#endif

extension VNCProtocol.ARDAuthentication {
    struct Authentication {
        let cipherText: Data
        let publicKey: Data

        private init(cipherText: Data,
                     publicKey: Data) {
            self.cipherText = cipherText
            self.publicKey = publicKey
        }

        init?(agreement: DiffieHellmanKeyAgreement,
              username: String,
              password: String) {
            // Get MD5 hash of shared secret
			let secretHash = agreement.secretKey.md5Hash()

            // ciphertext: AES128(shared, username[64]:password[64])
            let credArraySize = 128
            var creds = Data(count: credArraySize)

            let randomCredsDataSuccess = creds.withUnsafeMutableBytes {
                guard let credsBytes = $0.baseAddress else { return false }

#if canImport(Security)
				let randomStatus = SecRandomCopyBytes(kSecRandomDefault, credArraySize, credsBytes)

                guard randomStatus == errSecSuccess else { return false }
#else
				// TODO: Probably not secure
				for i in 0..<credArraySize {
					$0[i] = UInt8.random(in: 0...255)
				}
#endif

                return true
            }

            guard randomCredsDataSuccess else { return nil }

            // ARD has two 64-byte NUL-terminated UTF-8 fields. Reject oversized
            // values rather than truncating by Swift character count, which can
            // trap for multibyte text or overflow the fixed credential buffer.
            let usernameLength = username.utf8.count
            let passwordLength = password.utf8.count
            guard usernameLength <= 63, passwordLength <= 63,
                  !username.utf8.contains(0), !password.utf8.contains(0) else { return nil }

            // Convert username and password strings into C strings
            let usernameC = username.utf8CString
            let passwordC = password.utf8CString

			// Merge username and password into single array
			let fillCredsSuccess = creds.withUnsafeMutableBytes {
				guard let credsBytes = $0.baseAddress else { return false }

				let copyUsernameSuccess = usernameC.withUnsafeBytes { usernameCBytesPtr in
					guard let usernameCBytes = usernameCBytesPtr.baseAddress else { return false }

					credsBytes.copyMemory(from: usernameCBytes,
										  byteCount: usernameLength)

					return true
				}

				guard copyUsernameSuccess else { return false }

				let copyPasswordSuccess = passwordC.withUnsafeBytes { passwordCBytesPtr in
					guard let passwordCBytes = passwordCBytesPtr.baseAddress else { return false }

					let credsBytesStartingAtPassword = credsBytes.advanced(by: credArraySize / 2)

					credsBytesStartingAtPassword.copyMemory(from: passwordCBytes,
															byteCount: passwordLength)

					return true
				}

				guard copyPasswordSuccess else { return false }

				return true
			}

			guard fillCredsSuccess else { return nil }

			// Add null bytes to indicate end of c string
			creds[usernameLength] = 0
			creds[(credArraySize / 2) + passwordLength] = 0

			guard let cipherText = creds.aes128ECBEncrypted(withKey: secretHash) else {
				return nil
			}

            self.init(cipherText: cipherText,
                      publicKey: agreement.publicKey)
        }
    }
}
