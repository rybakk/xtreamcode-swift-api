import Foundation

// MARK: - VOD Category

public struct XtreamVODCategory: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let parentID: Int?

    public init(id: String, name: String, parentID: Int?) {
        self.id = id
        self.name = name
        self.parentID = parentID
    }
}

public struct XtreamVODCategoryResponse: Sendable, Decodable {
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

public extension XtreamVODCategory {
    init(from response: XtreamVODCategoryResponse) {
        self.init(
            id: response.categoryID,
            name: response.categoryName,
            parentID: Int(response.parentID ?? "")
        )
    }
}

// MARK: - VOD Stream

public struct XtreamVODStream: Codable, Sendable, Equatable, Hashable {
    public let num: Int?
    public let name: String
    public let streamType: String?
    public let streamID: Int
    public let streamIcon: String?
    public let rating: String?
    public let rating5Based: Double?
    public let added: String?
    public let categoryID: String?
    public let containerExtension: String?
    public let customSID: String?
    public let directSource: String?

    public init(
        num: Int?,
        name: String,
        streamType: String?,
        streamID: Int,
        streamIcon: String?,
        rating: String?,
        rating5Based: Double?,
        added: String?,
        categoryID: String?,
        containerExtension: String?,
        customSID: String?,
        directSource: String?
    ) {
        self.num = num
        self.name = name
        self.streamType = streamType
        self.streamID = streamID
        self.streamIcon = streamIcon
        self.rating = rating
        self.rating5Based = rating5Based
        self.added = added
        self.categoryID = categoryID
        self.containerExtension = containerExtension
        self.customSID = customSID
        self.directSource = directSource
    }
}

public struct XtreamVODStreamResponse: Sendable, Decodable {
    public let num: Int?
    public let name: String
    public let streamType: String?
    public let streamID: Int
    public let streamIcon: String?
    public let rating: String?
    public let rating5Based: Double?
    public let added: String?
    public let categoryID: String?
    public let containerExtension: String?
    public let customSID: String?
    public let directSource: String?

    private enum CodingKeys: String, CodingKey {
        case num
        case name
        case streamType = "stream_type"
        case streamID = "stream_id"
        case streamIcon = "stream_icon"
        case rating
        case rating5Based = "rating_5based"
        case added
        case categoryID = "category_id"
        case containerExtension = "container_extension"
        case customSID = "custom_sid"
        case directSource = "direct_source"
    }
}

public extension XtreamVODStream {
    init(from response: XtreamVODStreamResponse) {
        self.init(
            num: response.num,
            name: response.name,
            streamType: response.streamType,
            streamID: response.streamID,
            streamIcon: response.streamIcon,
            rating: response.rating,
            rating5Based: response.rating5Based,
            added: response.added,
            categoryID: response.categoryID,
            containerExtension: response.containerExtension,
            customSID: response.customSID,
            directSource: response.directSource
        )
    }
}

// MARK: - VOD Info (Detailed)

public struct XtreamVODInfo: Codable, Sendable, Equatable {
    public let info: XtreamVODMovieInfo?
    public let movieData: XtreamVODMovieData?

    public init(info: MovieInfo?, movieData: MovieData?) {
        self.info = info
        self.movieData = movieData
    }

    private enum CodingKeys: String, CodingKey {
        case info
        case movieData = "movie_data"
    }
}

public struct XtreamVODMovieInfo: Codable, Sendable, Equatable {
    public let movieImage: String?
    public let tmdbID: String?
    public let name: String?
    public let releaseDate: String?
    public let youtubeTrailer: String?
    public let director: String?
    public let actors: String?
    public let cast: String?
    public let description: String?
    public let plot: String?
    public let age: String?
    public let country: String?
    public let genre: String?
    public let backdropPath: [String]?
    public let duration: String?
    public let durationSecs: Int?
    public let video: XtreamVODCodecInfo?
    public let audio: XtreamVODCodecInfo?
    public let rating: String?
    public let rating5Based: Double?

    public init(
        movieImage: String?,
        tmdbID: String?,
        name: String?,
        releaseDate: String?,
        youtubeTrailer: String?,
        director: String?,
        actors: String?,
        cast: String?,
        description: String?,
        plot: String?,
        age: String?,
        country: String?,
        genre: String?,
        backdropPath: [String]?,
        duration: String?,
        durationSecs: Int?,
        video: XtreamVODCodecInfo?,
        audio: XtreamVODCodecInfo?,
        rating: String?,
        rating5Based: Double?
    ) {
        self.movieImage = movieImage
        self.tmdbID = tmdbID
        self.name = name
        self.releaseDate = releaseDate
        self.youtubeTrailer = youtubeTrailer
        self.director = director
        self.actors = actors
        self.cast = cast
        self.description = description
        self.plot = plot
        self.age = age
        self.country = country
        self.genre = genre
        self.backdropPath = backdropPath
        self.duration = duration
        self.durationSecs = durationSecs
        self.video = video
        self.audio = audio
        self.rating = rating
        self.rating5Based = rating5Based
    }

    private enum CodingKeys: String, CodingKey {
        case movieImage = "movie_image"
        case tmdbID = "tmdb_id"
        case name
        case releaseDate = "releasedate"
        case youtubeTrailer = "youtube_trailer"
        case director
        case actors
        case cast
        case description
        case plot
        case age
        case country
        case genre
        case backdropPath = "backdrop_path"
        case duration
        case durationSecs = "duration_secs"
        case video
        case audio
        case rating
        case rating5Based = "rating_5based"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        movieImage = try container.decodeIfPresent(String.self, forKey: .movieImage)
        tmdbID = try container.decodeIfPresent(String.self, forKey: .tmdbID)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        youtubeTrailer = try container.decodeIfPresent(String.self, forKey: .youtubeTrailer)
        director = try container.decodeIfPresent(String.self, forKey: .director)
        actors = try container.decodeIfPresent(String.self, forKey: .actors)
        cast = try container.decodeIfPresent(String.self, forKey: .cast)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        plot = try container.decodeIfPresent(String.self, forKey: .plot)
        age = try container.decodeIfPresent(String.self, forKey: .age)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
        backdropPath = try container.decodeIfPresent([String].self, forKey: .backdropPath)
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        durationSecs = try container.decodeIfPresent(Int.self, forKey: .durationSecs)
        video = XtreamVODMovieInfo.decodeCodec(from: container, key: .video)
        audio = XtreamVODMovieInfo.decodeCodec(from: container, key: .audio)
        rating = try container.decodeIfPresent(String.self, forKey: .rating)
        rating5Based = try container.decodeIfPresent(Double.self, forKey: .rating5Based)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(movieImage, forKey: .movieImage)
        try container.encodeIfPresent(tmdbID, forKey: .tmdbID)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(releaseDate, forKey: .releaseDate)
        try container.encodeIfPresent(youtubeTrailer, forKey: .youtubeTrailer)
        try container.encodeIfPresent(director, forKey: .director)
        try container.encodeIfPresent(actors, forKey: .actors)
        try container.encodeIfPresent(cast, forKey: .cast)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(plot, forKey: .plot)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(country, forKey: .country)
        try container.encodeIfPresent(genre, forKey: .genre)
        try container.encodeIfPresent(backdropPath, forKey: .backdropPath)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(durationSecs, forKey: .durationSecs)
        try container.encodeIfPresent(video, forKey: .video)
        try container.encodeIfPresent(audio, forKey: .audio)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(rating5Based, forKey: .rating5Based)
    }

    private static func decodeCodec(
        from container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> XtreamVODCodecInfo? {
        if let codec = try? container.decode(XtreamVODCodecInfo.self, forKey: key) {
            return codec
        }
        _ = try? container.decode(String.self, forKey: key)
        return nil
    }
}

public struct XtreamVODMovieData: Codable, Sendable, Equatable {
    public let streamID: Int?
    public let name: String?
    public let added: String?
    public let categoryID: String?
    public let containerExtension: String?
    public let customSID: String?
    public let directSource: String?

    public init(
        streamID: Int?,
        name: String?,
        added: String?,
        categoryID: String?,
        containerExtension: String?,
        customSID: String?,
        directSource: String?
    ) {
        self.streamID = streamID
        self.name = name
        self.added = added
        self.categoryID = categoryID
        self.containerExtension = containerExtension
        self.customSID = customSID
        self.directSource = directSource
    }

    private enum CodingKeys: String, CodingKey {
        case streamID = "stream_id"
        case name
        case added
        case categoryID = "category_id"
        case containerExtension = "container_extension"
        case customSID = "custom_sid"
        case directSource = "direct_source"
    }
}

public extension XtreamVODInfo {
    typealias MovieInfo = XtreamVODMovieInfo
    typealias MovieData = XtreamVODMovieData
}

public struct XtreamVODCodecInfo: Codable, Sendable, Equatable {
    public let index: Int?
    public let codecName: String?
    public let codecLongName: String?
    public let profile: String?
    public let codecType: String?
    public let width: Int?
    public let height: Int?
    public let bitrate: Int?

    public init(
        index: Int?,
        codecName: String?,
        codecLongName: String?,
        profile: String?,
        codecType: String?,
        width: Int?,
        height: Int?,
        bitrate: Int?
    ) {
        self.index = index
        self.codecName = codecName
        self.codecLongName = codecLongName
        self.profile = profile
        self.codecType = codecType
        self.width = width
        self.height = height
        self.bitrate = bitrate
    }

    private enum CodingKeys: String, CodingKey {
        case index
        case codecName = "codec_name"
        case codecLongName = "codec_long_name"
        case profile
        case codecType = "codec_type"
        case width
        case height
        case bitrate
    }
}
