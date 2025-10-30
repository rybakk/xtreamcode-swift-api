import Foundation

// MARK: - Search Result

public enum XtreamSearchResultType: String, Codable, Sendable, Equatable {
    case live
    case movie
    case series

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self).lowercased()
        self = XtreamSearchResultType(rawValue: rawValue) ?? .live
    }
}

public struct XtreamSearchResult: Codable, Sendable, Equatable {
    public let type: XtreamSearchResultType
    public let id: Int
    public let name: String
    public let categoryID: String?
    public let streamIcon: String?
    public let cover: String?
    public let rating: String?

    public init(
        type: XtreamSearchResultType,
        id: Int,
        name: String,
        categoryID: String?,
        streamIcon: String?,
        cover: String?,
        rating: String?
    ) {
        self.type = type
        self.id = id
        self.name = name
        self.categoryID = categoryID
        self.streamIcon = streamIcon
        self.cover = cover
        self.rating = rating
    }
}

public struct XtreamSearchResultResponse: Sendable, Decodable {
    public let streamType: String?
    public let streamID: Int?
    public let seriesID: Int?
    public let vodID: Int?
    public let name: String
    public let categoryID: String?
    public let streamIcon: String?
    public let cover: String?
    public let rating: String?

    private enum CodingKeys: String, CodingKey {
        case streamType = "stream_type"
        case streamID = "stream_id"
        case seriesID = "series_id"
        case vodID = "vod_id"
        case name
        case categoryID = "category_id"
        case streamIcon = "stream_icon"
        case cover
        case rating
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.streamType = try? container.decode(String.self, forKey: .streamType)
        self.streamID = try? container.decode(Int.self, forKey: .streamID)
        self.seriesID = try? container.decode(Int.self, forKey: .seriesID)
        self.vodID = try? container.decode(Int.self, forKey: .vodID)
        self.name = try container.decode(String.self, forKey: .name)
        self.categoryID = try? container.decode(String.self, forKey: .categoryID)
        self.streamIcon = try? container.decode(String.self, forKey: .streamIcon)
        self.cover = try? container.decode(String.self, forKey: .cover)
        self.rating = try? container.decode(String.self, forKey: .rating)
    }
}

public extension XtreamSearchResult {
    init(from response: XtreamSearchResultResponse) {
        let resultType: XtreamSearchResultType
        let resultID: Int

        if let seriesID = response.seriesID {
            resultType = .series
            resultID = seriesID
        } else if let vodID = response.vodID, response.streamType == "movie" {
            resultType = .movie
            resultID = vodID
        } else if let streamID = response.streamID {
            resultType = .live
            resultID = streamID
        } else {
            resultType = .live
            resultID = response.streamID ?? 0
        }

        self.init(
            type: resultType,
            id: resultID,
            name: response.name,
            categoryID: response.categoryID,
            streamIcon: response.streamIcon,
            cover: response.cover,
            rating: response.rating
        )
    }
}
