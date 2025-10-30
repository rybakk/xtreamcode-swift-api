import Foundation

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
