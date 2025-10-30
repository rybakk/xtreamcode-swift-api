import Foundation

public struct XtreamAccountDetails: Sendable {
    public let session: XtreamAuthSession
    public let serverInfo: XtreamServerInfo

    public init(session: XtreamAuthSession, serverInfo: XtreamServerInfo) {
        self.session = session
        self.serverInfo = serverInfo
    }
}

public extension XtreamAuthSession {
    init(from userInfo: PlayerAPIResponse.UserInfo) {
        self.init(
            username: userInfo.username,
            status: userInfo.status,
            expirationDate: XtreamMapping.date(from: userInfo.expDate),
            isTrial: XtreamMapping.bool(from: userInfo.isTrial),
            activeConnections: XtreamMapping.integer(from: userInfo.activeCons),
            maxConnections: XtreamMapping.integer(from: userInfo.maxConnections, default: 1),
            allowedOutputFormats: userInfo.allowedOutputFormats
        )
    }

    init(from raw: XtreamAccountInfoResponse.RawUserInfo) {
        self.init(
            username: raw.username,
            status: raw.status,
            expirationDate: XtreamMapping.date(from: raw.expDate),
            isTrial: XtreamMapping.bool(from: raw.isTrial),
            activeConnections: XtreamMapping.integer(from: raw.activeCons),
            maxConnections: XtreamMapping.integer(from: raw.maxConnections, default: 1),
            allowedOutputFormats: raw.allowedOutputFormats
        )
    }
}
