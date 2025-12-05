import Foundation

public struct XtreamSeriesInfo: Codable, Sendable, Equatable {
    public let seasons: [XtreamSeriesInfoSeason]?
    public let info: XtreamSeriesInfoDetail?
    public let episodes: [String: [XtreamSeriesInfoEpisode]]?

    public init(
        seasons: [XtreamSeriesInfoSeason]?,
        info: XtreamSeriesInfoDetail?,
        episodes: [String: [XtreamSeriesInfoEpisode]]?
    ) {
        self.seasons = seasons
        self.info = info
        self.episodes = episodes
    }

    private enum CodingKeys: String, CodingKey {
        case seasons, info, episodes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.seasons = try container.decodeIfPresent([XtreamSeriesInfoSeason].self, forKey: .seasons)
        self.info = try container.decodeIfPresent(XtreamSeriesInfoDetail.self, forKey: .info)

        // Handle episodes: can be either dictionary or array depending on provider
        do {
            let episodesDict = try container.decode([String: [XtreamSeriesInfoEpisode]].self, forKey: .episodes)
            self.episodes = episodesDict
        } catch {
            // Dictionary format failed, try array format
            do {
                let episodesArray = try container.decode([XtreamSeriesInfoEpisode].self, forKey: .episodes)
                var grouped: [String: [XtreamSeriesInfoEpisode]] = [:]
                for episode in episodesArray {
                    let seasonKey = String(episode.season ?? 1)
                    grouped[seasonKey, default: []].append(episode)
                }
                self.episodes = grouped.isEmpty ? nil : grouped
            } catch let arrayError {
                // Both formats failed - log the error for debugging
                print("[XtreamSeriesInfo] Episodes decoding failed:")
                print("  Dictionary error: \(error)")
                print("  Array error: \(arrayError)")
                self.episodes = nil
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(seasons, forKey: .seasons)
        try container.encodeIfPresent(info, forKey: .info)
        try container.encodeIfPresent(episodes, forKey: .episodes)
    }
}

public struct XtreamSeriesInfoSeason: Codable, Sendable, Equatable, Hashable {
    public let airDate: String?
    public let episodeCount: Int?
    public let id: Int?
    public let name: String?
    public let overview: String?
    public let seasonNumber: Int?
    public let cover: String?
    public let coverBig: String?
    public let voteAverage: Double?

    public init(
        airDate: String?,
        episodeCount: Int?,
        id: Int?,
        name: String?,
        overview: String?,
        seasonNumber: Int?,
        cover: String?,
        coverBig: String?,
        voteAverage: Double?
    ) {
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.id = id
        self.name = name
        self.overview = overview
        self.seasonNumber = seasonNumber
        self.cover = cover
        self.coverBig = coverBig
        self.voteAverage = voteAverage
    }

    private enum CodingKeys: String, CodingKey {
        case airDate = "air_date"
        case episodeCount = "episode_count"
        case id
        case name
        case overview
        case seasonNumber = "season_number"
        case cover
        case coverBig = "cover_big"
        case voteAverage = "vote_average"
    }
}

public struct XtreamSeriesInfoEpisode: Codable, Sendable, Equatable, Hashable {
    public let id: String?
    public let episodeNum: Int?
    public let title: String?
    public let containerExtension: String?
    public let info: XtreamSeriesInfoEpisodeInfo?
    public let customSID: String?
    public let added: String?
    public let season: Int?
    public let directSource: String?

    public init(
        id: String?,
        episodeNum: Int?,
        title: String?,
        containerExtension: String?,
        info: XtreamSeriesInfoEpisodeInfo?,
        customSID: String?,
        added: String?,
        season: Int?,
        directSource: String?
    ) {
        self.id = id
        self.episodeNum = episodeNum
        self.title = title
        self.containerExtension = containerExtension
        self.info = info
        self.customSID = customSID
        self.added = added
        self.season = season
        self.directSource = directSource
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case episodeNum = "episode_num"
        case title
        case containerExtension = "container_extension"
        case info
        case customSID = "custom_sid"
        case added
        case season
        case directSource = "direct_source"
    }
}

public struct XtreamSeriesInfoEpisodeInfo: Codable, Sendable, Equatable, Hashable {
    public let tmdbID: Int?
    public let releaseDate: String?
    public let plot: String?
    public let durationSecs: Int?
    public let duration: String?
    public let movieImage: String?
    public let bitrate: Int?
    public let rating: String?
    public let season: Int?
    public let video: XtreamVODCodecInfo?
    public let audio: [XtreamSeriesInfoAudioTrack]?
    public let subtitles: [XtreamSeriesInfoSubtitle]?

    public init(
        tmdbID: Int?,
        releaseDate: String?,
        plot: String?,
        durationSecs: Int?,
        duration: String?,
        movieImage: String?,
        bitrate: Int?,
        rating: String?,
        season: Int?,
        video: XtreamVODCodecInfo?,
        audio: [XtreamSeriesInfoAudioTrack]?,
        subtitles: [XtreamSeriesInfoSubtitle]?
    ) {
        self.tmdbID = tmdbID
        self.releaseDate = releaseDate
        self.plot = plot
        self.durationSecs = durationSecs
        self.duration = duration
        self.movieImage = movieImage
        self.bitrate = bitrate
        self.rating = rating
        self.season = season
        self.video = video
        self.audio = audio
        self.subtitles = subtitles
    }

    private enum CodingKeys: String, CodingKey {
        case tmdbID = "tmdb_id"
        case releaseDate = "releasedate"
        case plot
        case durationSecs = "duration_secs"
        case duration
        case movieImage = "movie_image"
        case bitrate
        case rating
        case season
        case video
        case audio
        case subtitles
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tmdbID = try container.decodeIfPresent(Int.self, forKey: .tmdbID)
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        self.plot = try container.decodeIfPresent(String.self, forKey: .plot)
        self.durationSecs = try container.decodeIfPresent(Int.self, forKey: .durationSecs)
        self.duration = try container.decodeIfPresent(String.self, forKey: .duration)
        self.movieImage = try container.decodeIfPresent(String.self, forKey: .movieImage)
        self.bitrate = try container.decodeIfPresent(Int.self, forKey: .bitrate)

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

        self.season = try container.decodeIfPresent(Int.self, forKey: .season)
        self.video = XtreamSeriesInfoEpisodeInfo.decodeCodec(from: container, key: .video)

        // Handle audio - API may return array or dictionary
        if let audioArray = try? container.decode([XtreamSeriesInfoAudioTrack].self, forKey: .audio) {
            self.audio = audioArray
        } else if let audioDict = try? container.decode([String: XtreamSeriesInfoAudioTrack].self, forKey: .audio) {
            self.audio = Array(audioDict.values)
        } else {
            self.audio = nil
        }

        // Handle subtitles - API may return array or dictionary
        if let subtitlesArray = try? container.decode([XtreamSeriesInfoSubtitle].self, forKey: .subtitles) {
            self.subtitles = subtitlesArray
        } else if let subtitlesDict = try? container.decode([String: XtreamSeriesInfoSubtitle].self, forKey: .subtitles) {
            self.subtitles = Array(subtitlesDict.values)
        } else {
            self.subtitles = nil
        }
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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(tmdbID, forKey: .tmdbID)
        try container.encodeIfPresent(releaseDate, forKey: .releaseDate)
        try container.encodeIfPresent(plot, forKey: .plot)
        try container.encodeIfPresent(durationSecs, forKey: .durationSecs)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(movieImage, forKey: .movieImage)
        try container.encodeIfPresent(bitrate, forKey: .bitrate)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(season, forKey: .season)
        try container.encodeIfPresent(video, forKey: .video)
        try container.encodeIfPresent(audio, forKey: .audio)
        try container.encodeIfPresent(subtitles, forKey: .subtitles)
    }
}

public struct XtreamSeriesInfoAudioTrack: Codable, Sendable, Equatable, Hashable {
    public let language: String?
    public let codec: String?

    public init(language: String?, codec: String?) {
        self.language = language
        self.codec = codec
    }
}

public struct XtreamSeriesInfoSubtitle: Codable, Sendable, Equatable, Hashable {
    public let language: String?
    public let path: String?

    public init(language: String?, path: String?) {
        self.language = language
        self.path = path
    }
}

public struct XtreamSeriesInfoDetail: Codable, Sendable, Equatable {
    public let name: String?
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
        name: String?,
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
        self.name = name
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

    private enum CodingKeys: String, CodingKey {
        case name
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
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
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
        self.backdropPath = try container.decodeIfPresent([String].self, forKey: .backdropPath)
        self.youtubeTrailer = try container.decodeIfPresent(String.self, forKey: .youtubeTrailer)
        self.episodeRunTime = try container.decodeIfPresent(String.self, forKey: .episodeRunTime)
        self.categoryID = try container.decodeIfPresent(String.self, forKey: .categoryID)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(cover, forKey: .cover)
        try container.encodeIfPresent(plot, forKey: .plot)
        try container.encodeIfPresent(cast, forKey: .cast)
        try container.encodeIfPresent(director, forKey: .director)
        try container.encodeIfPresent(genre, forKey: .genre)
        try container.encodeIfPresent(releaseDate, forKey: .releaseDate)
        try container.encodeIfPresent(lastModified, forKey: .lastModified)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(rating5Based, forKey: .rating5Based)
        try container.encodeIfPresent(backdropPath, forKey: .backdropPath)
        try container.encodeIfPresent(youtubeTrailer, forKey: .youtubeTrailer)
        try container.encodeIfPresent(episodeRunTime, forKey: .episodeRunTime)
        try container.encodeIfPresent(categoryID, forKey: .categoryID)
    }
}

public extension XtreamSeriesInfo {
    typealias Season = XtreamSeriesInfoSeason
    typealias Episode = XtreamSeriesInfoEpisode
    typealias EpisodeInfo = XtreamSeriesInfoEpisodeInfo
    typealias AudioTrack = XtreamSeriesInfoAudioTrack
    typealias Subtitle = XtreamSeriesInfoSubtitle
    typealias SeriesInfoDetail = XtreamSeriesInfoDetail
}
