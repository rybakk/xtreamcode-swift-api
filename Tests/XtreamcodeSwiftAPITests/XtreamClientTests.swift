import XCTest
@testable import XtreamClient
import XtreamModels

private struct PlayerAPIResponse: Decodable {
    struct UserInfo: Decodable {
        let username: String
        let auth: Int
    }

    let userInfo: UserInfo
}

final class XtreamClientTests: XCTestCase {
    private func makeClient(with stubs: [StubURLProtocol.Stub]) async -> XtreamClient {
        await TestClientFactory.makeClient(stubs: stubs)
    }

    func testRequestDecodesPlayerAPIResponse() async throws {
        let data = try TestFixtures.data(named: "auth_login_success_current")

        let stub = StubURLProtocol.Stub(
            matcher: { request in
                guard let url = request.url else { return false }
                return url.path == "/player_api.php"
            },
            response: { request in
                guard let url = request.url else {
                    throw URLError(.badURL)
                }
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let queryItems = components?.queryItems ?? []
                XCTAssertTrue(queryItems.contains(where: { $0.name == "username" && $0.value == "demo" }))
                XCTAssertTrue(queryItems.contains(where: { $0.name == "password" && $0.value == "secret" }))
                guard let response = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                ) else {
                    throw URLError(.badServerResponse)
                }
                return (response, data)
            }
        )

        let client = await makeClient(with: [stub])
        let endpoint = XtreamEndpoint.login()
        let credentials = XtreamCredentials(username: "demo", password: "secret")

        let response: PlayerAPIResponse = try await client.request(endpoint, credentials: credentials)
        XCTAssertEqual(response.userInfo.username, "SAMPLE_USER")
        XCTAssertEqual(response.userInfo.auth, 1)
    }

    func testRequestThrowsUnauthorized() async throws {
        let payload = Data(
            """
            {
                "user_info": {
                    "auth": 0,
                    "status": "Unauthorized"
                }
            }
            """.utf8
        )

        let stub = StubURLProtocol.Stub(
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
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: nil
                ) else {
                    throw URLError(.badServerResponse)
                }
                return (response, payload)
            }
        )

        let client = await makeClient(with: [stub])
        let endpoint = XtreamEndpoint.login()
        let credentials = XtreamCredentials(username: "demo", password: "secret")

        do {
            let _: Data = try await client.data(for: endpoint, credentials: credentials)
            XCTFail("Expected unauthorized error")
        } catch let error as XtreamClientError {
            switch error {
            case let .unauthorized(data):
                XCTAssertEqual(data, payload)
            default:
                XCTFail("Unexpected error \(error)")
            }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testMissingCredentialsThrows() async throws {
        let client = await makeClient(with: [])
        let endpoint = XtreamEndpoint.login()

        do {
            let _: Data = try await client.data(for: endpoint)
            XCTFail("Expected missing credentials error")
        } catch let error as XtreamClientError {
            switch error {
            case .missingCredentials:
                break
            default:
                XCTFail("Unexpected error \(error)")
            }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
