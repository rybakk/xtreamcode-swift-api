// swiftlint:disable:next superfluous_disable_command
// swiftlint:disable file_length
import Alamofire
import Foundation
#if canImport(XtreamClient)
@_exported import XtreamClient
#endif
#if canImport(XtreamModels)
@_exported import XtreamModels
#endif
#if canImport(XtreamServices)
@_exported import XtreamServices
#endif
#if canImport(Combine)
    import Combine
#endif

private final class ResultDispatcher<Value>: @unchecked Sendable {
    private let handler: (Result<Value, Error>) -> Void

    init(_ handler: @escaping (Result<Value, Error>) -> Void) {
        self.handler = handler
    }

    func resolve(_ result: Result<Value, Error>) {
        handler(result)
    }
}

/// Public entry point exposed to integrators. Manages the core services and caches authentication state.
// swiftlint:disable:next type_body_length
public final class XtreamcodeSwiftAPI: @unchecked Sendable {
    public struct Configuration {
        public var baseURL: URL
        public var credentials: XtreamCredentials
        public var session: Session
        public var defaultHeaders: [String: String]
        public var liveCacheConfiguration: LiveCacheConfiguration
        public var liveCacheStore: LiveCacheStore?
        public var logger: LiveLogger?
        public var progressStore: ProgressStore?

        public init(
            baseURL: URL,
            credentials: XtreamCredentials,
            session: Session = .default,
            defaultHeaders: [String: String] = [:],
            liveCacheConfiguration: LiveCacheConfiguration = LiveCacheConfiguration(),
            liveCacheStore: LiveCacheStore? = nil,
            logger: LiveLogger? = nil,
            progressStore: ProgressStore? = nil
        ) {
            self.baseURL = baseURL
            self.credentials = credentials
            self.session = session
            self.defaultHeaders = defaultHeaders
            self.liveCacheConfiguration = liveCacheConfiguration
            self.liveCacheStore = liveCacheStore
            self.logger = logger
            self.progressStore = progressStore
        }
    }

    private let serviceRegistry: XtreamServiceRegistry
    private let authService: XtreamAuthService
    private let accountService: XtreamAccountService
    private let liveService: XtreamLiveService
    private let epgService: XtreamEPGService
    private let vodService: XtreamVODService
    private let seriesService: XtreamSeriesService
    private let searchService: XtreamSearchService
    private let baseURL: URL
    private let liveCacheStore: LiveCacheStore?
    private let liveCacheConfiguration: LiveCacheConfiguration
    private let logger: LiveLogger
    private let diagnosticsTracker = LiveDiagnosticsTracker()
    private let progressStore: ProgressStore?

    private let stateLock = NSLock()
    private var credentials: XtreamCredentials
    private var cachedSession: XtreamAuthSession?
    private var cachedAccountDetails: XtreamAccountDetails?

    public convenience init(
        baseURL: URL,
        credentials: XtreamCredentials,
        session: Session = .default,
        defaultHeaders: [String: String] = [:],
        liveCacheConfiguration: LiveCacheConfiguration = LiveCacheConfiguration(),
        liveCacheStore: LiveCacheStore? = nil,
        logger: LiveLogger? = nil,
        progressStore: ProgressStore? = nil
    ) {
        let configuration = Configuration(
            baseURL: baseURL,
            credentials: credentials,
            session: session,
            defaultHeaders: defaultHeaders,
            liveCacheConfiguration: liveCacheConfiguration,
            liveCacheStore: liveCacheStore,
            logger: logger,
            progressStore: progressStore
        )
        self.init(configuration: configuration)
    }

    public init(configuration: Configuration) {
        let clientConfiguration = XtreamClient.Configuration(
            baseURL: configuration.baseURL,
            session: configuration.session,
            defaultHeaders: configuration.defaultHeaders
        )
        let client = XtreamClient(configuration: clientConfiguration)

        let liveCacheStore = XtreamcodeSwiftAPI.makeLiveCacheStore(
            configuration: configuration.liveCacheConfiguration,
            customStore: configuration.liveCacheStore
        )
        let effectiveLogger = configuration.logger ?? DefaultLiveLogger()
        let registry = XtreamServiceRegistry(
            client: client,
            liveCacheStore: liveCacheStore,
            liveCacheConfiguration: configuration.liveCacheConfiguration,
            logger: effectiveLogger,
            diagnostics: diagnosticsTracker
        )

        self.serviceRegistry = registry
        self.authService = registry.makeAuthService()
        self.accountService = registry.makeAccountService()
        self.liveService = registry.makeLiveService()
        self.epgService = registry.makeEPGService()
        self.vodService = registry.makeVODService()
        self.seriesService = registry.makeSeriesService()
        self.searchService = registry.makeSearchService()
        self.baseURL = configuration.baseURL
        self.liveCacheStore = liveCacheStore
        self.liveCacheConfiguration = configuration.liveCacheConfiguration
        self.logger = effectiveLogger
        self.credentials = configuration.credentials
        self.progressStore = configuration.progressStore
    }

    private static func makeLiveCacheStore(
        configuration: LiveCacheConfiguration,
        customStore: LiveCacheStore?
    ) -> LiveCacheStore? {
        if let customStore {
            return customStore
        }

        let memoryStore = InMemoryLiveCacheStore()
        let diskStore: DiskLiveCacheStore? = configuration.diskOptions.isEnabled
            ? DiskLiveCacheStore(
                directory: configuration.diskOptions.directory,
                capacityInBytes: configuration.diskOptions.capacityInBytes
            )
            : nil

        return HybridLiveCacheStore(
            memoryStore: memoryStore,
            diskStore: diskStore,
            ttlProvider: { configuration.ttl(for: $0) }
        )
    }

    // MARK: - Helpers

    private func withStateLock<T>(_ body: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body()
    }

    private func credentialsSnapshot() -> XtreamCredentials {
        withStateLock { credentials }
    }

    private func cache(session: XtreamAuthSession?) {
        withStateLock {
            cachedSession = session
            if session == nil {
                cachedAccountDetails = nil
            }
        }
    }

    private func cache(accountDetails: XtreamAccountDetails) {
        withStateLock {
            cachedAccountDetails = accountDetails
            cachedSession = accountDetails.session
        }
    }

    private func invalidateLiveCache(for key: LiveCacheKey) async {
        guard let liveCacheStore else { return }
        await liveCacheStore.invalidate(for: key)
    }

    private func cachedValue<Value: Codable & Sendable>(
        for key: LiveCacheKey,
        ignoringExpiry: Bool = false
    ) async -> Value? {
        guard let liveCacheStore else { return nil }
        if ignoringExpiry {
            return await liveCacheStore.valueIgnoringExpiry(for: key, as: Value.self)
        }
        return await liveCacheStore.value(for: key, as: Value.self)
    }

    private func restoreFallback(
        _ value: some Codable & Sendable,
        for key: LiveCacheKey
    ) async {
        guard let liveCacheStore else { return }
        guard let ttl = liveCacheConfiguration.ttl(for: key), ttl > 0 else { return }
        await liveCacheStore.store(value, for: key, ttl: ttl)
    }

    private func sdkVersionIdentifier() -> String? {
        let bundle = Bundle(for: XtreamcodeSwiftAPI.self)
        if let shortVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            return shortVersion
        }
        if let buildVersion = bundle.infoDictionary?["CFBundleVersion"] as? String {
            return buildVersion
        }
        if let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return shortVersion
        }
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }

    private func isOfflineError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
                return true
            default:
                return false
            }
        }

        if let afError = error as? AFError {
            if let underlying = afError.underlyingError {
                return isOfflineError(underlying)
            }
            return false
        }

        if let xtreamError = error as? XtreamError {
            if case let .network(underlying) = xtreamError {
                return isOfflineError(underlying)
            }
        }

        if let clientError = error as? XtreamClientError {
            if case let .network(underlying) = clientError {
                return isOfflineError(underlying)
            }
        }

        return false
    }

    public func diagnosticsSnapshot() async -> XtreamDiagnostics {
        await diagnosticsTracker.snapshot()
    }

    public func resetDiagnostics() async {
        await diagnosticsTracker.reset()
    }

    @available(*, deprecated, message: "Use makeMediaIssueReport(domain:context:error:additionalNotes:) instead")
    public func makeLiveIssueReport(
        context: LiveContext? = nil,
        error: Error? = nil,
        additionalNotes: [String: String] = [:]
    ) async -> LiveIssueReport {
        await makeMediaIssueReport(domain: .live, context: context, error: error, additionalNotes: additionalNotes)
    }

    public func makeMediaIssueReport(
        domain: MediaIssueDomain,
        context: LiveContext? = nil,
        error: Error? = nil,
        additionalNotes: [String: String] = [:]
    ) async -> LiveIssueReport {
        let diagnostics = await diagnosticsSnapshot()
        let metadata = LiveIssueReport.Metadata(
            generatedAt: Date(),
            username: credentialsSnapshot().username,
            baseURL: baseURL,
            sdkVersion: sdkVersionIdentifier(),
            platform: LiveIssueReport.platformIdentifier()
        )
        return LiveIssueReport(
            domain: domain,
            metadata: metadata,
            context: context,
            diagnostics: diagnostics,
            cacheConfiguration: .init(configuration: liveCacheConfiguration),
            errorDescription: error.map { String(describing: $0) },
            additionalNotes: additionalNotes
        )
    }

    // MARK: - Cache Management

    public func invalidateLiveCache() async {
        guard let liveCacheStore else { return }
        await liveCacheStore.invalidateAll()
    }

    public func invalidateMediaCache() async {
        await invalidateLiveCache()
    }

    // MARK: - Credentials Management

    public func updateCredentials(_ newCredentials: XtreamCredentials) {
        withStateLock {
            credentials = newCredentials
            cachedSession = nil
            cachedAccountDetails = nil
        }
        if let store = liveCacheStore {
            Task { [weak store] in
                await store?.invalidateAll()
            }
        }
    }

    // MARK: - Session

    public var currentSession: XtreamAuthSession? {
        withStateLock { cachedSession }
    }

    @discardableResult
    public func authenticate(forceRefresh: Bool = false) async throws -> XtreamAuthSession {
        if !forceRefresh, let session = currentSession {
            return session
        }

        let response = try await authService.login(credentials: credentialsSnapshot())
        cache(session: response)
        return response
    }

    @discardableResult
    public func refreshSession() async throws -> XtreamAuthSession {
        let response = try await authService.refreshSession(credentials: credentialsSnapshot())
        cache(session: response)
        await invalidateLiveCache()
        return response
    }

    public func logout() {
        authService.logout()
        cache(session: nil)
        if let store = liveCacheStore {
            Task { [weak store] in
                await store?.invalidateAll()
            }
        }
    }

    // MARK: - Account

    public func fetchAccountDetails(forceRefresh: Bool = false) async throws -> XtreamAccountDetails {
        if !forceRefresh, let details = withStateLock({ cachedAccountDetails }) {
            return details
        }

        let details = try await accountService.fetchAccountDetails(credentials: credentialsSnapshot())
        cache(accountDetails: details)
        return details
    }

    // MARK: - Live TV & EPG

    public func liveCategories(forceRefresh: Bool = false) async throws -> [XtreamLiveCategory] {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.liveCategories(username: credentials.username)
        let fallback: [XtreamLiveCategory]? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await liveService.fetchCategories(credentials: credentials)
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func liveStreams(
        in categoryID: String? = nil,
        forceRefresh: Bool = false
    ) async throws -> [XtreamLiveStream] {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.liveStreams(username: credentials.username, categoryID: categoryID)
        let fallback: [XtreamLiveStream]? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await liveService.fetchStreams(
                credentials: credentials,
                categoryID: categoryID
            )
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func liveStream(
        by streamID: Int,
        forceRefresh: Bool = false
    ) async throws -> XtreamLiveStream? {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.liveStreamDetails(username: credentials.username, streamID: streamID)
        let fallback: XtreamLiveStream? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await liveService.fetchStreamDetails(
                credentials: credentials,
                streamID: streamID
            )
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func liveStreamURLs(
        for streamID: Int,
        forceRefresh: Bool = false
    ) async throws -> [XtreamLiveStreamURL] {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.liveStreamURLs(username: credentials.username, streamID: streamID)
        let fallback: [XtreamLiveStreamURL]? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await liveService.fetchStreamURLs(
                credentials: credentials,
                streamID: streamID
            )
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func liveStreamURL(
        for streamID: Int,
        quality: String? = nil,
        forceRefresh: Bool = false
    ) async throws -> URL? {
        let urls = try await liveStreamURLs(for: streamID, forceRefresh: forceRefresh)
        guard let quality else {
            return urls.first?.url
        }

        let matched = urls.first {
            guard let candidateQuality = $0.quality else { return false }
            return candidateQuality.caseInsensitiveCompare(quality) == .orderedSame
        }

        return (matched ?? urls.first)?.url
    }

    public func epg(
        for streamID: Int,
        limit: Int? = nil,
        forceRefresh: Bool = false
    ) async throws -> [XtreamEPGEntry] {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.shortEPG(username: credentials.username, streamID: streamID, limit: limit)
        let fallback: [XtreamEPGEntry]? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await epgService.fetchShortEPG(
                credentials: credentials,
                streamID: streamID,
                limit: limit
            )
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func epg(
        for streamID: Int,
        start: Date?,
        end: Date?,
        forceRefresh: Bool = false
    ) async throws -> [XtreamEPGEntry] {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.fullEPG(
            username: credentials.username,
            streamID: streamID,
            start: start,
            end: end
        )
        let fallback: [XtreamEPGEntry]? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await epgService.fetchEPG(
                credentials: credentials,
                streamID: streamID,
                start: start,
                end: end
            )
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func catchup(
        for streamID: Int,
        start: Date? = nil,
        forceRefresh: Bool = false
    ) async throws -> XtreamCatchupCollection? {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.catchup(username: credentials.username, streamID: streamID, start: start)
        let fallback: XtreamCatchupCollection? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await epgService.fetchCatchup(
                credentials: credentials,
                streamID: streamID,
                start: start
            )
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    /// Fetches the full EPG in XMLTV format.
    /// - Returns: Raw XML data that can be parsed using an XML parser.
    public func xmltvEPG() async throws -> Data {
        let credentials = credentialsSnapshot()
        return try await epgService.fetchXMLTVEPG(credentials: credentials)
    }

    // MARK: - VOD

    public func vodCategories(forceRefresh: Bool = false) async throws -> [XtreamVODCategory] {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.vodCategories(username: credentials.username)
        let fallback: [XtreamVODCategory]? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await vodService.fetchCategories(credentials: credentials)
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func vodStreams(
        in categoryID: String? = nil,
        forceRefresh: Bool = false
    ) async throws -> [XtreamVODStream] {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.vodStreams(username: credentials.username, categoryID: categoryID)
        let fallback: [XtreamVODStream]? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await vodService.fetchStreams(
                credentials: credentials,
                categoryID: categoryID
            )
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func vodDetails(
        for vodID: Int,
        forceRefresh: Bool = false
    ) async throws -> XtreamVODInfo {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.vodInfo(username: credentials.username, vodID: vodID)
        let fallback: XtreamVODInfo? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await vodService.fetchDetails(
                credentials: credentials,
                vodID: vodID
            )
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func vodStreamURL(
        for vodID: Int,
        forceRefresh: Bool = false
    ) async throws -> URL {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.vodStreamURL(username: credentials.username, vodID: vodID)
        let fallback: URL? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : await cachedValue(for: cacheKey)

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            let url = try await vodService.fetchStreamURL(
                credentials: credentials,
                vodID: vodID
            )
            if let liveCacheStore,
               let ttl = liveCacheConfiguration.ttl(for: cacheKey), ttl > 0 {
                await liveCacheStore.store(url, for: cacheKey, ttl: ttl)
            }
            return url
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    // MARK: - Series

    public func seriesCategories(forceRefresh: Bool = false) async throws -> [XtreamSeriesCategory] {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.seriesCategories(username: credentials.username)
        let fallback: [XtreamSeriesCategory]? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await seriesService.fetchCategories(credentials: credentials)
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func seriesEpisodeURL(
        for seriesID: Int,
        season: Int,
        episode: Int,
        forceRefresh: Bool = false
    ) async throws -> URL {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.seriesEpisodeURL(
            username: credentials.username,
            seriesID: seriesID,
            season: season,
            episode: episode
        )
        let fallback: URL? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : await cachedValue(for: cacheKey)

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            let url = try await seriesService.fetchEpisodeURL(
                credentials: credentials,
                seriesID: seriesID,
                season: season,
                episode: episode
            )
            if let liveCacheStore,
               let ttl = liveCacheConfiguration.ttl(for: cacheKey), ttl > 0 {
                await liveCacheStore.store(url, for: cacheKey, ttl: ttl)
            }
            return url
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func series(
        in categoryID: String? = nil,
        forceRefresh: Bool = false
    ) async throws -> [XtreamSeries] {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.series(username: credentials.username, categoryID: categoryID)
        let fallback: [XtreamSeries]? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await seriesService.fetchSeries(
                credentials: credentials,
                categoryID: categoryID
            )
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    public func seriesDetails(
        for seriesID: Int,
        forceRefresh: Bool = false
    ) async throws -> XtreamSeriesInfo {
        let credentials = credentialsSnapshot()
        let cacheKey = LiveCacheKey.seriesInfo(username: credentials.username, seriesID: seriesID)
        let fallback: XtreamSeriesInfo? = forceRefresh
            ? await cachedValue(for: cacheKey, ignoringExpiry: true)
            : nil

        if forceRefresh {
            await diagnosticsTracker.recordForceRefresh(for: cacheKey)
            await invalidateLiveCache(for: cacheKey)
        }

        do {
            return try await seriesService.fetchDetails(
                credentials: credentials,
                seriesID: seriesID
            )
        } catch {
            if forceRefresh, let fallback, isOfflineError(error) {
                logger.event(.offlineFallback(key: cacheKey))
                await diagnosticsTracker.recordOfflineFallback(for: cacheKey)
                await restoreFallback(fallback, for: cacheKey)
                return fallback
            }
            throw error
        }
    }

    // MARK: - Search

    public func search(
        query: String,
        type: XtreamSearchType = .all
    ) async throws -> [XtreamSearchResult] {
        let credentials = credentialsSnapshot()
        return try await searchService.search(
            credentials: credentials,
            query: query,
            type: type
        )
    }

    // MARK: - Progress Tracking

    @discardableResult
    public func saveProgress(
        contentID: String,
        position: TimeInterval,
        duration: TimeInterval
    ) async throws -> ContentProgress {
        guard let progressStore else {
            throw XtreamError.unsupported
        }
        guard position >= 0, duration >= 0 else {
            throw XtreamError.unsupported
        }

        let sanitizedDuration = duration == 0 ? max(position, 0) : duration
        let normalizedDuration = max(sanitizedDuration, 0)
        let normalizedPosition = min(max(position, 0), normalizedDuration == 0 ? max(position, 0) : normalizedDuration)
        let progress = ContentProgress(
            contentID: contentID,
            position: normalizedPosition,
            duration: normalizedDuration,
            updatedAt: Date()
        )
        try await progressStore.save(progress)
        return progress
    }

    public func loadProgress(contentID: String) async throws -> ContentProgress? {
        guard let progressStore else {
            throw XtreamError.unsupported
        }
        return try await progressStore.load(contentID: contentID)
    }

    public func clearProgress(contentID: String) async throws {
        guard let progressStore else {
            throw XtreamError.unsupported
        }
        try await progressStore.clear(contentID: contentID)
    }

    // MARK: - Closure Adaptors

    @discardableResult
    public func liveCategories(
        forceRefresh: Bool = false,
        completion: @escaping (Result<[XtreamLiveCategory], Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await liveCategories(forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func liveStreams(
        in categoryID: String? = nil,
        forceRefresh: Bool = false,
        completion: @escaping (Result<[XtreamLiveStream], Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await liveStreams(in: categoryID, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func liveStreamURL(
        for streamID: Int,
        quality: String? = nil,
        forceRefresh: Bool = false,
        completion: @escaping (Result<URL?, Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await liveStreamURL(for: streamID, quality: quality, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func epg(
        for streamID: Int,
        limit: Int? = nil,
        forceRefresh: Bool = false,
        completion: @escaping (Result<[XtreamEPGEntry], Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await epg(for: streamID, limit: limit, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func epg(
        for streamID: Int,
        start: Date?,
        end: Date?,
        forceRefresh: Bool = false,
        completion: @escaping (Result<[XtreamEPGEntry], Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await epg(for: streamID, start: start, end: end, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func catchup(
        for streamID: Int,
        start: Date? = nil,
        forceRefresh: Bool = false,
        completion: @escaping (Result<XtreamCatchupCollection?, Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await catchup(for: streamID, start: start, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func xmltvEPG(
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await xmltvEPG()
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func vodCategories(
        forceRefresh: Bool = false,
        completion: @escaping (Result<[XtreamVODCategory], Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await vodCategories(forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func vodStreams(
        in categoryID: String? = nil,
        forceRefresh: Bool = false,
        completion: @escaping (Result<[XtreamVODStream], Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await vodStreams(in: categoryID, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func vodDetails(
        for vodID: Int,
        forceRefresh: Bool = false,
        completion: @escaping (Result<XtreamVODInfo, Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await vodDetails(for: vodID, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func vodStreamURL(
        for vodID: Int,
        forceRefresh: Bool = false,
        completion: @escaping (Result<URL, Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await vodStreamURL(for: vodID, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func seriesCategories(
        forceRefresh: Bool = false,
        completion: @escaping (Result<[XtreamSeriesCategory], Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await seriesCategories(forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func series(
        in categoryID: String? = nil,
        forceRefresh: Bool = false,
        completion: @escaping (Result<[XtreamSeries], Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await series(in: categoryID, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func seriesDetails(
        for seriesID: Int,
        forceRefresh: Bool = false,
        completion: @escaping (Result<XtreamSeriesInfo, Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await seriesDetails(for: seriesID, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func seriesEpisodeURL(
        for seriesID: Int,
        season: Int,
        episode: Int,
        forceRefresh: Bool = false,
        completion: @escaping (Result<URL, Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await seriesEpisodeURL(for: seriesID, season: season, episode: episode, forceRefresh: forceRefresh)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }

    @discardableResult
    public func search(
        query: String,
        type: XtreamSearchType = .all,
        completion: @escaping (Result<[XtreamSearchResult], Error>) -> Void
    ) -> Task<Void, Never> {
        let dispatcher = ResultDispatcher(completion)

        return Task { [weak self] in
            guard let self else {
                dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                return
            }
            do {
                let value = try await search(query: query, type: type)
                dispatcher.resolve(.success(value))
            } catch {
                dispatcher.resolve(.failure(error))
            }
        }
    }
}

#if canImport(Combine)
    public extension XtreamcodeSwiftAPI {
        func liveCategoriesPublisher(
            forceRefresh: Bool = false
        ) -> AnyPublisher<[XtreamLiveCategory], Error> {
            publisher { api in
                try await api.liveCategories(forceRefresh: forceRefresh)
            }
        }

        func liveStreamsPublisher(
            in categoryID: String? = nil,
            forceRefresh: Bool = false
        ) -> AnyPublisher<[XtreamLiveStream], Error> {
            publisher { api in
                try await api.liveStreams(in: categoryID, forceRefresh: forceRefresh)
            }
        }

        func liveStreamURLPublisher(
            for streamID: Int,
            quality: String? = nil,
            forceRefresh: Bool = false
        ) -> AnyPublisher<URL?, Error> {
            publisher { api in
                try await api.liveStreamURL(for: streamID, quality: quality, forceRefresh: forceRefresh)
            }
        }

        func epgPublisher(
            for streamID: Int,
            limit: Int? = nil,
            forceRefresh: Bool = false
        ) -> AnyPublisher<[XtreamEPGEntry], Error> {
            publisher { api in
                try await api.epg(for: streamID, limit: limit, forceRefresh: forceRefresh)
            }
        }

        func epgPublisher(
            for streamID: Int,
            start: Date?,
            end: Date?,
            forceRefresh: Bool = false
        ) -> AnyPublisher<[XtreamEPGEntry], Error> {
            publisher { api in
                try await api.epg(for: streamID, start: start, end: end, forceRefresh: forceRefresh)
            }
        }

        func catchupPublisher(
            for streamID: Int,
            start: Date? = nil,
            forceRefresh: Bool = false
        ) -> AnyPublisher<XtreamCatchupCollection?, Error> {
            publisher { api in
                try await api.catchup(for: streamID, start: start, forceRefresh: forceRefresh)
            }
        }

        func xmltvEPGPublisher() -> AnyPublisher<Data, Error> {
            publisher { api in
                try await api.xmltvEPG()
            }
        }

        func vodCategoriesPublisher(
            forceRefresh: Bool = false
        ) -> AnyPublisher<[XtreamVODCategory], Error> {
            publisher { api in
                try await api.vodCategories(forceRefresh: forceRefresh)
            }
        }

        func vodStreamsPublisher(
            in categoryID: String? = nil,
            forceRefresh: Bool = false
        ) -> AnyPublisher<[XtreamVODStream], Error> {
            publisher { api in
                try await api.vodStreams(in: categoryID, forceRefresh: forceRefresh)
            }
        }

        func vodDetailsPublisher(
            for vodID: Int,
            forceRefresh: Bool = false
        ) -> AnyPublisher<XtreamVODInfo, Error> {
            publisher { api in
                try await api.vodDetails(for: vodID, forceRefresh: forceRefresh)
            }
        }

        func vodStreamURLPublisher(
            for vodID: Int,
            forceRefresh: Bool = false
        ) -> AnyPublisher<URL, Error> {
            publisher { api in
                try await api.vodStreamURL(for: vodID, forceRefresh: forceRefresh)
            }
        }

        func seriesCategoriesPublisher(
            forceRefresh: Bool = false
        ) -> AnyPublisher<[XtreamSeriesCategory], Error> {
            publisher { api in
                try await api.seriesCategories(forceRefresh: forceRefresh)
            }
        }

        func seriesPublisher(
            in categoryID: String? = nil,
            forceRefresh: Bool = false
        ) -> AnyPublisher<[XtreamSeries], Error> {
            publisher { api in
                try await api.series(in: categoryID, forceRefresh: forceRefresh)
            }
        }

        func seriesDetailsPublisher(
            for seriesID: Int,
            forceRefresh: Bool = false
        ) -> AnyPublisher<XtreamSeriesInfo, Error> {
            publisher { api in
                try await api.seriesDetails(for: seriesID, forceRefresh: forceRefresh)
            }
        }

        func seriesEpisodeURLPublisher(
            for seriesID: Int,
            season: Int,
            episode: Int,
            forceRefresh: Bool = false
        ) -> AnyPublisher<URL, Error> {
            publisher { api in
                try await api.seriesEpisodeURL(for: seriesID, season: season, episode: episode, forceRefresh: forceRefresh)
            }
        }

        func searchPublisher(
            query: String,
            type: XtreamSearchType = .all
        ) -> AnyPublisher<[XtreamSearchResult], Error> {
            publisher { api in
                try await api.search(query: query, type: type)
            }
        }

        private func publisher<Output>(
            _ operation: @Sendable @escaping (XtreamcodeSwiftAPI) async throws -> Output
        ) -> AnyPublisher<Output, Error> {
            Deferred { () -> AnyPublisher<Output, Error> in
                var task: Task<Void, Never>?
                let future = Future<Output, Error> { [weak self] promise in
                    let dispatcher = ResultDispatcher(promise)

                    guard let self else {
                        dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                        return
                    }

                    task = Task { [weak self] in
                        guard let self else {
                            dispatcher.resolve(.failure(XtreamError.unknown(underlying: CancellationError())))
                            return
                        }
                        do {
                            let value = try await operation(self)
                            dispatcher.resolve(.success(value))
                        } catch {
                            dispatcher.resolve(.failure(error))
                        }
                    }
                }

                return future
                    .handleEvents(receiveCancel: { task?.cancel() })
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        }
    }
#endif
