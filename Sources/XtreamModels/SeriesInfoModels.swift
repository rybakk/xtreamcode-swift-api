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
}

public struct XtreamSeriesInfoSeason: Codable, Sendable, Equatable, Hashable {
    public let airDate: String?
    public let episodeCount: Int?
    public let id: Int?
    public let name: String?
    public let overview: String?
    public let seasonNumber: Int?
    public let coverBig: String?

    public init(
        airDate: String?,
        episodeCount: Int?,
        id: Int?,
        name: String?,
        overview: String?,
        seasonNumber: Int?,
        coverBig: String?
    ) {
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.id = id
        self.name = name
        self.overview = overview
        self.seasonNumber = seasonNumber
        self.coverBig = coverBig
    }

    private enum CodingKeys: String, CodingKey {
        case airDate = "air_date"
        case episodeCount = "episode_count"
        case id
        case name
        case overview
        case seasonNumber = "season_number"
        case coverBig = "cover_big"
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
        case audio
        case subtitles
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
}

public extension XtreamSeriesInfo {
    typealias Season = XtreamSeriesInfoSeason
    typealias Episode = XtreamSeriesInfoEpisode
    typealias EpisodeInfo = XtreamSeriesInfoEpisodeInfo
    typealias AudioTrack = XtreamSeriesInfoAudioTrack
    typealias Subtitle = XtreamSeriesInfoSubtitle
    typealias SeriesInfoDetail = XtreamSeriesInfoDetail
}
