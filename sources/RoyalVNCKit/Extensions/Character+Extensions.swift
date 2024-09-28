import Foundation

extension Character {
	var isPrintable: Bool {
		isASCII ||
		isLetter ||
		isNumber ||
		isCurrencySymbol ||
		isMathSymbol ||
		isPunctuation ||
		isSymbol
	}
}
