import Foundation
import XCTest
import XtreamClient
import XtreamModels
@testable import XtreamServices

final class XtreamEPGServiceTests: XCTestCase {
    private let credentials = XtreamCredentials(username: "demo", password: "secret")
    private let baseURL: URL = {
        guard let url = URL(string: "https://sanitized.example") else {
            fatalError("Invalid test base URL")
        }
        return url
    }()

    func testFetchShortEPGMapsEntries() async throws {
        let data = try TestFixtures.data(named: "epg_tf1_short")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_short_epg",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "limit" })?.value == "5"
                    && components.queryItems?.first(where: { $0.name == "stream_id" })?.value == "366"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamEPGService(client: client)

        let entries = try await service.fetchShortEPG(credentials: credentials, streamID: 366, limit: 5)

        XCTAssertEqual(entries.count, 5)
        let first = try XCTUnwrap(entries.first)
        XCTAssertEqual(first.id, "64163309")
        XCTAssertNotNil(first.startDate)
        XCTAssertEqual(first.channelID, "TF1.fr")
        XCTAssertEqual(first.decodedTitle, "Coup de foudre au village de Noël")
    }

    func testFetchEPGWithWindow() async throws {
        let data = try TestFixtures.data(named: "epg_bbc_one_full")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_epg",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "stream_id" })?.value == "36011"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamEPGService(client: client)

        let entries = try await service.fetchEPG(
            credentials: credentials,
            streamID: 36011,
            start: Date(timeIntervalSince1970: 1_761_760_000),
            end: Date(timeIntervalSince1970: 1_761_770_700)
        )

        XCTAssertEqual(entries.count, 3)
        let last = try XCTUnwrap(entries.last)
        XCTAssertEqual(last.title, "Drama Premiere")
        XCTAssertEqual(last.language, "en")
    }

    func testFetchCatchupReturnsCollection() async throws {
        let data = try TestFixtures.data(named: "catchup_bbc_one_segments")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_tv_archive",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "stream_id" })?.value == "36011"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamEPGService(client: client)

        let catchup = try await service.fetchCatchup(
            credentials: credentials,
            streamID: 36011,
            start: nil
        )

        let collection = try XCTUnwrap(catchup)
        XCTAssertEqual(collection.streamID, 36011)
        XCTAssertEqual(collection.segments.count, 2)
        XCTAssertEqual(collection.archiveDurationHours, 168)
        XCTAssertEqual(collection.segments.first?.title, "World News")
        XCTAssertNotNil(collection.segments.first?.startDate)
    }

    func testFetchEPGUsesCacheWhenTTLValid() async throws {
        let data = try TestFixtures.data(named: "epg_bbc_one_full")
        let requestCount = LockingBox(0)
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_epg",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "stream_id" })?.value == "36011"
            }
        ).counted(using: requestCount)

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let cacheConfiguration = LiveCacheConfiguration(
            categoriesTTL: 0,
            streamsTTL: 0,
            streamDetailsTTL: 0,
            streamURLsTTL: 0,
            shortEPGTTL: 0,
            fullEPGTTL: 120,
            catchupTTL: 0
        )
        let cache = InMemoryLiveCacheStore()
        let service = XtreamEPGService(
            client: client,
            cache: cache,
            cacheConfiguration: cacheConfiguration
        )

        let start = Date(timeIntervalSince1970: 1_761_760_000)
        let end = Date(timeIntervalSince1970: 1_761_770_700)

        _ = try await service.fetchEPG(
            credentials: credentials,
            streamID: 36011,
            start: start,
            end: end
        )

        _ = try await service.fetchEPG(
            credentials: credentials,
            streamID: 36011,
            start: start,
            end: end
        )

        let hits = requestCount.withValue { $0 }
        XCTAssertEqual(hits, 1, "Expected single network request thanks to cache")
    }

    func testFetchEPGThrowsUnavailableWhenEmpty() async throws {
        let data = try TestFixtures.data(named: "epg_empty")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_epg",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "stream_id" })?.value == "123"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamEPGService(client: client)

        do {
            _ = try await service.fetchEPG(credentials: credentials, streamID: 123, start: nil, end: nil)
            XCTFail("Expected XtreamError.epgUnavailable to be thrown")
        } catch let error as XtreamError {
            switch error {
            case let .epgUnavailable(reason):
                XCTAssertNotNil(reason)
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchCatchupThrowsWhenDisabled() async throws {
        let data = try TestFixtures.data(named: "catchup_disabled")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_tv_archive",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "stream_id" })?.value == "36011"
            }
        )

        let client = await TestClientFactory.makeClient(stubs: [stub], baseURL: baseURL)
        let service = XtreamEPGService(client: client)

        do {
            _ = try await service.fetchCatchup(credentials: credentials, streamID: 36011, start: nil)
            XCTFail("Expected XtreamError.catchupDisabled to be thrown")
        } catch let error as XtreamError {
            switch error {
            case let .catchupDisabled(reason):
                XCTAssertNotNil(reason)
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
