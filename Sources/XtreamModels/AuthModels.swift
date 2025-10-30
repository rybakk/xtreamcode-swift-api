import Foundation

public struct XtreamAuthSession: Sendable, Decodable {
    public let username: String
    public let status: SubscriptionStatus
    public let expirationDate: Date?
    public let isTrial: Bool
    public let activeConnections: Int
    public let maxConnections: Int
    public let allowedOutputFormats: [String]

    public init(
        username: String,
        status: SubscriptionStatus,
        expirationDate: Date?,
        isTrial: Bool,
        activeConnections: Int,
        maxConnections: Int,
        allowedOutputFormats: [String]
    ) {
        self.username = username
        self.status = status
        self.expirationDate = expirationDate
        self.isTrial = isTrial
        self.activeConnections = activeConnections
        self.maxConnections = maxConnections
        self.allowedOutputFormats = allowedOutputFormats
    }
}

public enum SubscriptionStatus: String, Sendable, Decodable {
    case active = "Active"
    case disabled = "Disabled"
    case expired = "Expired"
    case other

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SubscriptionStatus(rawValue: rawValue) ?? .other
    }
}

public struct XtreamServerInfo: Sendable, Decodable {
    public let url: String
    public let port: String
    public let httpsPort: String
    public let serverProtocol: String
    public let timezone: String?
    public let timestampNow: Int?
}

public struct XtreamAccountInfoResponse: Sendable, Decodable {
    public let userInfo: RawUserInfo
    public let serverInfo: XtreamServerInfo

    public struct RawUserInfo: Sendable, Decodable {
        public let username: String
        public let password: String
        public let auth: Int
        public let status: SubscriptionStatus
        public let expDate: String?
        public let isTrial: String
        public let activeCons: String
        public let createdAt: String?
        public let maxConnections: String
        public let allowedOutputFormats: [String]
        public let message: String?
    }
}
