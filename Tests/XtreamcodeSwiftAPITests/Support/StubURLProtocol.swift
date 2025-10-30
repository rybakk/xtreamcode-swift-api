// swiftlint:disable static_over_final_class
@preconcurrency import Alamofire
import Foundation

final class StubURLProtocol: URLProtocol {
    struct Stub: @unchecked Sendable {
        let matcher: @Sendable (URLRequest) -> Bool
        let response: @Sendable (URLRequest) throws -> (HTTPURLResponse, Data?)
    }

    private static let storage = LockingBox<[Stub]>([])

    static func register(_ stub: Stub) {
        storage.withLocked { stubs in
            stubs.append(stub)
        }
    }

    static func removeAllStubs() {
        storage.withLocked { stubs in
            stubs.removeAll()
        }
    }

    static func makeSession() -> Session {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return Session(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        storage.withValue { stubs in
            stubs.contains { $0.matcher(request) }
        }
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.storage.withValue({ stubs in
            stubs.first { $0.matcher(request) }
        }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        do {
            let (response, data) = try handler.response(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension StubURLProtocol.Stub {
    func counted(using counter: LockingBox<Int>) -> StubURLProtocol.Stub {
        let originalMatcher = matcher
        let originalResponse = response

        return StubURLProtocol.Stub(
            matcher: originalMatcher,
            response: { request in
                counter.withLocked { $0 += 1 }
                return try originalResponse(request)
            }
        )
    }

    static func exactURL(
        _ url: URL,
        statusCode: Int = 200,
        headers: [String: String]? = nil,
        data: Data? = nil
    ) -> StubURLProtocol.Stub {
        StubURLProtocol.Stub(
            matcher: { $0.url == url },
            response: { _ in
                guard let response = HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: headers
                ) else {
                    throw URLError(.badServerResponse)
                }
                return (response, data)
            }
        )
    }

    static func path(
        _ path: String,
        baseURL: URL,
        statusCode: Int = 200,
        headers: [String: String]? = nil,
        data: Data? = nil
    ) -> StubURLProtocol.Stub {
        StubURLProtocol.Stub(
            matcher: { request in
                guard let url = request.url else { return false }
                return url.path == path && url.host == baseURL.host && url.port == baseURL.port && url.scheme == baseURL
                    .scheme
            },
            response: { request in
                let url = request.url ?? baseURL.appendingPathComponent(path)
                guard let response = HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: headers
                ) else {
                    throw URLError(.badServerResponse)
                }
                return (response, data)
            }
        )
    }

    static func playerAPI(
        baseURL: URL,
        action: String? = nil,
        statusCode: Int = 200,
        headers: [String: String]? = ["Content-Type": "application/json"],
        data: Data? = nil,
        componentsMatcher: (@Sendable (URLComponents) -> Bool)? = nil
    ) -> StubURLProtocol.Stub {
        StubURLProtocol.Stub(
            matcher: { request in
                guard
                    let url = request.url,
                    url.scheme == baseURL.scheme,
                    url.host == baseURL.host,
                    url.port == baseURL.port,
                    url.path == "/player_api.php",
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                else {
                    return false
                }

                let hasActionQuery = components.queryItems?.contains(where: { $0.name == "action" }) == true

                if let action {
                    let actionValue = components.queryItems?.first(where: { $0.name == "action" })?.value
                    guard actionValue == action else { return false }
                } else if hasActionQuery {
                    return false
                }

                if let componentsMatcher {
                    if componentsMatcher(components) == false {
                        return false
                    }
                }

                return true
            },
            response: { request in
                guard let url = request.url else {
                    throw URLError(.badURL)
                }
                guard let response = HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: headers
                ) else {
                    throw URLError(.badServerResponse)
                }
                return (response, data)
            }
        )
    }
}

// swiftlint:enable static_over_final_class
