import XCTest
import XtreamModels
@testable import XtreamSDKFacade

final class LiveIssueReportTests: XCTestCase {
    private var baseURL: URL {
        guard let url = URL(string: "https://demo.xtream-codes.test") else {
            fatalError("Invalid demo URL")
        }
        return url
    }

    private let credentials = XtreamCredentials(username: "sample", password: "secret")

    func testMakeLiveIssueReportCapturesMetadata() async {
        let session = await TestClientFactory.makeSession(stubs: [])

        var configuration = XtreamcodeSwiftAPI.Configuration(
            baseURL: baseURL,
            credentials: credentials,
            session: session
        )

        configuration.liveCacheConfiguration.categoriesTTL = 120
        configuration.liveCacheConfiguration.streamsTTL = 90
        configuration.liveCacheConfiguration.streamDetailsTTL = 60
        configuration.liveCacheConfiguration.streamURLsTTL = 30
        configuration.liveCacheConfiguration.shortEPGTTL = 45
        configuration.liveCacheConfiguration.fullEPGTTL = 50
        configuration.liveCacheConfiguration.catchupTTL = 75
        configuration.liveCacheConfiguration.diskOptions = .init(isEnabled: false)

        enum DummyError: Error { case maintenance }

        let api = XtreamcodeSwiftAPI(configuration: configuration)
        let report = await api.makeMediaIssueReport(
            domain: .vod,
            error: DummyError.maintenance,
            additionalNotes: ["device": "Apple TV"]
        )

        XCTAssertEqual(report.metadata.username, credentials.username)
        XCTAssertEqual(report.metadata.baseURL, baseURL)
        XCTAssertEqual(report.metadata.platform, LiveIssueReport.platformIdentifier())
        XCTAssertNotNil(report.metadata.generatedAt.timeIntervalSince1970)

        XCTAssertEqual(report.cacheConfiguration.categoriesTTL, 120)
        XCTAssertEqual(report.cacheConfiguration.streamURLsTTL, 30)
        XCTAssertFalse(report.cacheConfiguration.diskEnabled)

        XCTAssertEqual(report.diagnostics.liveCacheHits, 0)
        XCTAssertEqual(report.additionalNotes["device"], "Apple TV")
        XCTAssertTrue(report.errorDescription?.contains("maintenance") ?? false)
    }
}
