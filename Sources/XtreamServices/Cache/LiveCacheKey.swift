import Foundation

/// Represents a unique cache key for Live/EPG resources.
public struct LiveCacheKey: Hashable, Sendable, CustomStringConvertible {
    public let components: [String]

    public init(components: [String]) {
        self.components = components.map { $0.replacingOccurrences(of: "::", with: "_") }
    }

    public var description: String {
        components.joined(separator: "::")
    }

    // MARK: - Factory Helpers

    public static func liveCategories(username: String) -> LiveCacheKey {
        LiveCacheKey(components: ["live", "categories", username])
    }

    public static func liveStreams(username: String, categoryID: String?) -> LiveCacheKey {
        LiveCacheKey(components: ["live", "streams", username, categoryID ?? "all"])
    }

    public static func liveStreamDetails(username: String, streamID: Int) -> LiveCacheKey {
        LiveCacheKey(components: ["live", "stream", username, String(streamID)])
    }

    public static func liveStreamURLs(username: String, streamID: Int) -> LiveCacheKey {
        LiveCacheKey(components: ["live", "streamUrls", username, String(streamID)])
    }

    public static func shortEPG(username: String, streamID: Int, limit: Int?) -> LiveCacheKey {
        let limitComponent = limit.map(String.init) ?? "default"
        return LiveCacheKey(components: ["epg", "short", username, String(streamID), limitComponent])
    }

    public static func fullEPG(
        username: String,
        streamID: Int,
        start: Date?,
        end: Date?
    ) -> LiveCacheKey {
        let startComponent = start.flatMap(timestamp) ?? "nil"
        let endComponent = end.flatMap(timestamp) ?? "nil"
        return LiveCacheKey(components: ["epg", "full", username, String(streamID), startComponent, endComponent])
    }

    public static func catchup(
        username: String,
        streamID: Int,
        start: Date?
    ) -> LiveCacheKey {
        let startComponent = start.flatMap(timestamp) ?? "nil"
        return LiveCacheKey(components: ["catchup", username, String(streamID), startComponent])
    }

    public static func vodCategories(username: String) -> LiveCacheKey {
        LiveCacheKey(components: ["vod", "categories", username])
    }

    public static func vodStreams(username: String, categoryID: String?) -> LiveCacheKey {
        LiveCacheKey(components: ["vod", "streams", username, categoryID ?? "all"])
    }

    public static func vodInfo(username: String, vodID: Int) -> LiveCacheKey {
        LiveCacheKey(components: ["vod", "info", username, String(vodID)])
    }

    public static func vodStreamURL(username: String, vodID: Int) -> LiveCacheKey {
        LiveCacheKey(components: ["vod", "streamUrls", username, String(vodID)])
    }

    public static func seriesCategories(username: String) -> LiveCacheKey {
        LiveCacheKey(components: ["series", "categories", username])
    }

    public static func series(username: String, categoryID: String?) -> LiveCacheKey {
        LiveCacheKey(components: ["series", "items", username, categoryID ?? "all"])
    }

    public static func seriesInfo(username: String, seriesID: Int) -> LiveCacheKey {
        LiveCacheKey(components: ["series", "info", username, String(seriesID)])
    }

    public static func seriesEpisodeURL(username: String, seriesID: Int, season: Int, episode: Int) -> LiveCacheKey {
        LiveCacheKey(components: ["series", "episodeUrls", username, String(seriesID), String(season), String(episode)])
    }

    private static func timestamp(from date: Date) -> String {
        String(Int(date.timeIntervalSince1970))
    }
}
