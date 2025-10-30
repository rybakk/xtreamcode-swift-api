import XCTest
import XtreamModels
@testable import XtreamSDKFacade

final class XtreamAPIMediaTests: XCTestCase {
    private let baseURL: URL = {
        guard let url = URL(string: "https://sanitized.example") else {
            fatalError("Invalid test base URL")
        }
        return url
    }()

    private let credentials = XtreamCredentials(username: "demo", password: "secret")

    func testProgressStoreRoundTrip() async throws {
        let suiteName = "com.xtreamcode.tests.progress.\(UUID().uuidString)"
        let store = UserDefaultsProgressStore(suiteName: suiteName)

        let session = await TestClientFactory.makeSession(stubs: [])
        var configuration = XtreamcodeSwiftAPI.Configuration(
            baseURL: baseURL,
            credentials: credentials,
            session: session
        )
        configuration.progressStore = store

        let api = XtreamcodeSwiftAPI(configuration: configuration)

        let saved = try await api.saveProgress(contentID: "vod-999", position: 120, duration: 360)
        let loaded = try await api.loadProgress(contentID: "vod-999")
        guard let loaded else {
            return XCTFail("Expected progress to be stored")
        }
        XCTAssertEqual(loaded.contentID, saved.contentID)
        XCTAssertEqual(loaded.position, saved.position, accuracy: 0.001)
        XCTAssertEqual(loaded.duration, saved.duration, accuracy: 0.001)
        let loadedDate = loaded.updatedAt.timeIntervalSinceReferenceDate
        XCTAssertEqual(loadedDate, saved.updatedAt.timeIntervalSinceReferenceDate, accuracy: 1.5)

        try await api.clearProgress(contentID: "vod-999")
        let afterClear = try await api.loadProgress(contentID: "vod-999")
        XCTAssertNil(afterClear)

        try await store.removeAll()
    }
}
