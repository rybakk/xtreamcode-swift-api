// swiftlint:disable large_tuple
import Foundation

/// Disk-backed cache for Live/EPG resources.
public final class DiskLiveCacheStore: LiveCacheStore {
    private struct EntryEnvelope: Codable {
        let expiry: Date?
        let payload: Data
    }

    private let directoryURL: URL
    private let capacityInBytes: Int
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(
        label: "com.xtreamcode.livecache.disk",
        qos: .utility
    )

    public init(
        directory: URL? = nil,
        capacityInBytes: Int = 50 * 1024 * 1024,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.capacityInBytes = capacityInBytes
        let baseDirectory = directory ?? DiskLiveCacheStore.defaultDirectoryURL()
        self.directoryURL = baseDirectory.appendingPathComponent("LiveCache", isDirectory: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        self.encoder = encoder
        self.decoder = decoder

        try? ensureDirectoryExists()
    }

    public func store(
        _ value: some Codable & Sendable,
        for key: LiveCacheKey,
        ttl: TimeInterval?
    ) async {
        guard let ttl, ttl > 0 else {
            await invalidate(for: key)
            return
        }

        queue.sync {
            guard let encodedPayload = try? encoder.encode(value) else {
                return
            }

            let entry = EntryEnvelope(
                expiry: Date().addingTimeInterval(ttl),
                payload: encodedPayload
            )

            guard let data = try? encoder.encode(entry) else {
                return
            }

            let url = fileURL(for: key)
            do {
                try ensureDirectoryExists()
                try data.write(to: url, options: .atomic)
                try fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
                trimIfNeeded()
            } catch {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    public func value<Value: Codable & Sendable>(
        for key: LiveCacheKey,
        as type: Value.Type
    ) async -> Value? {
        queue.sync {
            let url = fileURL(for: key)
            guard fileManager.fileExists(atPath: url.path) else {
                return nil
            }

            guard let data = try? Data(contentsOf: url),
                  let envelope = try? decoder.decode(EntryEnvelope.self, from: data)
            else {
                try? fileManager.removeItem(at: url)
                return nil
            }

            if let expiry = envelope.expiry, expiry < Date() {
                return nil
            }

            guard let value = try? decoder.decode(Value.self, from: envelope.payload) else {
                try? fileManager.removeItem(at: url)
                return nil
            }

            try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
            return value
        }
    }

    public func valueIgnoringExpiry<Value: Codable & Sendable>(
        for key: LiveCacheKey,
        as type: Value.Type
    ) async -> Value? {
        queue.sync {
            let url = fileURL(for: key)
            guard fileManager.fileExists(atPath: url.path) else {
                return nil
            }

            guard let data = try? Data(contentsOf: url),
                  let envelope = try? decoder.decode(EntryEnvelope.self, from: data),
                  let value = try? decoder.decode(Value.self, from: envelope.payload)
            else {
                try? fileManager.removeItem(at: url)
                return nil
            }

            try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
            return value
        }
    }

    public func invalidate(for key: LiveCacheKey) async {
        queue.sync {
            let url = fileURL(for: key)
            try? fileManager.removeItem(at: url)
        }
    }

    public func invalidateAll() async {
        queue.sync {
            guard fileManager.fileExists(atPath: directoryURL.path) else {
                return
            }

            guard let contents = try? fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else {
                return
            }

            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    private func trimIfNeeded() {
        guard capacityInBytes > 0,
              let urls = try? fileManager.contentsOfDirectory(
                  at: directoryURL,
                  includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                  options: [.skipsHiddenFiles]
              )
        else {
            return
        }

        var filesWithSize: [(url: URL, size: Int, modificationDate: Date)] = []
        var totalSize = 0

        for url in urls {
            let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey]
            guard let resourceValues = try? url.resourceValues(forKeys: resourceKeys) else {
                continue
            }

            let size = resourceValues.fileSize ?? 0
            let modificationDate = resourceValues.contentModificationDate ?? Date.distantPast
            totalSize += size
            filesWithSize.append((url, size, modificationDate))
        }

        guard totalSize > capacityInBytes else {
            return
        }

        let sorted = filesWithSize.sorted { lhs, rhs in
            lhs.modificationDate < rhs.modificationDate
        }

        var sizeToFree = totalSize - capacityInBytes
        for file in sorted {
            try? fileManager.removeItem(at: file.url)
            sizeToFree -= file.size
            if sizeToFree <= 0 {
                break
            }
        }
    }

    private func ensureDirectoryExists() throws {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return
            } else {
                try fileManager.removeItem(at: directoryURL)
            }
        }
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    private func fileURL(for key: LiveCacheKey) -> URL {
        directoryURL.appendingPathComponent(filename(for: key), isDirectory: false)
    }

    private func filename(for key: LiveCacheKey) -> String {
        let raw = key.description
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let sanitized = raw.unicodeScalars.map { scalar -> Character in
            if allowed.contains(scalar) {
                return Character(scalar)
            } else {
                return "-"
            }
        }
        return String(sanitized) + ".json"
    }

    private static func defaultDirectoryURL() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return caches ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }
}

// swiftlint:enable large_tuple

extension DiskLiveCacheStore: @unchecked Sendable {}
