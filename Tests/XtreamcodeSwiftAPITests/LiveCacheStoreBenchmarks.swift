import Foundation
import XCTest
@testable import XtreamModels
@testable import XtreamServices

final class LiveCacheStoreBenchmarks: XCTestCase {
    private let sampleCategories: [XtreamLiveCategory] = (0 ..< 50).map {
        XtreamLiveCategory(id: "\($0)", name: "Category \($0)", parentID: nil)
    }

    func testInMemoryCacheHitPerformance() {
        let cache = InMemoryLiveCacheStore()
        let key = LiveCacheKey.liveCategories(username: "benchmark")
        let payload = sampleCategories

        blocking {
            await cache.store(payload, for: key, ttl: 3600)
        }

        measure(metrics: [XCTClockMetric()]) {
            _ = blocking {
                await cache.value(for: key, as: [XtreamLiveCategory].self)
            }
        }
    }

    func testInMemoryCacheMissPerformance() {
        let cache = InMemoryLiveCacheStore()
        let key = LiveCacheKey.liveCategories(username: "benchmark-miss")

        measure(metrics: [XCTClockMetric()]) {
            _ = blocking {
                await cache.value(for: key, as: [XtreamLiveCategory].self)
            }
        }
    }
}

@discardableResult
private func blocking<Value: Sendable>(_ operation: @escaping @Sendable () async -> Value) -> Value {
    let semaphore = DispatchSemaphore(value: 0)
    var result: Value!
    Task.detached {
        result = await operation()
        semaphore.signal()
    }
    semaphore.wait()
    return result
}
