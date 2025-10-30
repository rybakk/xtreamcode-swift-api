import Foundation
import XCTest
import XtreamClient
import XtreamModels
@testable import XtreamServices

final class XtreamLiveServiceTests: XCTestCase {
    private let credentials = XtreamCredentials(username: "demo", password: "secret")
    private let baseURL: URL = {
        guard let url = URL(string: "https://sanitized.example") else {
            fatalError("Invalid test base URL")
        }
        return url
    }()

    func testFetchCategoriesMapsResponse() async throws {
        let data = try TestFixtures.data(named: "live_categories_tnt_sample")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_live_categories",
            data: data
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamLiveService(client: client)

        let categories = try await service.fetchCategories(credentials: credentials)

        XCTAssertEqual(categories.count, 6)
        let first = try XCTUnwrap(categories.first)
        XCTAssertEqual(first.id, "5")
        XCTAssertEqual(first.name, "USA")
        XCTAssertEqual(first.parentID, 0)
    }

    func testFetchStreamsForCategoryMapsFields() async throws {
        let data = try TestFixtures.data(named: "live_streams_tnt_sample")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_live_streams",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "category_id" })?.value == "6"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamLiveService(client: client)

        let streams = try await service.fetchStreams(credentials: credentials, categoryID: "6")

        XCTAssertEqual(streams.count, 5)
        let stream = try XCTUnwrap(streams.first)
        XCTAssertEqual(stream.id, 22375)
        XCTAssertEqual(stream.number, 1)
        XCTAssertEqual(stream.categoryID, "6")
        XCTAssertEqual(stream.type, .live)
        XCTAssertFalse(stream.hasCatchup)
    }

    func testFetchStreamDetailsReturnsSingleStream() async throws {
        let data = try TestFixtures.data(named: "live_stream_details_sample")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_live_streams",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "stream_id" })?.value == "22375"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamLiveService(client: client)

        let stream = try await service.fetchStreamDetails(credentials: credentials, streamID: 22375)

        XCTAssertNotNil(stream)
        XCTAssertEqual(stream?.id, 22375)
        XCTAssertEqual(
            stream?.name,
            "EVENT 1: UFC FIGHT NIGHT 135 EARLY PRELIMS 8/25 6:30PM EST"
        )
    }

    func testFetchStreamURLsFiltersInvalidEntries() async throws {
        var response = try JSONSerialization.jsonObject(
            with: TestFixtures.data(named: "live_stream_url_sample"),
            options: []
        ) as? [String: Any] ?? [:]
        var urls = response["stream_urls"] as? [[String: Any]] ?? []
        urls.append(["quality": "broken", "container_extension": "m3u8", "playlist_url": ""])
        response["stream_urls"] = urls

        let payload = try JSONSerialization.data(withJSONObject: response, options: [.prettyPrinted])
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_live_url",
            data: payload,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "stream_id" })?.value == "22375"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamLiveService(client: client)

        let urlsResult = try await service.fetchStreamURLs(credentials: credentials, streamID: 22375)

        XCTAssertEqual(urlsResult.count, 2)
        XCTAssertEqual(urlsResult.first?.containerExtension, "m3u8")
        XCTAssertEqual(urlsResult.first?.quality, "1080p")
    }

    func testFetchCategoriesUsesCacheWhenTTLValid() async throws {
        let data = try TestFixtures.data(named: "live_categories_tnt_sample")
        let requestCount = LockingBox(0)

        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_live_categories",
            data: data,
            componentsMatcher: nil
        ).counted(using: requestCount)

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let cacheConfiguration = LiveCacheConfiguration(
            categoriesTTL: 60,
            streamsTTL: 0,
            streamDetailsTTL: 0,
            streamURLsTTL: 0,
            shortEPGTTL: 0,
            fullEPGTTL: 0,
            catchupTTL: 0
        )
        let cache = InMemoryLiveCacheStore()
        let service = XtreamLiveService(
            client: client,
            cache: cache,
            cacheConfiguration: cacheConfiguration
        )

        _ = try await service.fetchCategories(credentials: credentials)
        _ = try await service.fetchCategories(credentials: credentials)

        let hits = requestCount.withValue { $0 }
        XCTAssertEqual(hits, 1, "Expected single network request thanks to cache")
    }

    func testFetchStreamURLsThrowsLiveUnavailableWhenEmpty() async throws {
        let data = try TestFixtures.data(named: "live_stream_url_empty")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_live_url",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "stream_id" })?.value == "999"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamLiveService(client: client)

        do {
            _ = try await service.fetchStreamURLs(credentials: credentials, streamID: 999)
            XCTFail("Expected XtreamError.liveUnavailable to be thrown")
        } catch let error as XtreamError {
            switch error {
            case let .liveUnavailable(statusCode, reason):
                XCTAssertNil(statusCode)
                XCTAssertNotNil(reason)
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
