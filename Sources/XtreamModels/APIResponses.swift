import Foundation

public struct PlayerAPIResponse: Sendable, Decodable {
    public let userInfo: UserInfo
    public let serverInfo: XtreamServerInfo

    public struct UserInfo: Sendable, Decodable {
        public let username: String
        public let status: SubscriptionStatus
        public let expDate: FlexibleString?
        public let isTrial: FlexibleString
        public let activeCons: FlexibleString
        public let maxConnections: FlexibleString
        public let allowedOutputFormats: [String]
        public let auth: Int
        public let createdAt: FlexibleString?
        public let message: String?
    }
}
