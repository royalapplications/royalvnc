import Foundation

struct CredentialsKeychain {
	private let keychain = Keychain()
}

extension CredentialsKeychain {
	func username(forHostname hostname: String,
				  port: UInt16) -> String {
		string(forKey: usernameKey(forHostname: hostname, port: port))
	}
	
	func setUsername(_ username: String,
					 forHostname hostname: String,
					 port: UInt16) {
		setString(username, forKey: usernameKey(forHostname: hostname, port: port))
	}
	
	func password(forHostname hostname: String,
				  port: UInt16) -> String {
		string(forKey: passwordKey(forHostname: hostname, port: port))
	}
	
	func setPassword(_ password: String,
					 forHostname hostname: String,
					 port: UInt16) {
		setString(password, forKey: passwordKey(forHostname: hostname, port: port))
	}
}

private extension CredentialsKeychain {
	func string(forKey key: String) -> String {
		guard let data = keychain.get(key: key) else {
			return ""
		}
		
		guard let string = String(data: data, encoding: .utf8) else {
			return ""
		}
		
		return string
	}
	
	func setString(_ string: String,
				   forKey key: String) {
		guard let data = string.data(using: .utf8) else {
			return
		}
		
		keychain.set(data, forKey: key)
	}
	
	func usernameKey(forHostname hostname: String,
					 port: UInt16) -> String {
		"RoyalVNC_\(hostname):\(port)_Username"
	}
	
	func passwordKey(forHostname hostname: String,
					 port: UInt16) -> String {
		"RoyalVNC_\(hostname):\(port)_Password"
	}
}
