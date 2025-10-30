import Alamofire
import Foundation
import XCTest
import XtreamClient

enum TestFixtures {
    static func data(named name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw NSError(domain: "Fixture", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing fixture \(name)"])
        }
        return try Data(contentsOf: url)
    }
}

enum TestClientFactory {
    private static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://sanitized.example") else {
            preconditionFailure("Invalid default base URL")
        }
        return url
    }()

    @MainActor
    private static func makeSession(stubs: [StubURLProtocol.Stub]) -> Session {
        StubURLProtocol.removeAllStubs()
        for stub in stubs {
            StubURLProtocol.register(stub)
        }
        return StubURLProtocol.makeSession()
    }

    static func makeClient(stubs: [StubURLProtocol.Stub], baseURL: URL? = nil) async -> XtreamClient {
        let session = await MainActor.run {
            makeSession(stubs: stubs)
        }
        let configuration = XtreamClient.Configuration(
            baseURL: baseURL ?? defaultBaseURL,
            session: session
        )
        return XtreamClient(configuration: configuration)
    }

    static func makeSession(stubs: [StubURLProtocol.Stub]) async -> Session {
        await MainActor.run {
            makeSession(stubs: stubs)
        }
    }
}
