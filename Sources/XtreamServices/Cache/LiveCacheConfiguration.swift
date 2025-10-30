import Foundation

/// Describes TTL and storage options for the Live/EPG cache.
public struct LiveCacheConfiguration: Sendable {
    public struct DiskOptions: Sendable {
        public let isEnabled: Bool
        public let capacityInBytes: Int
        public let directory: URL?

        public init(
            isEnabled: Bool = true,
            capacityInBytes: Int = 50 * 1024 * 1024,
            directory: URL? = nil
        ) {
            self.isEnabled = isEnabled
            self.capacityInBytes = capacityInBytes
            self.directory = directory
        }
    }

    public var categoriesTTL: TimeInterval
    public var streamsTTL: TimeInterval
    public var streamDetailsTTL: TimeInterval
    public var streamURLsTTL: TimeInterval
    public var shortEPGTTL: TimeInterval
    public var fullEPGTTL: TimeInterval
    public var catchupTTL: TimeInterval
    public var diskOptions: DiskOptions

    public init(
        categoriesTTL: TimeInterval = 6 * 3600,
        streamsTTL: TimeInterval = 1800,
        streamDetailsTTL: TimeInterval = 1800,
        streamURLsTTL: TimeInterval = 300,
        shortEPGTTL: TimeInterval = 600,
        fullEPGTTL: TimeInterval = 300,
        catchupTTL: TimeInterval = 1800,
        diskOptions: DiskOptions = DiskOptions()
    ) {
        self.categoriesTTL = categoriesTTL
        self.streamsTTL = streamsTTL
        self.streamDetailsTTL = streamDetailsTTL
        self.streamURLsTTL = streamURLsTTL
        self.shortEPGTTL = shortEPGTTL
        self.fullEPGTTL = fullEPGTTL
        self.catchupTTL = catchupTTL
        self.diskOptions = diskOptions
    }

    public static let disabled = LiveCacheConfiguration(
        categoriesTTL: 0,
        streamsTTL: 0,
        streamDetailsTTL: 0,
        streamURLsTTL: 0,
        shortEPGTTL: 0,
        fullEPGTTL: 0,
        catchupTTL: 0,
        diskOptions: DiskOptions(isEnabled: false)
    )
}

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
public extension LiveCacheConfiguration {
    func ttl(for key: LiveCacheKey) -> TimeInterval? {
        guard let scope = key.components.first else { return nil }
        switch scope {
        case "live":
            guard key.components.count >= 2 else { return nil }
            switch key.components[1] {
            case "categories":
                return categoriesTTL
            case "streams":
                return streamsTTL
            case "stream":
                return streamDetailsTTL
            case "streamUrls":
                return streamURLsTTL
            default:
                return nil
            }
        case "epg":
            guard key.components.count >= 2 else { return nil }
            switch key.components[1] {
            case "short":
                return shortEPGTTL
            case "full":
                return fullEPGTTL
            default:
                return nil
            }
        case "catchup":
            return catchupTTL
        case "vod":
            guard key.components.count >= 2 else { return nil }
            switch key.components[1] {
            case "categories":
                return categoriesTTL
            case "streams":
                return streamsTTL
            case "info":
                return streamDetailsTTL
            case "streamUrls":
                return streamURLsTTL
            default:
                return nil
            }
        case "series":
            guard key.components.count >= 2 else { return nil }
            switch key.components[1] {
            case "categories":
                return categoriesTTL
            case "items":
                return streamsTTL
            case "info":
                return streamDetailsTTL
            case "episodeUrls":
                return streamURLsTTL
            default:
                return nil
            }
        default:
            return nil
        }
    }
}

// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
