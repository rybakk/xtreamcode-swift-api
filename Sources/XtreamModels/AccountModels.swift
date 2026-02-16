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
            expirationDate: XtreamMapping.date(from: userInfo.expDate?.value),
            isTrial: XtreamMapping.bool(from: userInfo.isTrial.value),
            activeConnections: XtreamMapping.integer(from: userInfo.activeCons.value),
            maxConnections: XtreamMapping.integer(from: userInfo.maxConnections.value, default: 1),
            allowedOutputFormats: userInfo.allowedOutputFormats
        )
    }

    init(from raw: XtreamAccountInfoResponse.RawUserInfo) {
        self.init(
            username: raw.username,
            status: raw.status,
            expirationDate: XtreamMapping.date(from: raw.expDate?.value),
            isTrial: XtreamMapping.bool(from: raw.isTrial.value),
            activeConnections: XtreamMapping.integer(from: raw.activeCons.value),
            maxConnections: XtreamMapping.integer(from: raw.maxConnections.value, default: 1),
            allowedOutputFormats: raw.allowedOutputFormats
        )
    }
}
