import Foundation

// MARK: - Series Category

public struct XtreamSeriesCategory: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let parentID: Int?

    public init(id: String, name: String, parentID: Int?) {
        self.id = id
        self.name = name
        self.parentID = parentID
    }
}

public struct XtreamSeriesCategoryResponse: Sendable, Decodable {
    public let categoryID: String
    public let categoryName: String
    public let parentID: String?

    private enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case categoryName = "category_name"
        case parentID = "parent_id"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.categoryID = try container.decode(String.self, forKey: .categoryID)
        self.categoryName = try container.decode(String.self, forKey: .categoryName)

        if let stringValue = try? container.decode(String.self, forKey: .parentID) {
            self.parentID = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: .parentID) {
            self.parentID = String(intValue)
        } else {
            self.parentID = nil
        }
    }
}

public extension XtreamSeriesCategory {
    init(from response: XtreamSeriesCategoryResponse) {
        self.init(
            id: response.categoryID,
            name: response.categoryName,
            parentID: Int(response.parentID ?? "")
        )
    }
}

// MARK: - Series

public struct XtreamSeries: Codable, Sendable, Equatable, Hashable {
    public let num: Int?
    public let name: String
    public let streamType: String?
    public let seriesID: Int
    public let cover: String?
    public let plot: String?
    public let cast: String?
    public let director: String?
    public let genre: String?
    public let releaseDate: String?
    public let lastModified: String?
    public let rating: String?
    public let rating5Based: Double?
    public let backdropPath: [String]?
    public let youtubeTrailer: String?
    public let episodeRunTime: String?
    public let categoryID: String?

    public init(
        num: Int?,
        name: String,
        streamType: String?,
        seriesID: Int,
        cover: String?,
        plot: String?,
        cast: String?,
        director: String?,
        genre: String?,
        releaseDate: String?,
        lastModified: String?,
        rating: String?,
        rating5Based: Double?,
        backdropPath: [String]?,
        youtubeTrailer: String?,
        episodeRunTime: String?,
        categoryID: String?
    ) {
        self.num = num
        self.name = name
        self.streamType = streamType
        self.seriesID = seriesID
        self.cover = cover
        self.plot = plot
        self.cast = cast
        self.director = director
        self.genre = genre
        self.releaseDate = releaseDate
        self.lastModified = lastModified
        self.rating = rating
        self.rating5Based = rating5Based
        self.backdropPath = backdropPath
        self.youtubeTrailer = youtubeTrailer
        self.episodeRunTime = episodeRunTime
        self.categoryID = categoryID
    }
}

public struct XtreamSeriesResponse: Sendable, Decodable {
    public let num: Int?
    public let name: String
    public let streamType: String?
    public let seriesID: Int
    public let cover: String?
    public let plot: String?
    public let cast: String?
    public let director: String?
    public let genre: String?
    public let releaseDate: String?
    public let lastModified: String?
    public let rating: String?
    public let rating5Based: Double?
    public let backdropPath: BackdropPathValue?
    public let youtubeTrailer: String?
    public let episodeRunTime: String?
    public let categoryID: String?

    private enum CodingKeys: String, CodingKey {
        case num
        case name
        case streamType = "stream_type"
        case seriesID = "series_id"
        case cover
        case plot
        case cast
        case director
        case genre
        case releaseDate
        case lastModified = "last_modified"
        case rating
        case rating5Based = "rating_5based"
        case backdropPath = "backdrop_path"
        case youtubeTrailer = "youtube_trailer"
        case episodeRunTime = "episode_run_time"
        case categoryID = "category_id"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.num = try container.decodeIfPresent(Int.self, forKey: .num)
        self.name = try container.decode(String.self, forKey: .name)
        self.streamType = try container.decodeIfPresent(String.self, forKey: .streamType)
        self.seriesID = try container.decode(Int.self, forKey: .seriesID)
        self.cover = try container.decodeIfPresent(String.self, forKey: .cover)
        self.plot = try container.decodeIfPresent(String.self, forKey: .plot)
        self.cast = try container.decodeIfPresent(String.self, forKey: .cast)
        self.director = try container.decodeIfPresent(String.self, forKey: .director)
        self.genre = try container.decodeIfPresent(String.self, forKey: .genre)
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        self.lastModified = try container.decodeIfPresent(String.self, forKey: .lastModified)

        // Handle rating - API may return String or numeric value
        if let stringValue = try? container.decode(String.self, forKey: .rating) {
            self.rating = stringValue
        } else if let doubleValue = try? container.decode(Double.self, forKey: .rating) {
            self.rating = String(doubleValue)
        } else if let intValue = try? container.decode(Int.self, forKey: .rating) {
            self.rating = String(intValue)
        } else {
            self.rating = nil
        }

        self.rating5Based = try container.decodeIfPresent(Double.self, forKey: .rating5Based)
        self.backdropPath = try container.decodeIfPresent(BackdropPathValue.self, forKey: .backdropPath)
        self.youtubeTrailer = try container.decodeIfPresent(String.self, forKey: .youtubeTrailer)
        self.episodeRunTime = try container.decodeIfPresent(String.self, forKey: .episodeRunTime)
        self.categoryID = try container.decodeIfPresent(String.self, forKey: .categoryID)
    }

    public enum BackdropPathValue: Decodable, Sendable {
        case array([String])
        case string(String)
        case empty

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let array = try? container.decode([String].self) {
                self = .array(array)
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else {
                self = .empty
            }
        }
    }
}

public extension XtreamSeries {
    init(from response: XtreamSeriesResponse) {
        let backdropArray: [String]? = {
            guard let value = response.backdropPath else { return nil }
            switch value {
            case let .array(array):
                return array
            case let .string(string):
                return string.isEmpty ? nil : [string]
            case .empty:
                return nil
            }
        }()

        self.init(
            num: response.num,
            name: response.name,
            streamType: response.streamType,
            seriesID: response.seriesID,
            cover: response.cover,
            plot: response.plot,
            cast: response.cast,
            director: response.director,
            genre: response.genre,
            releaseDate: response.releaseDate,
            lastModified: response.lastModified,
            rating: response.rating,
            rating5Based: response.rating5Based,
            backdropPath: backdropArray,
            youtubeTrailer: response.youtubeTrailer,
            episodeRunTime: response.episodeRunTime,
            categoryID: response.categoryID
        )
    }
}

// MARK: - Series Info (Detailed with Seasons/Episodes)
