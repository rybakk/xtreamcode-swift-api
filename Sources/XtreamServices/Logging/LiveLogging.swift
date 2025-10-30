import Foundation

public enum LiveCacheSource: String, Sendable {
    case memoryOrDisk
    case fallback
}

public enum LiveLogEvent: Sendable {
    case requestStarted(endpoint: String)
    case requestSucceeded(endpoint: String, duration: TimeInterval)
    case requestFailed(endpoint: String, error: Error)
    case cacheHit(key: LiveCacheKey, source: LiveCacheSource)
    case cacheMiss(key: LiveCacheKey)
    case offlineFallback(key: LiveCacheKey)
}

public struct LiveContext: Sendable, Codable {
    public let endpoint: String?
    public let streamID: Int?
    public let categoryID: String?
    public let vodID: Int?
    public let seriesID: Int?
    public let episodeNumber: Int?
    public let searchQuery: String?
    public let searchType: XtreamSearchType?

    public init(
        endpoint: String? = nil,
        streamID: Int? = nil,
        categoryID: String? = nil,
        vodID: Int? = nil,
        seriesID: Int? = nil,
        episodeNumber: Int? = nil,
        searchQuery: String? = nil,
        searchType: XtreamSearchType? = nil
    ) {
        self.endpoint = endpoint
        self.streamID = streamID
        self.categoryID = categoryID
        self.vodID = vodID
        self.seriesID = seriesID
        self.episodeNumber = episodeNumber
        self.searchQuery = searchQuery
        self.searchType = searchType
    }
}

public protocol LiveLogger: Sendable {
    func event(_ event: LiveLogEvent)
    func error(_ error: Error, context: LiveContext?)
}

public struct DefaultLiveLogger: LiveLogger {
    public init() {}

    public func event(_ event: LiveLogEvent) {
        #if DEBUG
            print("[LiveLogger] event: \(event)")
        #endif
    }

    public func error(_ error: Error, context: LiveContext?) {
        #if DEBUG
            print("[LiveLogger] error: \(error) context: \(String(describing: context))")
        #endif
    }
}
