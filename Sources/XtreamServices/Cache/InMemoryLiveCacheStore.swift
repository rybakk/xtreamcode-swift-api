import Foundation

/// In-memory cache relying on `NSCache` with TTL management.
public final class InMemoryLiveCacheStore: LiveCacheStore {
    private final class Entry: NSObject {
        let data: Data
        let expiry: Date?

        init(data: Data, expiry: Date?) {
            self.data = data
            self.expiry = expiry
        }
    }

    private let cache = NSCache<NSString, Entry>()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(
        label: "com.xtreamcode.livecache.memory",
        qos: .userInitiated
    )

    public init(totalCostLimit: Int = 10 * 1024 * 1024) {
        cache.totalCostLimit = totalCostLimit
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        self.encoder = encoder
        self.decoder = decoder
    }

    public func store(
        _ value: some Codable & Sendable,
        for key: LiveCacheKey,
        ttl: TimeInterval?
    ) async {
        guard let ttl else {
            await invalidate(for: key)
            return
        }

        if ttl <= 0 {
            await invalidate(for: key)
            return
        }

        guard let entry = makeEntry(from: value, ttl: ttl) else {
            return
        }

        queue.sync {
            cache.setObject(entry, forKey: cacheKey(for: key), cost: entry.data.count)
        }
    }

    public func value<Value: Codable & Sendable>(
        for key: LiveCacheKey,
        as type: Value.Type
    ) async -> Value? {
        queue.sync {
            guard let entry = cache.object(forKey: cacheKey(for: key)) else {
                return nil
            }

            if let expiry = entry.expiry, expiry < Date() {
                return nil
            }

            return try? decoder.decode(Value.self, from: entry.data)
        }
    }

    public func valueIgnoringExpiry<Value: Codable & Sendable>(
        for key: LiveCacheKey,
        as type: Value.Type
    ) async -> Value? {
        queue.sync {
            guard let entry = cache.object(forKey: cacheKey(for: key)) else {
                return nil
            }
            return try? decoder.decode(Value.self, from: entry.data)
        }
    }

    public func invalidate(for key: LiveCacheKey) async {
        queue.sync {
            cache.removeObject(forKey: cacheKey(for: key))
        }
    }

    public func invalidateAll() async {
        queue.sync {
            cache.removeAllObjects()
        }
    }

    private func cacheKey(for key: LiveCacheKey) -> NSString {
        NSString(string: key.description)
    }

    private func makeEntry(
        from value: some Codable & Sendable,
        ttl: TimeInterval
    ) -> Entry? {
        guard let data = try? encoder.encode(value) else {
            return nil
        }
        let expiry = Date().addingTimeInterval(ttl)
        return Entry(data: data, expiry: expiry)
    }
}

extension InMemoryLiveCacheStore: @unchecked Sendable {}
