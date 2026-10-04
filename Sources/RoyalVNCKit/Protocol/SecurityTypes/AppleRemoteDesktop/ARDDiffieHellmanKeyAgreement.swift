#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension VNCProtocol.ARDAuthentication {
	struct DiffieHellmanKeyAgreement {
		// Bound work before allocating or exponentiating server-supplied values.
		// This 4096-bit implementation resource limit is not an ARD protocol limit.
		static let maximumKeySize = 512

		let publicKey: Data
		let privateKey: Data
		let secretKey: Data

		init?(prime: Data,
			  generator: Data,
			  peerKey: Data,
			  keyLength: Int) {
			guard Self.acceptsParameters(prime: prime, generator: generator,
									peerKey: peerKey, keyLength: keyLength) else {
				return nil
			}

			guard let keyPair = Self.generateKeyPair(generator: generator,
													 prime: prime,
													 keyLength: keyLength),
				  !keyPair.privateKey.isEmpty,
				  !keyPair.publicKey.isEmpty else {
				return nil
			}

			guard let secretKey = Self.computeSharedKey(prime: prime,
														peerKey: peerKey,
														privateKey: keyPair.privateKey,
													keyLength: keyLength),
				  !secretKey.isEmpty else {
				return nil
			}

			self.publicKey = keyPair.publicKey
			self.privateKey = keyPair.privateKey
			self.secretKey = secretKey
		}

		static func acceptsParameters(prime: Data, generator: Data, peerKey: Data,
									  keyLength: Int) -> Bool {
			guard (1...maximumKeySize).contains(keyLength),
				  prime.count == keyLength, peerKey.count == keyLength,
				  (1...2).contains(generator.count),
				  let modulus = BigNum(data: prime), !modulus.isLessThan(5), modulus.isOdd,
				  let base = BigNum(data: generator),
				  let peer = BigNum(data: peerKey) else { return false }
			// These range checks prevent zero-modulus traps, nonterminating
			// private-key selection and trivial public values. They do not prove
			// primality or authenticate the server.
			return base.isValidDiffieHellmanPublicValue(modulus: modulus) &&
				peer.isValidDiffieHellmanPublicValue(modulus: modulus)
		}
	}
}

private extension VNCProtocol.ARDAuthentication.DiffieHellmanKeyAgreement {
	struct KeyPair {
		let publicKey: Data
		let privateKey: Data
	}

	static func generateKeyPair(generator: Data,
								prime: Data,
								keyLength: Int) -> KeyPair? {
		let bigPrivKey = BigNum()
		let bigPubKey = BigNum()

		guard let bigPrime = BigNum(data: prime),
			  let bigGenerator = BigNum(data: generator) else {
			return nil
		}

		// Generate DH private key
		repeat {
			let randSuccess = bigPrivKey.rand(range: bigPrime)

			guard randSuccess else {
				return nil
			}
		} while bigPrivKey.isZero

		let modSuccess = BigNum.modExp(y: bigPubKey,
									   g: bigGenerator,
									   x: bigPrivKey,
									   p: bigPrime)

		guard modSuccess else {
			return nil
		}

		// ARD encodes DH values at the server's advertised width. A leading
		// zero byte is valid and must remain part of the shared-secret hash.
		guard let privKey = bigPrivKey.fixedWidthBigEndianData(length: keyLength),
			  let pubKey = bigPubKey.fixedWidthBigEndianData(length: keyLength) else {
			return nil
		}

		let keyPair = KeyPair(publicKey: pubKey,
							  privateKey: privKey)

		return keyPair
	}

	static func computeSharedKey(prime: Data,
								 peerKey: Data,
								 privateKey: Data,
								 keyLength: Int) -> Data? {
		guard let bigPrime = BigNum(data: prime),
			  let bigPrivKey = BigNum(data: privateKey),
			  let bigPeerKey = BigNum(data: peerKey) else {
			return nil
		}

		let bigSharedKey = BigNum()

		let modSuccess = BigNum.modExp(y: bigSharedKey,
									   g: bigPeerKey,
									   x: bigPrivKey,
									   p: bigPrime)

		guard modSuccess else {
			return nil
		}

		guard let sharedKey = bigSharedKey.fixedWidthBigEndianData(length: keyLength) else {
			return nil
		}

		return sharedKey
	}
}
