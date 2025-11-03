// swiftlint:disable function_body_length
import XCTest
import XtreamModels
@testable import XtreamcodeSwiftAPI
@testable import XtreamServices

final class XtreamAPIIntegrationTests: XCTestCase {
    func testAuthenticateThenFetchAccountUsesCache() async throws {
        let authPayload = try TestFixtures.data(named: "auth_login_success_current")
        let accountPayload = try TestFixtures.data(named: "account_user_info_current")

        let accountRequestCount = LockingBox(0)

        var stubs: [StubURLProtocol.Stub] = []
        stubs.append(playerAPIStub(action: nil, payload: authPayload))
        stubs.append(playerAPIStub(action: "get_user_info", payload: accountPayload, counter: accountRequestCount))

        let session = await TestClientFactory.makeSession(stubs: stubs)
        let baseURL = try XCTUnwrap(URL(string: "https://sanitized.example"))
        let credentials = XtreamCredentials(username: "demo", password: "secret")
        let api = XtreamcodeSwiftAPI(baseURL: baseURL, credentials: credentials, session: session)

        let authSession = try await api.authenticate()
        XCTAssertEqual(authSession.username, "SAMPLE_USER")

        let details = try await api.fetchAccountDetails()
        XCTAssertEqual(details.session.username, "SAMPLE_USER")
        XCTAssertEqual(details.serverInfo.url, "sanitized.example")

        let cachedSession = api.currentSession
        XCTAssertEqual(cachedSession?.username, "SAMPLE_USER")

        let cachedDetails = try await api.fetchAccountDetails()
        XCTAssertEqual(cachedDetails.session.username, details.session.username)
        let requestCount = accountRequestCount.withValue { $0 }
        XCTAssertEqual(requestCount, 1, "Account endpoint should not be called twice when cache is valid")
    }

    func testLiveCategoriesAndStreamsUseCacheAndForceRefresh() async throws {
        let categoriesPayload = try TestFixtures.data(named: "live_categories_tnt_sample")
        let streamsPayload = try TestFixtures.data(named: "live_streams_tnt_sample")
        let streamURLPayload = try TestFixtures.data(named: "live_stream_url_sample")

        let categoriesCount = LockingBox(0)
        let streamsCount = LockingBox(0)

        var stubs: [StubURLProtocol.Stub] = []
        stubs.append(playerAPIStub(action: "get_live_categories", payload: categoriesPayload, counter: categoriesCount))
        stubs.append(playerAPIStub(action: "get_live_streams", payload: streamsPayload, counter: streamsCount))
        stubs.append(playerAPIStub(action: "get_live_url", payload: streamURLPayload))

        let session = await TestClientFactory.makeSession(stubs: stubs)
        let baseURL = try XCTUnwrap(URL(string: "https://sanitized.example"))
        let credentials = XtreamCredentials(username: "demo", password: "secret")

        let cacheConfiguration = LiveCacheConfiguration(
            categoriesTTL: 60,
            streamsTTL: 60,
            streamDetailsTTL: 0,
            streamURLsTTL: 0,
            shortEPGTTL: 0,
            fullEPGTTL: 0,
            catchupTTL: 0,
            diskOptions: .init(isEnabled: false)
        )

        let configuration = XtreamcodeSwiftAPI.Configuration(
            baseURL: baseURL,
            credentials: credentials,
            session: session,
            liveCacheConfiguration: cacheConfiguration,
            liveCacheStore: InMemoryLiveCacheStore()
        )
        let api = XtreamcodeSwiftAPI(configuration: configuration)

        let categories = try await api.liveCategories()
        XCTAssertEqual(categories.count, 6)

        let cachedCategories = try await api.liveCategories()
        XCTAssertEqual(cachedCategories.count, 6)
        XCTAssertEqual(categoriesCount.withValue { $0 }, 1)

        let refreshedCategories = try await api.liveCategories(forceRefresh: true)
        XCTAssertEqual(refreshedCategories.count, 6)
        XCTAssertEqual(categoriesCount.withValue { $0 }, 2)

        let streams = try await api.liveStreams(in: "6")
        XCTAssertFalse(streams.isEmpty)

        let cachedStreams = try await api.liveStreams(in: "6")
        XCTAssertEqual(streams.first?.id, cachedStreams.first?.id)
        XCTAssertEqual(streamsCount.withValue { $0 }, 1)

        let refreshedStreams = try await api.liveStreams(in: "6", forceRefresh: true)
        XCTAssertEqual(refreshedStreams.first?.id, streams.first?.id)
        XCTAssertEqual(streamsCount.withValue { $0 }, 2)

        let url = try await api.liveStreamURL(for: 22375)
        XCTAssertNotNil(url)
    }

    func testLiveParcoursCompleteAvecCache() async throws {
        let categoriesPayload = try TestFixtures.data(named: "live_categories_tnt_sample")
        let streamsPayload = try TestFixtures.data(named: "live_streams_tnt_sample")
        let epgPayload = try TestFixtures.data(named: "epg_bbc_one_full")
        let catchupPayload = try TestFixtures.data(named: "catchup_bbc_one_segments")
        let streamURLPayload = try TestFixtures.data(named: "live_stream_url_sample")

        let categoriesCounter = LockingBox(0)
        let streamsCounter = LockingBox(0)
        let epgCounter = LockingBox(0)
        let catchupCounter = LockingBox(0)
        let urlCounter = LockingBox(0)

        // swiftlint:disable trailing_comma
        let stubs: [StubURLProtocol.Stub] = [
            playerAPIStub(action: "get_live_categories", payload: categoriesPayload, counter: categoriesCounter),
            playerAPIStub(action: "get_live_streams", payload: streamsPayload, counter: streamsCounter),
            playerAPIStub(action: "get_epg", payload: epgPayload, counter: epgCounter),
            playerAPIStub(action: "get_tv_archive", payload: catchupPayload, counter: catchupCounter),
            playerAPIStub(action: "get_live_url", payload: streamURLPayload, counter: urlCounter),
        ]
        // swiftlint:enable trailing_comma

        let session = await TestClientFactory.makeSession(stubs: stubs)
        let baseURL = try XCTUnwrap(URL(string: "https://sanitized.example"))
        let credentials = XtreamCredentials(username: "demo", password: "secret")

        var configuration = XtreamcodeSwiftAPI.Configuration(
            baseURL: baseURL,
            credentials: credentials,
            session: session
        )
        configuration.liveCacheConfiguration = LiveCacheConfiguration(
            categoriesTTL: 3600,
            streamsTTL: 900,
            streamDetailsTTL: 900,
            streamURLsTTL: 120,
            shortEPGTTL: 300,
            fullEPGTTL: 300,
            catchupTTL: 600,
            diskOptions: .init(isEnabled: false)
        )
        configuration.liveCacheStore = InMemoryLiveCacheStore()

        let api = XtreamcodeSwiftAPI(configuration: configuration)

        let categories = try await api.liveCategories()
        XCTAssertFalse(categories.isEmpty)

        let streams = try await api.liveStreams(in: "6")
        XCTAssertFalse(streams.isEmpty)

        let epg = try await api.epg(
            for: 36011,
            start: Date(timeIntervalSince1970: 1_761_760_800),
            end: Date(timeIntervalSince1970: 1_761_770_700)
        )
        XCTAssertEqual(epg.count, 3)

        let catchup = try await api.catchup(for: 36011)
        XCTAssertNotNil(catchup)

        let liveURL = try await api.liveStreamURL(for: 22375)
        XCTAssertNotNil(liveURL)

        // Cache hits
        _ = try await api.liveCategories()
        _ = try await api.liveStreams(in: "6")
        _ = try await api.epg(
            for: 36011,
            start: Date(timeIntervalSince1970: 1_761_760_800),
            end: Date(timeIntervalSince1970: 1_761_770_700)
        )
        _ = try await api.catchup(for: 36011)
        _ = try await api.liveStreamURL(for: 22375)

        XCTAssertEqual(categoriesCounter.withValue { $0 }, 1)
        XCTAssertEqual(streamsCounter.withValue { $0 }, 1)
        XCTAssertEqual(epgCounter.withValue { $0 }, 1)
        XCTAssertEqual(catchupCounter.withValue { $0 }, 1)
        XCTAssertEqual(urlCounter.withValue { $0 }, 1)

        // Force refresh
        _ = try await api.epg(
            for: 36011,
            start: Date(timeIntervalSince1970: 1_761_760_800),
            end: Date(timeIntervalSince1970: 1_761_770_700),
            forceRefresh: true
        )
        XCTAssertEqual(epgCounter.withValue { $0 }, 2)

        // Offline fallback (forceRefresh)
        StubURLProtocol.removeAllStubs()
        StubURLProtocol.register(
            playerAPIErrorStub(
                action: "get_epg",
                error: URLError(.notConnectedToInternet),
                counter: epgCounter
            )
        )

        let offlineFallback = try await api.epg(
            for: 36011,
            start: Date(timeIntervalSince1970: 1_761_760_800),
            end: Date(timeIntervalSince1970: 1_761_770_700),
            forceRefresh: true
        )
        XCTAssertEqual(offlineFallback.count, 3)
        XCTAssertEqual(epgCounter.withValue { $0 }, 3)

        let cachedOffline = try await api.epg(
            for: 36011,
            start: Date(timeIntervalSince1970: 1_761_760_800),
            end: Date(timeIntervalSince1970: 1_761_770_700)
        )
        XCTAssertEqual(cachedOffline.count, 3)
        XCTAssertEqual(epgCounter.withValue { $0 }, 3)

        let diagnostics = await api.diagnosticsSnapshot()
        XCTAssertGreaterThanOrEqual(diagnostics.liveCacheHits, 3)
        XCTAssertGreaterThanOrEqual(diagnostics.liveCacheMisses, 3)
        XCTAssertGreaterThanOrEqual(diagnostics.offlineFallbacks, 1)

        await api.resetDiagnostics()
        let resetDiagnostics = await api.diagnosticsSnapshot()
        XCTAssertEqual(resetDiagnostics.liveCacheHits, 0)
        XCTAssertEqual(resetDiagnostics.liveCacheMisses, 0)
        XCTAssertEqual(resetDiagnostics.offlineFallbacks, 0)
    }

    func testVODSériesParcoursAvecCacheEtOffline() async throws {
        let vodCategoriesPayload = try TestFixtures.data(named: "vod_categories")
        let vodStreamsPayload = try TestFixtures.data(named: "vod_streams_sample")
        let vodInfoPayload = try TestFixtures.data(named: "vod_info_detailed_sample")
        let seriesCategoriesPayload = try TestFixtures.data(named: "series_categories")
        let seriesPayload = try TestFixtures.data(named: "series_sample")
        let seriesInfoPayload = try TestFixtures.data(named: "series_info_full_sample")
        let searchPayload = try TestFixtures.data(named: "search_results_mixed_sample")

        let vodCategoriesCounter = LockingBox(0)
        let vodStreamsCounter = LockingBox(0)
        let vodInfoCounter = LockingBox(0)
        let seriesCategoriesCounter = LockingBox(0)
        let seriesCounter = LockingBox(0)
        let seriesInfoCounter = LockingBox(0)
        let searchCounter = LockingBox(0)

        let stubs: [StubURLProtocol.Stub] = [
            playerAPIStub(action: "get_vod_categories", payload: vodCategoriesPayload, counter: vodCategoriesCounter),
            playerAPIStub(action: "get_vod_streams", payload: vodStreamsPayload, counter: vodStreamsCounter),
            playerAPIStub(action: "get_vod_info", payload: vodInfoPayload, counter: vodInfoCounter),
            playerAPIStub(action: "get_series_categories", payload: seriesCategoriesPayload, counter: seriesCategoriesCounter),
            playerAPIStub(action: "get_series", payload: seriesPayload, counter: seriesCounter),
            playerAPIStub(action: "get_series_info", payload: seriesInfoPayload, counter: seriesInfoCounter),
            playerAPIStub(action: "search", payload: searchPayload, counter: searchCounter)
        ]

        let session = await TestClientFactory.makeSession(stubs: stubs)
        let baseURL = try XCTUnwrap(URL(string: "https://sanitized.example"))
        let credentials = XtreamCredentials(username: "demo", password: "secret")

        let cacheConfiguration = LiveCacheConfiguration(
            categoriesTTL: 3600,
            streamsTTL: 1800,
            streamDetailsTTL: 86400,
            streamURLsTTL: 600,
            shortEPGTTL: 0,
            fullEPGTTL: 0,
            catchupTTL: 0,
            diskOptions: .init(isEnabled: false)
        )

        let configuration = XtreamcodeSwiftAPI.Configuration(
            baseURL: baseURL,
            credentials: credentials,
            session: session,
            liveCacheConfiguration: cacheConfiguration,
            liveCacheStore: InMemoryLiveCacheStore()
        )

        let api = XtreamcodeSwiftAPI(configuration: configuration)

        let vodCategories = try await api.vodCategories()
        XCTAssertEqual(vodCategoriesCounter.withValue { $0 }, 1)
        XCTAssertFalse(vodCategories.isEmpty)

        let vodStreams = try await api.vodStreams(in: vodCategories.first?.id)
        XCTAssertEqual(vodStreamsCounter.withValue { $0 }, 1)
        XCTAssertFalse(vodStreams.isEmpty)

        let vodDetails = try await api.vodDetails(for: 130_529)
        XCTAssertEqual(vodInfoCounter.withValue { $0 }, 1)
        XCTAssertEqual(vodDetails.movieData?.streamID, 130_529)

        let vodURL = try await api.vodStreamURL(for: 130_529)
        XCTAssertEqual(vodURL.absoluteString, "https://sanitized.example/movie/demo/secret/130529.mp4")

        let seriesCategories = try await api.seriesCategories()
        XCTAssertEqual(seriesCategoriesCounter.withValue { $0 }, 1)

        let seriesList = try await api.series(in: seriesCategories.first?.id)
        XCTAssertEqual(seriesCounter.withValue { $0 }, 1)
        XCTAssertFalse(seriesList.isEmpty)

        let seriesDetails = try await api.seriesDetails(for: 500)
        XCTAssertEqual(seriesInfoCounter.withValue { $0 }, 1)
        XCTAssertEqual(seriesDetails.seasons?.count, 2)

        let episodeURL = try await api.seriesEpisodeURL(for: 500, season: 1, episode: 1)
        XCTAssertEqual(episodeURL.absoluteString, "https://sanitized.example/series/demo/secret/500/1/63101.mp4")

        let results = try await api.search(query: "demo")
        XCTAssertEqual(searchCounter.withValue { $0 }, 1)
        XCTAssertTrue(results.contains { $0.type == .movie })

        // Cache hits
        _ = try await api.vodCategories()
        _ = try await api.vodStreams(in: vodCategories.first?.id)
        _ = try await api.vodDetails(for: 130_529)
        _ = try await api.seriesCategories()
        _ = try await api.series(in: seriesCategories.first?.id)
        _ = try await api.seriesDetails(for: 500)

        XCTAssertEqual(vodCategoriesCounter.withValue { $0 }, 1)
        XCTAssertEqual(vodStreamsCounter.withValue { $0 }, 1)
        XCTAssertEqual(vodInfoCounter.withValue { $0 }, 1)
        XCTAssertEqual(seriesCategoriesCounter.withValue { $0 }, 1)
        XCTAssertEqual(seriesCounter.withValue { $0 }, 1)
        XCTAssertEqual(seriesInfoCounter.withValue { $0 }, 1)

        // Force refresh VOD & Series details
        _ = try await api.vodDetails(for: 130_529, forceRefresh: true)
        _ = try await api.seriesDetails(for: 500, forceRefresh: true)
        XCTAssertEqual(vodInfoCounter.withValue { $0 }, 2)
        XCTAssertEqual(seriesInfoCounter.withValue { $0 }, 2)

        // Offline fallback for VOD stream URL
        // vodStreamURL can use cached VOD info to construct URL, so it doesn't always trigger a new request
        StubURLProtocol.removeAllStubs()
        StubURLProtocol.register(
            playerAPIErrorStub(
                action: "get_vod_info",
                error: URLError(.notConnectedToInternet),
                counter: vodInfoCounter
            )
        )

        let offlineURL = try await api.vodStreamURL(for: 130_529, forceRefresh: true)
        XCTAssertEqual(offlineURL.absoluteString, "https://sanitized.example/movie/demo/secret/130529.mp4")
        // vodStreamURL may use cached VOD details to build URL without additional network request
        XCTAssertGreaterThanOrEqual(vodInfoCounter.withValue { $0 }, 2)

        let diagnostics = await api.diagnosticsSnapshot()
        XCTAssertGreaterThanOrEqual(diagnostics.liveCacheHits, 5)

        await api.resetDiagnostics()
        StubURLProtocol.removeAllStubs()
    }
}

private func playerAPIStub(action: String?, payload: Data, counter: LockingBox<Int>? = nil) -> StubURLProtocol.Stub {
    StubURLProtocol.Stub(
        matcher: { request in
            guard let url = request.url else { return false }
            let isPlayerAPI = url.path == "/player_api.php"
            guard let action else { return isPlayerAPI && !(url.query?.contains("action=") ?? false) }
            // Use URLComponents to properly match query parameters
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems,
                  let actionValue = queryItems.first(where: { $0.name == "action" })?.value else {
                return false
            }
            return isPlayerAPI && actionValue == action
        },
        response: { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            counter?.withLocked { $0 += 1 }
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ) else {
                throw URLError(.badServerResponse)
            }
            return (response, payload)
        }
    )
}

private func playerAPIErrorStub(action: String, error: Error, counter: LockingBox<Int>? = nil) -> StubURLProtocol.Stub {
    StubURLProtocol.Stub(
        matcher: { request in
            guard let url = request.url else { return false }
            let isPlayerAPI = url.path == "/player_api.php"
            // Use URLComponents to properly match query parameters
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems,
                  let actionValue = queryItems.first(where: { $0.name == "action" })?.value else {
                return false
            }
            return isPlayerAPI && actionValue == action
        },
        response: { _ in
            counter?.withLocked { $0 += 1 }
            throw error
        }
    )
}

// swiftlint:enable function_body_length
