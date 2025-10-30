import Foundation

public struct XtreamCatchupSegment: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let startDate: Date?
    public let endDate: Date?
    public let duration: TimeInterval?
    public let channelID: String?

    public init(
        id: String,
        title: String,
        startDate: Date?,
        endDate: Date?,
        duration: TimeInterval?,
        channelID: String?
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.channelID = channelID
    }
}

public struct XtreamCatchupCollection: Codable, Sendable, Equatable {
    public let streamID: Int
    public let streamName: String?
    public let number: Int?
    public let isCatchupEnabled: Bool
    public let archiveDurationHours: Int?
    public let archiveDays: Int?
    public let segments: [XtreamCatchupSegment]

    public init(
        streamID: Int,
        streamName: String?,
        number: Int?,
        isCatchupEnabled: Bool,
        archiveDurationHours: Int?,
        archiveDays: Int?,
        segments: [XtreamCatchupSegment]
    ) {
        self.streamID = streamID
        self.streamName = streamName
        self.number = number
        self.isCatchupEnabled = isCatchupEnabled
        self.archiveDurationHours = archiveDurationHours
        self.archiveDays = archiveDays
        self.segments = segments
    }
}

public struct XtreamCatchupResponse: Sendable, Decodable {
    public let streamID: Int
    public let streamDisplayName: String?
    public let num: String?
    public let tvArchive: String?
    public let tvArchiveDuration: String?
    public let tvArchiveDays: String?
    public let entries: [XtreamCatchupEntry]

    private enum CodingKeys: String, CodingKey {
        case streamID = "stream_id"
        case streamDisplayName = "stream_display_name"
        case num
        case tvArchive = "tv_archive"
        case tvArchiveDuration = "tv_archive_duration"
        case tvArchiveDays = "tv_archive_days"
        case entries
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.streamID = try container.decode(Int.self, forKey: .streamID)
        self.streamDisplayName = try? container.decode(String.self, forKey: .streamDisplayName)

        if let numInt = try? container.decode(Int.self, forKey: .num) {
            self.num = String(numInt)
        } else {
            self.num = try? container.decode(String.self, forKey: .num)
        }

        if let archiveInt = try? container.decode(Int.self, forKey: .tvArchive) {
            self.tvArchive = String(archiveInt)
        } else {
            self.tvArchive = try? container.decode(String.self, forKey: .tvArchive)
        }

        if let durationInt = try? container.decode(Int.self, forKey: .tvArchiveDuration) {
            self.tvArchiveDuration = String(durationInt)
        } else {
            self.tvArchiveDuration = try? container.decode(String.self, forKey: .tvArchiveDuration)
        }

        if let daysInt = try? container.decode(Int.self, forKey: .tvArchiveDays) {
            self.tvArchiveDays = String(daysInt)
        } else {
            self.tvArchiveDays = try? container.decode(String.self, forKey: .tvArchiveDays)
        }

        self.entries = try container.decode([XtreamCatchupEntry].self, forKey: .entries)
    }
}

public struct XtreamCatchupEntry: Sendable, Decodable {
    public let id: String
    public let title: String
    public let start: String?
    public let end: String?
    public let duration: Double?
    public let channelID: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case start
        case end
        case duration
        case channelID = "channel_id"
    }
}

public extension XtreamCatchupCollection {
    init(from response: XtreamCatchupResponse) {
        let segments = response.entries.map { entry -> XtreamCatchupSegment in
            let startDate = XtreamMapping.portalDate(from: entry.start)
            let endDate = XtreamMapping.portalDate(from: entry.end)
            return XtreamCatchupSegment(
                id: entry.id,
                title: entry.title,
                startDate: startDate,
                endDate: endDate,
                duration: entry.duration,
                channelID: entry.channelID
            )
        }

        self.init(
            streamID: response.streamID,
            streamName: response.streamDisplayName,
            number: XtreamMapping.optionalInteger(from: response.num),
            isCatchupEnabled: XtreamMapping.bool(from: response.tvArchive, truthyValues: ["1", "true", "TRUE"]),
            archiveDurationHours: {
                let value = XtreamMapping.optionalInteger(from: response.tvArchiveDuration)
                return value == 0 ? nil : value
            }(),
            archiveDays: {
                let value = XtreamMapping.optionalInteger(from: response.tvArchiveDays)
                return value == 0 ? nil : value
            }(),
            segments: segments
        )
    }
}
