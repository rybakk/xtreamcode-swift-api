import XCTest
import XtreamModels
@testable import XtreamSDKFacade

#if canImport(Combine)
    import Combine
#endif

final class XtreamAPIBridgeTests: XCTestCase {
    private let credentials = XtreamCredentials(username: "demo", password: "secret")
    private let baseURL: URL = {
        guard let url = URL(string: "https://sanitized.example") else {
            fatalError("Invalid URL")
        }
        return url
    }()

    #if canImport(Combine)
        private var cancellables: Set<AnyCancellable> = []

        override func tearDown() {
            cancellables.removeAll()
            super.tearDown()
        }
    #endif

    func testLiveStreamsCompletionBridgeReturnsValue() async throws {
        let data = try TestFixtures.data(named: "live_streams_tnt_sample")
        let stub = StubURLProtocol.Stub.playerAPI(
            baseURL: baseURL,
            action: "get_live_streams",
            data: data,
            componentsMatcher: { components in
                components.queryItems?.first(where: { $0.name == "category_id" })?.value == "6"
            }
        )

        let session = await TestClientFactory.makeSession(stubs: [stub])
        let api = XtreamcodeSwiftAPI(
            configuration: .init(
                baseURL: baseURL,
                credentials: credentials,
                session: session
            )
        )

        let expectation = expectation(description: "Completion called")
        let task = api.liveStreams(in: "6") { result in
            switch result {
            case let .success(streams):
                XCTAssertEqual(streams.count, 5)
                XCTAssertEqual(streams.first?.id, 22375)
            case let .failure(error):
                XCTFail("Unexpected error \(error)")
            }
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        task.cancel()
    }

    #if canImport(Combine)
        func testLiveCategoriesPublisherEmitsValues() async throws {
            let data = try TestFixtures.data(named: "live_categories_tnt_sample")
            let stub = StubURLProtocol.Stub.playerAPI(
                baseURL: baseURL,
                action: "get_live_categories",
                data: data
            )

            let session = await TestClientFactory.makeSession(stubs: [stub])
            let api = XtreamcodeSwiftAPI(
                configuration: .init(
                    baseURL: baseURL,
                    credentials: credentials,
                    session: session
                )
            )

            let expectation = expectation(description: "Publisher emits categories")

            api.liveCategoriesPublisher()
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            XCTFail("Unexpected error \(error)")
                        }
                    },
                    receiveValue: { categories in
                        XCTAssertEqual(categories.count, 6)
                        XCTAssertEqual(categories.first?.name, "USA")
                        expectation.fulfill()
                    }
                )
                .store(in: &cancellables)

            await fulfillment(of: [expectation], timeout: 1.0)
        }
    #endif
}
