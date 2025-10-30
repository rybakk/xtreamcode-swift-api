import Foundation

/// Credentials used to authenticate against Xtream Codes endpoints.
public struct XtreamCredentials: Sendable {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}
