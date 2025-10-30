import Foundation

public struct XtreamEPGEntry: Codable, Sendable, Equatable {
    public let id: String
    public let epgID: String?
    public let title: String
    public let language: String?
    public let description: String?
    public let channelID: String?
    public let startDate: Date?
    public let endDate: Date?

    public init(
        id: String,
        epgID: String?,
        title: String,
        language: String?,
        description: String?,
        channelID: String?,
        startDate: Date?,
        endDate: Date?
    ) {
        self.id = id
        self.epgID = epgID
        self.title = title
        self.language = language
        self.description = description
        self.channelID = channelID
        self.startDate = startDate
        self.endDate = endDate
    }

    public var decodedTitle: String? {
        guard let data = Data(base64Encoded: title) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public var decodedDescription: String? {
        guard let description, let data = Data(base64Encoded: description) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

public struct XtreamEPGResponse: Sendable, Decodable {
    public let epgListings: [XtreamEPGListing]

    private enum CodingKeys: String, CodingKey {
        case epgListings = "epg_listings"
    }
}

public struct XtreamEPGListing: Sendable, Decodable {
    public let id: String
    public let epgID: String?
    public let title: String
    public let lang: String?
    public let description: String?
    public let channelID: String?
    public let startTimestamp: String?
    public let stopTimestamp: String?
    public let start: String?
    public let end: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case epgID = "epg_id"
        case title
        case lang
        case description
        case channelID = "channel_id"
        case startTimestamp = "start_timestamp"
        case stopTimestamp = "stop_timestamp"
        case start
        case end
    }
}

public extension XtreamEPGEntry {
    init(from listing: XtreamEPGListing) {
        let startDate = XtreamMapping.date(from: listing.startTimestamp)
            ?? XtreamMapping.portalDate(from: listing.start)
        let endDate = XtreamMapping.date(from: listing.stopTimestamp)
            ?? XtreamMapping.portalDate(from: listing.end)

        self.init(
            id: listing.id,
            epgID: listing.epgID,
            title: listing.title,
            language: listing.lang,
            description: listing.description,
            channelID: listing.channelID,
            startDate: startDate,
            endDate: endDate
        )
    }
}
