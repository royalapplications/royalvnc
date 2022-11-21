import Foundation

protocol VNCSecurityType {
	static var authenticationType: VNCAuthenticationType { get }
	var authenticationType: VNCAuthenticationType { get }
}
