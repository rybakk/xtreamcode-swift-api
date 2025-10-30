import Foundation

public struct PlayerAPIResponse: Sendable, Decodable {
    public let userInfo: UserInfo
    public let serverInfo: XtreamServerInfo

    public struct UserInfo: Sendable, Decodable {
        public let username: String
        public let status: SubscriptionStatus
        public let expDate: String?
        public let isTrial: String
        public let activeCons: String
        public let maxConnections: String
        public let allowedOutputFormats: [String]
        public let auth: Int
        public let createdAt: String?
        public let message: String?
    }
}
