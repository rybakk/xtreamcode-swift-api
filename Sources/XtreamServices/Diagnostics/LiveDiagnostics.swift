import Foundation

public struct XtreamDiagnostics: Sendable, Codable {
    public let liveCacheHits: Int
    public let liveCacheMisses: Int
    public let offlineFallbacks: Int
    public let lastForceRefresh: Date?

    public init(
        liveCacheHits: Int,
        liveCacheMisses: Int,
        offlineFallbacks: Int,
        lastForceRefresh: Date?
    ) {
        self.liveCacheHits = liveCacheHits
        self.liveCacheMisses = liveCacheMisses
        self.offlineFallbacks = offlineFallbacks
        self.lastForceRefresh = lastForceRefresh
    }
}

public protocol LiveDiagnosticsRecording: AnyObject, Sendable {
    func recordCacheHit(for key: LiveCacheKey) async
    func recordCacheMiss(for key: LiveCacheKey) async
    func recordOfflineFallback(for key: LiveCacheKey) async
    func recordForceRefresh(for key: LiveCacheKey) async
    func snapshot() async -> XtreamDiagnostics
    func reset() async
}

public actor LiveDiagnosticsTracker: LiveDiagnosticsRecording {
    private var liveCacheHits = 0
    private var liveCacheMisses = 0
    private var offlineFallbacks = 0
    private var lastForceRefresh: Date?

    public init() {}

    public func recordCacheHit(for _: LiveCacheKey) {
        liveCacheHits += 1
    }

    public func recordCacheMiss(for _: LiveCacheKey) {
        liveCacheMisses += 1
    }

    public func recordOfflineFallback(for _: LiveCacheKey) {
        offlineFallbacks += 1
    }

    public func recordForceRefresh(for _: LiveCacheKey) {
        lastForceRefresh = Date()
    }

    public func snapshot() async -> XtreamDiagnostics {
        XtreamDiagnostics(
            liveCacheHits: liveCacheHits,
            liveCacheMisses: liveCacheMisses,
            offlineFallbacks: offlineFallbacks,
            lastForceRefresh: lastForceRefresh
        )
    }

    public func reset() {
        liveCacheHits = 0
        liveCacheMisses = 0
        offlineFallbacks = 0
        lastForceRefresh = nil
    }
}
