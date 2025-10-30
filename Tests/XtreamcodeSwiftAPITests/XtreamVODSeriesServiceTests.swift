import XCTest
import XtreamClient
import XtreamModels
@testable import XtreamServices

final class XtreamVODSeriesServiceTests: XCTestCase {
    private let credentials = XtreamCredentials(username: "demo", password: "secret")
    private let baseURL: URL = {
        guard let url = URL(string: "https://sanitized.example") else {
            fatalError("Invalid test base URL")
        }
        return url
    }()

    func testFetchVODDetailsMapsMetadata() async throws {
        let payload = try TestFixtures.data(named: "vod_info_detailed_sample")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_vod_info",
            data: payload,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "vod_id" })?.value == "101"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamVODService(client: client)

        let info = try await service.fetchDetails(credentials: credentials, vodID: 101)

        let movieInfo = try XCTUnwrap(info.info)
        XCTAssertEqual(movieInfo.name, "Fight Club")
        XCTAssertEqual(movieInfo.tmdbID, "550")
        XCTAssertEqual(movieInfo.backdropPath?.count, 2)

        let movieData = try XCTUnwrap(info.movieData)
        XCTAssertEqual(movieData.streamID, 130_529)
        XCTAssertEqual(movieData.containerExtension, "mp4")
    }

    func testVODCategoriesUsesCache() async throws {
        let payload = try TestFixtures.data(named: "vod_categories")
        let counter = LockingBox(0)

        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_vod_categories",
            data: payload
        ).counted(using: counter)

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let cache = InMemoryLiveCacheStore()
        let configuration = LiveCacheConfiguration(
            categoriesTTL: 120,
            streamsTTL: 0,
            streamDetailsTTL: 0,
            streamURLsTTL: 0,
            shortEPGTTL: 0,
            fullEPGTTL: 0,
            catchupTTL: 0
        )
        let service = XtreamVODService(
            client: client,
            cache: cache,
            cacheConfiguration: configuration
        )

        _ = try await service.fetchCategories(credentials: credentials)
        _ = try await service.fetchCategories(credentials: credentials)

        XCTAssertEqual(counter.withValue { $0 }, 1)
    }

    func testFetchVODStreamURLBuildsPlaybackURL() async throws {
        let payload = try TestFixtures.data(named: "vod_info_detailed_sample")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_vod_info",
            data: payload,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "vod_id" })?.value == "130529"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamVODService(client: client)

        let url = try await service.fetchStreamURL(credentials: credentials, vodID: 130_529)

        XCTAssertEqual(url.absoluteString, "https://sanitized.example/movie/demo/secret/130529.mp4")
    }

    func testFetchVODStreamURLUsesDirectSourceWhenAvailable() async throws {
        let basePayload = try JSONSerialization.jsonObject(
            with: TestFixtures.data(named: "vod_info_detailed_sample"),
            options: []
        ) as? [String: Any] ?? [:]
        var payload = basePayload
        if var movieData = payload["movie_data"] as? [String: Any] {
            movieData["direct_source"] = "https://cdn.example/fightclub.m3u8"
            payload["movie_data"] = movieData
        }
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])

        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_vod_info",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "vod_id" })?.value == "777"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamVODService(client: client)

        let url = try await service.fetchStreamURL(credentials: credentials, vodID: 777)

        XCTAssertEqual(url.absoluteString, "https://cdn.example/fightclub.m3u8")
    }

    func testFetchSeriesDetailsProvidesEpisodes() async throws {
        let payload = try TestFixtures.data(named: "series_info_full_sample")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_series_info",
            data: payload,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "series_id" })?.value == "500"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamSeriesService(client: client)

        let info = try await service.fetchDetails(credentials: credentials, seriesID: 500)

        XCTAssertEqual(info.seasons?.count, 2)
        let firstSeason = try XCTUnwrap(info.seasons?.first)
        XCTAssertEqual(firstSeason.seasonNumber, 1)

        let episodesSeason1 = try XCTUnwrap(info.episodes?["1"])
        XCTAssertFalse(episodesSeason1.isEmpty)
        let pilot = try XCTUnwrap(episodesSeason1.first)
        XCTAssertEqual(pilot.episodeNum, 1)
        XCTAssertEqual(pilot.containerExtension, "mp4")
    }

    func testFetchSeriesEpisodeURLBuildsPlaybackURL() async throws {
        let payload = try TestFixtures.data(named: "series_info_full_sample")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_series_info",
            data: payload,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "series_id" })?.value == "500"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamSeriesService(client: client)

        let url = try await service.fetchEpisodeURL(
            credentials: credentials,
            seriesID: 500,
            season: 1,
            episode: 1
        )

        XCTAssertEqual(url.absoluteString, "https://sanitized.example/series/demo/secret/500/1/63101.mp4")
    }

    func testFetchSeriesEpisodeURLThrowsWhenEpisodeMissing() async throws {
        let payload = try TestFixtures.data(named: "series_info_full_sample")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_series_info",
            data: payload,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "series_id" })?.value == "500"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamSeriesService(client: client)

        do {
            _ = try await service.fetchEpisodeURL(
                credentials: credentials,
                seriesID: 500,
                season: 4,
                episode: 99
            )
            XCTFail("Expected episodeNotFound error")
        } catch let XtreamError.episodeNotFound(seriesID, season, episode) {
            XCTAssertEqual(seriesID, 500)
            XCTAssertEqual(season, 4)
            XCTAssertEqual(episode, 99)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSearchReturnsTypedResults() async throws {
        let payload = try TestFixtures.data(named: "search_results_mixed_sample")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "search",
            data: payload,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "search" })?.value == "demo"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamSearchService(client: client)

        let results = try await service.search(credentials: credentials, query: "demo", type: .all)

        XCTAssertEqual(results.count, 5)
        XCTAssertTrue(results.contains { $0.type == .movie })
        XCTAssertTrue(results.contains { $0.type == .series })
        XCTAssertTrue(results.contains { $0.type == .live })
    }
}
