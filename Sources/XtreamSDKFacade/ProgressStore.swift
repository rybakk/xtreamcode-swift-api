import Foundation

public struct ContentProgress: Codable, Sendable, Equatable {
    public let contentID: String
    public let position: TimeInterval
    public let duration: TimeInterval
    public let updatedAt: Date

    public init(contentID: String, position: TimeInterval, duration: TimeInterval, updatedAt: Date) {
        self.contentID = contentID
        self.position = position
        self.duration = duration
        self.updatedAt = updatedAt
    }
}

public protocol ProgressStore: Sendable {
    func save(_ progress: ContentProgress) async throws
    func load(contentID: String) async throws -> ContentProgress?
    func clear(contentID: String) async throws
}

public actor UserDefaultsProgressStore: ProgressStore {
    private let userDefaults: UserDefaults
    private let keyPrefix: String
    private let suiteName: String?

    public init(suiteName: String? = nil, keyPrefix: String = "xtreamcode.progress") {
        if let suiteName, let defaults = UserDefaults(suiteName: suiteName) {
            self.userDefaults = defaults
        } else {
            self.userDefaults = .standard
        }
        self.keyPrefix = keyPrefix
        self.suiteName = suiteName
    }

    public func save(_ progress: ContentProgress) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(progress)
        userDefaults.set(data, forKey: storageKey(for: progress.contentID))
    }

    public func load(contentID: String) async throws -> ContentProgress? {
        guard let data = userDefaults.data(forKey: storageKey(for: contentID)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ContentProgress.self, from: data)
    }

    public func clear(contentID: String) async throws {
        userDefaults.removeObject(forKey: storageKey(for: contentID))
    }

    public func removeAll() async throws {
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("\(keyPrefix).") }
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
        if let suiteName {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
    }

    private func storageKey(for contentID: String) -> String {
        "\(keyPrefix).\(contentID)"
    }
}

public final class RemoteProgressStore: ProgressStore {
    public typealias SaveHandler = @Sendable (ContentProgress) async throws -> Void
    public typealias LoadHandler = @Sendable (String) async throws -> ContentProgress?
    public typealias ClearHandler = @Sendable (String) async throws -> Void

    private let saveHandler: SaveHandler
    private let loadHandler: LoadHandler
    private let clearHandler: ClearHandler

    public init(
        saveHandler: @escaping SaveHandler,
        loadHandler: @escaping LoadHandler,
        clearHandler: @escaping ClearHandler
    ) {
        self.saveHandler = saveHandler
        self.loadHandler = loadHandler
        self.clearHandler = clearHandler
    }

    public convenience init(
        saveHandler: @escaping SaveHandler,
        loadHandler: @escaping LoadHandler
    ) {
        self.init(saveHandler: saveHandler, loadHandler: loadHandler, clearHandler: { _ in })
    }

    public func save(_ progress: ContentProgress) async throws {
        try await saveHandler(progress)
    }

    public func load(contentID: String) async throws -> ContentProgress? {
        try await loadHandler(contentID)
    }

    public func clear(contentID: String) async throws {
        try await clearHandler(contentID)
    }
}
