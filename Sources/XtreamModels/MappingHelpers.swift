import Foundation

/// A Decodable wrapper that accepts both String and numeric JSON values,
/// storing the result as a String. Xtream APIs are inconsistent and may
/// return the same field as a string or a number depending on the server.
public struct FlexibleString: Sendable, Decodable, Equatable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self.value = str
        } else if let int = try? container.decode(Int.self) {
            self.value = String(int)
        } else if let double = try? container.decode(Double.self) {
            self.value = String(double)
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Expected String or Number")
            )
        }
    }
}

public enum XtreamMapping {
    public static func integer(from string: String?, default defaultValue: Int = 0) -> Int {
        guard let string, let value = Int(string) else { return defaultValue }
        return value
    }

    public static func optionalInteger(from string: String?) -> Int? {
        guard let string, let value = Int(string) else { return nil }
        return value
    }

    public static func bool(from string: String?, truthyValues: Set<String> = ["1", "true", "TRUE"]) -> Bool {
        guard let string else { return false }
        return truthyValues.contains(string)
    }

    public static func date(from string: String?) -> Date? {
        guard let string, let timestamp = Double(string) else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    public static func portalDate(from string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: string)
    }
}
