import Foundation

final class LockingBox<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self.value = value
    }

    func withLocked<T>(_ body: (inout Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }

    func withValue<T>(_ body: (Value) -> T) -> T {
        lock.lock()
        let current = value
        lock.unlock()
        return body(current)
    }
}
