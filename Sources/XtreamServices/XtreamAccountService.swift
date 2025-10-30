import XtreamClient
import XtreamModels

public protocol XtreamAccountServicing {
    func fetchAccountDetails(credentials: XtreamCredentials) async throws -> XtreamAccountDetails
}

public final class XtreamAccountService: XtreamAccountServicing {
    private let client: XtreamClient

    public init(client: XtreamClient) {
        self.client = client
    }

    public func fetchAccountDetails(credentials: XtreamCredentials) async throws -> XtreamAccountDetails {
        let response: XtreamAccountInfoResponse = try await client.request(.accountInfo(), credentials: credentials)
        let session = XtreamAuthSession(from: response.userInfo)
        return XtreamAccountDetails(session: session, serverInfo: response.serverInfo)
    }
}
