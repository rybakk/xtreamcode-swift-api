import Foundation
#if canImport(XtreamClient)
import XtreamClient
#endif
#if canImport(XtreamModels)
import XtreamModels
#endif

public protocol XtreamAuthServicing {
    func login(credentials: XtreamCredentials) async throws -> XtreamAuthSession
    func refreshSession(credentials: XtreamCredentials) async throws -> XtreamAuthSession
    func logout()
}

public final class XtreamAuthService: XtreamAuthServicing {
    private let client: XtreamClient

    public init(client: XtreamClient) {
        self.client = client
    }

    public func login(credentials: XtreamCredentials) async throws -> XtreamAuthSession {
        do {
            let response: PlayerAPIResponse = try await client.request(.login(), credentials: credentials)
            return XtreamAuthSession(from: response.userInfo)
        } catch {
            throw map(error: error)
        }
    }

    public func refreshSession(credentials: XtreamCredentials) async throws -> XtreamAuthSession {
        try await login(credentials: credentials)
    }

    public func logout() {}

    private func map(error: Error) -> Error {
        guard let clientError = error as? XtreamClientError else {
            return error
        }

        switch clientError {
        case let .unauthorized(data):
            if let data, let authError = decodeAuthError(from: data) {
                return authError
            }
            return XtreamAuthError.unauthorized(message: nil)
        default:
            return XtreamAuthError.client(clientError)
        }
    }

    private func decodeAuthError(from data: Data) -> XtreamAuthError? {
        let decoder = XtreamClient.makeDefaultDecoder()
        guard let response = try? decoder.decode(PlayerAPIResponse.self, from: data) else {
            return nil
        }

        let userInfo = response.userInfo
        let message = userInfo.message
        let expiration = XtreamMapping.date(from: userInfo.expDate)
        let active = XtreamMapping.integer(from: userInfo.activeCons)
        let max = XtreamMapping.integer(from: userInfo.maxConnections, default: 0)

        if userInfo.status == SubscriptionStatus.expired {
            return .accountExpired(expiration: expiration)
        }

        if max > 0 && active >= max {
            return .tooManyConnections(active: active, max: max)
        }

        if userInfo.auth == 0 || userInfo.status == SubscriptionStatus.disabled {
            return .invalidCredentials(message: message)
        }

        return .unauthorized(message: message)
    }
}
