import XCTest
import XtreamModels
@testable import XtreamcodeSwiftAPI

final class ExampleTests: XCTestCase {
    func testAPIInitialization() {
        guard let url = URL(string: "https://example.com") else {
            XCTFail("Invalid URL")
            return
        }
        let credentials = XtreamCredentials(username: "demo", password: "secret")
        let api = XtreamcodeSwiftAPI(baseURL: url, credentials: credentials)
        XCTAssertNotNil(api)
        api.updateCredentials(credentials)
    }
}
