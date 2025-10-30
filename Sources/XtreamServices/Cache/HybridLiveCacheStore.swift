import Foundation

/// Combines in-memory and disk caches.
public final class HybridLiveCacheStore: LiveCacheStore {
    private let memoryStore: InMemoryLiveCacheStore
    private let diskStore: DiskLiveCacheStore?
    private let ttlProvider: (LiveCacheKey) -> TimeInterval?

    public init(
        memoryStore: InMemoryLiveCacheStore = InMemoryLiveCacheStore(),
        diskStore: DiskLiveCacheStore? = nil,
        ttlProvider: @escaping (LiveCacheKey) -> TimeInterval? = { _ in nil }
    ) {
        self.memoryStore = memoryStore
        self.diskStore = diskStore
        self.ttlProvider = ttlProvider
    }

    public func store(
        _ value: some Codable & Sendable,
        for key: LiveCacheKey,
        ttl: TimeInterval?
    ) async {
        await memoryStore.store(value, for: key, ttl: ttl)
        if let diskStore {
            await diskStore.store(value, for: key, ttl: ttl)
        }
    }

    public func value<Value: Codable & Sendable>(
        for key: LiveCacheKey,
        as type: Value.Type
    ) async -> Value? {
        if let cached: Value = await memoryStore.value(for: key, as: type) {
            return cached
        }

        guard let diskStore,
              let cached: Value = await diskStore.value(for: key, as: type)
        else {
            return nil
        }

        let ttl = ttlProvider(key)
        if let ttl, ttl > 0 {
            await memoryStore.store(cached, for: key, ttl: ttl)
        }

        return cached
    }

    public func valueIgnoringExpiry<Value: Codable & Sendable>(
        for key: LiveCacheKey,
        as type: Value.Type
    ) async -> Value? {
        if let cached: Value = await memoryStore.valueIgnoringExpiry(for: key, as: type) {
            return cached
        }

        guard let diskStore,
              let cached: Value = await diskStore.valueIgnoringExpiry(for: key, as: type)
        else {
            return nil
        }

        return cached
    }

    public func invalidate(for key: LiveCacheKey) async {
        await memoryStore.invalidate(for: key)
        if let diskStore {
            await diskStore.invalidate(for: key)
        }
    }

    public func invalidateAll() async {
        await memoryStore.invalidateAll()
        if let diskStore {
            await diskStore.invalidateAll()
        }
    }
}

extension HybridLiveCacheStore: @unchecked Sendable {}
