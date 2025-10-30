import Foundation

public struct XtreamLiveStream: Codable, Sendable, Equatable {
    public enum StreamType: String, Sendable, Codable {
        case live
        case createdLive = "created_live"
        case other

        public init(rawValue: String) {
            switch rawValue.lowercased() {
            case "live":
                self = .live
            case "created_live":
                self = .createdLive
            default:
                self = .other
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self.init(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.rawValue)
        }
    }

    public let id: Int
    public let number: Int?
    public let name: String
    public let categoryID: String
    public let type: StreamType
    public let iconPath: String?
    public let epgChannelID: String?
    public let addedAt: Date?
    public let customSID: String?
    public let hasCatchup: Bool
    public let catchupDurationHours: Int?

    public init(
        id: Int,
        number: Int?,
        name: String,
        categoryID: String,
        type: StreamType,
        iconPath: String?,
        epgChannelID: String?,
        addedAt: Date?,
        customSID: String?,
        hasCatchup: Bool,
        catchupDurationHours: Int?
    ) {
        self.id = id
        self.number = number
        self.name = name
        self.categoryID = categoryID
        self.type = type
        self.iconPath = iconPath
        self.epgChannelID = epgChannelID
        self.addedAt = addedAt
        self.customSID = customSID
        self.hasCatchup = hasCatchup
        self.catchupDurationHours = catchupDurationHours
    }
}

public struct XtreamLiveStreamResponse: Sendable, Decodable {
    public let num: String?
    public let name: String
    public let streamType: String
    public let streamID: Int
    public let streamIcon: String?
    public let epgChannelID: String?
    public let added: String?
    public let categoryID: String
    public let customSID: String?
    public let tvArchive: String?
    public let tvArchiveDuration: String?

    private enum CodingKeys: String, CodingKey {
        case num
        case name
        case streamType = "stream_type"
        case streamID = "stream_id"
        case streamIcon = "stream_icon"
        case epgChannelID = "epg_channel_id"
        case added
        case categoryID = "category_id"
        case customSID = "custom_sid"
        case tvArchive = "tv_archive"
        case tvArchiveDuration = "tv_archive_duration"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intValue = try? container.decode(Int.self, forKey: .num) {
            self.num = String(intValue)
        } else {
            self.num = try? container.decode(String.self, forKey: .num)
        }
        self.name = try container.decode(String.self, forKey: .name)
        self.streamType = try container.decode(String.self, forKey: .streamType)
        self.streamID = try container.decode(Int.self, forKey: .streamID)
        self.streamIcon = try? container.decode(String.self, forKey: .streamIcon)
        self.epgChannelID = try? container.decode(String.self, forKey: .epgChannelID)
        self.added = try? container.decode(String.self, forKey: .added)
        self.categoryID = try container.decode(String.self, forKey: .categoryID)
        self.customSID = try? container.decode(String.self, forKey: .customSID)
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
    }
}

public extension XtreamLiveStream {
    init(from response: XtreamLiveStreamResponse) {
        let numberValue = XtreamMapping.optionalInteger(from: response.num)
        let durationValue = XtreamMapping.optionalInteger(from: response.tvArchiveDuration)

        self.init(
            id: response.streamID,
            number: numberValue,
            name: response.name,
            categoryID: response.categoryID,
            type: StreamType(rawValue: response.streamType),
            iconPath: response.streamIcon,
            epgChannelID: response.epgChannelID,
            addedAt: XtreamMapping.date(from: response.added),
            customSID: response.customSID,
            hasCatchup: XtreamMapping.bool(from: response.tvArchive, truthyValues: ["1", "true", "TRUE"]),
            catchupDurationHours: durationValue == 0 ? nil : durationValue
        )
    }
}

public struct XtreamLiveStreamURL: Codable, Sendable, Equatable {
    public let quality: String?
    public let containerExtension: String
    public let url: URL

    public init(quality: String?, containerExtension: String, url: URL) {
        self.quality = quality
        self.containerExtension = containerExtension
        self.url = url
    }
}

public struct XtreamLiveURLResponse: Sendable, Decodable {
    public let streamURLs: [XtreamLiveURLFormat]

    private enum CodingKeys: String, CodingKey {
        case streamURLs = "stream_urls"
    }
}

public struct XtreamLiveURLFormat: Sendable, Decodable {
    public let quality: String?
    public let containerExtension: String
    public let playlistURL: String

    private enum CodingKeys: String, CodingKey {
        case quality
        case containerExtension = "container_extension"
        case playlistURL = "playlist_url"
    }
}

public extension XtreamLiveStreamURL {
    init?(from response: XtreamLiveURLFormat) {
        guard let url = URL(string: response.playlistURL) else { return nil }
        self.init(quality: response.quality, containerExtension: response.containerExtension, url: url)
    }
}
