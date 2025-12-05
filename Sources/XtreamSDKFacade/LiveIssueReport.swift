import Foundation
#if canImport(XtreamServices)
import XtreamServices
#endif

public enum MediaIssueDomain: String, Codable, Sendable {
    case live
    case vod
    case series
    case search
}

public struct LiveIssueReport: Sendable, Codable {
    public let domain: MediaIssueDomain
    public struct Metadata: Sendable, Codable {
        public let generatedAt: Date
        public let username: String
        public let baseURL: URL
        public let sdkVersion: String?
        public let platform: String

        public init(
            generatedAt: Date,
            username: String,
            baseURL: URL,
            sdkVersion: String?,
            platform: String
        ) {
            self.generatedAt = generatedAt
            self.username = username
            self.baseURL = baseURL
            self.sdkVersion = sdkVersion
            self.platform = platform
        }
    }

    public struct CacheConfigurationSummary: Sendable, Codable {
        public let categoriesTTL: TimeInterval
        public let streamsTTL: TimeInterval
        public let streamDetailsTTL: TimeInterval
        public let streamURLsTTL: TimeInterval
        public let shortEPGTTL: TimeInterval
        public let fullEPGTTL: TimeInterval
        public let catchupTTL: TimeInterval
        public let diskEnabled: Bool
        public let diskCapacityInBytes: Int
        public let diskDirectory: URL?

        public init(
            categoriesTTL: TimeInterval,
            streamsTTL: TimeInterval,
            streamDetailsTTL: TimeInterval,
            streamURLsTTL: TimeInterval,
            shortEPGTTL: TimeInterval,
            fullEPGTTL: TimeInterval,
            catchupTTL: TimeInterval,
            diskEnabled: Bool,
            diskCapacityInBytes: Int,
            diskDirectory: URL?
        ) {
            self.categoriesTTL = categoriesTTL
            self.streamsTTL = streamsTTL
            self.streamDetailsTTL = streamDetailsTTL
            self.streamURLsTTL = streamURLsTTL
            self.shortEPGTTL = shortEPGTTL
            self.fullEPGTTL = fullEPGTTL
            self.catchupTTL = catchupTTL
            self.diskEnabled = diskEnabled
            self.diskCapacityInBytes = diskCapacityInBytes
            self.diskDirectory = diskDirectory
        }

        public init(configuration: LiveCacheConfiguration) {
            self.init(
                categoriesTTL: configuration.categoriesTTL,
                streamsTTL: configuration.streamsTTL,
                streamDetailsTTL: configuration.streamDetailsTTL,
                streamURLsTTL: configuration.streamURLsTTL,
                shortEPGTTL: configuration.shortEPGTTL,
                fullEPGTTL: configuration.fullEPGTTL,
                catchupTTL: configuration.catchupTTL,
                diskEnabled: configuration.diskOptions.isEnabled,
                diskCapacityInBytes: configuration.diskOptions.capacityInBytes,
                diskDirectory: configuration.diskOptions.directory
            )
        }
    }

    public let metadata: Metadata
    public let context: LiveContext?
    public let diagnostics: XtreamDiagnostics
    public let cacheConfiguration: CacheConfigurationSummary
    public let errorDescription: String?
    public let additionalNotes: [String: String]

    public init(
        domain: MediaIssueDomain,
        metadata: Metadata,
        context: LiveContext?,
        diagnostics: XtreamDiagnostics,
        cacheConfiguration: CacheConfigurationSummary,
        errorDescription: String?,
        additionalNotes: [String: String]
    ) {
        self.domain = domain
        self.metadata = metadata
        self.context = context
        self.diagnostics = diagnostics
        self.cacheConfiguration = cacheConfiguration
        self.errorDescription = errorDescription
        self.additionalNotes = additionalNotes
    }

    public static func platformIdentifier() -> String {
        #if os(tvOS)
            return "tvOS"
        #elseif os(iOS)
            return "iOS"
        #elseif os(macOS)
            return "macOS"
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(Linux)
            return "Linux"
        #else
            return "unknown"
        #endif
    }
}
