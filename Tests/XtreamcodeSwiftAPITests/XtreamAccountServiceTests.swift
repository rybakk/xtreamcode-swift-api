import XCTest
@testable import XtreamClient
import XtreamModels
@testable import XtreamServices

final class XtreamAccountServiceTests: XCTestCase {
    func testFetchAccountDetailsReturnsMappedSession() async throws {
        let payload = try TestFixtures.data(named: "account_user_info_current")

        let stub = StubURLProtocol.Stub(
            matcher: { request in
                guard
                    let url = request.url,
                    url.path == "/player_api.php",
                    url.query?.contains("action=get_user_info") == true
                else { return false }
                return true
            },
            response: { request in
                guard let url = request.url else {
                    throw URLError(.badURL)
                }
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

        let client = await TestClientFactory.makeClient(stubs: [stub])

        let service = XtreamAccountService(client: client)
        let details = try await service.fetchAccountDetails(credentials: XtreamCredentials(
            username: "demo",
            password: "secret"
        ))

        XCTAssertEqual(details.serverInfo.url, "sanitized.example")
        XCTAssertEqual(details.serverInfo.port, "8111")
        XCTAssertEqual(details.serverInfo.serverProtocol, "http")
        XCTAssertEqual(details.session.username, "SAMPLE_USER")
        XCTAssertEqual(details.session.maxConnections, 1)
        XCTAssertEqual(details.session.allowedOutputFormats, ["m3u8", "ts"])
        XCTAssertEqual(details.session.status, .active)
    }
}
