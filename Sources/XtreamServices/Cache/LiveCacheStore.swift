import Foundation

/// Abstraction for live/EPG caching.
public protocol LiveCacheStore: AnyObject, Sendable {
    func store(
        _ value: some Codable & Sendable,
        for key: LiveCacheKey,
        ttl: TimeInterval?
    ) async

    func value<Value: Codable & Sendable>(
        for key: LiveCacheKey,
        as type: Value.Type
    ) async -> Value?

    func valueIgnoringExpiry<Value: Codable & Sendable>(
        for key: LiveCacheKey,
        as type: Value.Type
    ) async -> Value?

    func invalidate(for key: LiveCacheKey) async
    func invalidateAll() async
}
