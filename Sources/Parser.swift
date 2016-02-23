import String

extension String {

    public func indexOfCharacter(char: Character) -> Int? {
        if let idx = self.characters.indexOf(char) {
            return self.startIndex.distanceTo(idx)
        }
        return nil
    }
}

public enum ResponseError: ErrorType {
	case InvalidResponse(byte: Character, response: String)
	case ServerError(error: String)

}

// For more info: http://redis.io/topics/protocol
struct Parser {

	static func read_response(fullResponse: String) throws -> Any? {

		let byte: Character = fullResponse[fullResponse.startIndex]
		let response: String = fullResponse[fullResponse.startIndex.advancedBy(1)..<fullResponse.endIndex]

		var result: Any?

		guard ["+", "-", ":", "$", "*"].indexOf(byte) != nil else { throw ResponseError.InvalidResponse(byte: byte, response: response) }

		switch byte {
		case "-":
			// Server error
			throw ResponseError.ServerError(error: response)
		case ":":
			// Simple integer
			let idx = Int(response.indexOfCharacter("\r\n")!)
			result = Int(response[response.startIndex..<response.startIndex.advancedBy(idx)])
		case "+":
			// Simple scleng
			result = String(response)
		case "$":
			// Bulk string
			let idx = Int(response.indexOfCharacter("\r\n")!)
			if response[response.startIndex..<response.startIndex.advancedBy(idx)] == "-1" {
				// nil string
				result = nil
			} else {
				result = String(response[response.startIndex.advancedBy(idx)..<response.endIndex])
			}

		case "*":
			// Arrays
			var values = response.characters.split("\r\n").map(String.init)
			var tmp: [String?] = []

			// first value is the array size
			values.removeAtIndex(0)

			for value in values {
				if value[value.startIndex] != "$" {
					tmp.append(value)
				} else if value == "$-1" {
					// check if it's $-1 and append a nil value
					tmp.append(nil)
				}
			}

			result = tmp

		default:
			result = ""
		}

		return result

	}

}