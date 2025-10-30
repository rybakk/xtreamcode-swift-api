import XCTest
@testable import XtreamClient
import XtreamModels
@testable import XtreamServices

final class XtreamAuthServiceTests: XCTestCase {
    func testLoginReturnsSession() async throws {
        let payload = try TestFixtures.data(named: "auth_login_success_current")

        let client = await TestClientFactory.makeClient(stubs: [loginStub(statusCode: 200, payload: payload)])

        let service = XtreamAuthService(client: client)
        let session = try await service.login(credentials: XtreamCredentials(username: "demo", password: "secret"))

        XCTAssertEqual(session.username, "SAMPLE_USER")
        XCTAssertEqual(session.allowedOutputFormats, ["m3u8", "ts"])
        XCTAssertEqual(session.maxConnections, 1)
        XCTAssertFalse(session.isTrial)
        XCTAssertEqual(session.status, .active)
    }

    func testLoginInvalidCredentialsThrowsSpecificError() async throws {
        let payload = try TestFixtures.data(named: "auth_login_invalid")

        let client = await TestClientFactory.makeClient(stubs: [loginStub(statusCode: 401, payload: payload)])

        let service = XtreamAuthService(client: client)

        do {
            _ = try await service.login(credentials: XtreamCredentials(username: "demo", password: "bad"))
            XCTFail("Expected invalid credentials error")
        } catch let error as XtreamAuthError {
            if case let .invalidCredentials(message) = error {
                XCTAssertEqual(message, "Invalid username or password")
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testLoginExpiredAccountThrowsSpecificError() async throws {
        let payload = try TestFixtures.data(named: "auth_login_expired")

        let client = await TestClientFactory.makeClient(stubs: [loginStub(statusCode: 401, payload: payload)])

        let service = XtreamAuthService(client: client)

        do {
            _ = try await service.login(credentials: XtreamCredentials(username: "demo", password: "secret"))
            XCTFail("Expected account expired error")
        } catch let error as XtreamAuthError {
            if case let .accountExpired(expiration) = error {
                XCTAssertNotNil(expiration)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testLoginTooManyConnectionsThrowsSpecificError() async throws {
        let payload = try TestFixtures.data(named: "auth_login_toomany")

        let client = await TestClientFactory.makeClient(stubs: [loginStub(statusCode: 401, payload: payload)])

        let service = XtreamAuthService(client: client)

        do {
            _ = try await service.login(credentials: XtreamCredentials(username: "demo", password: "secret"))
            XCTFail("Expected too many connections error")
        } catch let error as XtreamAuthError {
            if case let .tooManyConnections(active, max) = error {
                XCTAssertEqual(active, 2)
                XCTAssertEqual(max, 2)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}

private func loginStub(statusCode: Int, payload: Data) -> StubURLProtocol.Stub {
    StubURLProtocol.Stub(
        matcher: { request in
            guard let url = request.url else { return false }
            return url.path == "/player_api.php"
        },
        response: { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: statusCode == 200 ? ["Content-Type": "application/json"] : nil
            ) else {
                throw URLError(.badServerResponse)
            }
            return (response, payload)
        }
    )
}
