import Foundation
import XtreamClient
import XtreamModels

public protocol XtreamSeriesServicing {
    func fetchCategories(credentials: XtreamCredentials) async throws -> [XtreamSeriesCategory]
    func fetchSeries(credentials: XtreamCredentials, categoryID: String?) async throws -> [XtreamSeries]
    func fetchDetails(credentials: XtreamCredentials, seriesID: Int) async throws -> XtreamSeriesInfo
}

public final class XtreamSeriesService: XtreamSeriesServicing {
    private let client: XtreamClient
    private let cache: LiveCacheStore?
    private let cacheConfiguration: LiveCacheConfiguration
    private let logger: LiveLogger?
    private let diagnostics: LiveDiagnosticsRecording?

    public init(
        client: XtreamClient,
        cache: LiveCacheStore? = nil,
        cacheConfiguration: LiveCacheConfiguration = LiveCacheConfiguration(),
        logger: LiveLogger? = nil,
        diagnostics: LiveDiagnosticsRecording? = nil
    ) {
        self.client = client
        self.cache = cache
        self.cacheConfiguration = cacheConfiguration
        self.logger = logger
        self.diagnostics = diagnostics
    }

    public func fetchCategories(credentials: XtreamCredentials) async throws -> [XtreamSeriesCategory] {
        let cacheKey = LiveCacheKey.seriesCategories(username: credentials.username)
        if cacheConfiguration.categoriesTTL > 0, let cache {
            if let cached: [XtreamSeriesCategory] = await cache.value(for: cacheKey, as: [XtreamSeriesCategory].self) {
                logger?.event(.cacheHit(key: cacheKey, source: .memoryOrDisk))
                if let diagnostics {
                    await diagnostics.recordCacheHit(for: cacheKey)
                }
                return cached
            }
        }

        if let diagnostics {
            await diagnostics.recordCacheMiss(for: cacheKey)
        }
        logger?.event(.cacheMiss(key: cacheKey))

        do {
            logger?.event(.requestStarted(endpoint: "get_series_categories"))
            let start = Date()

            let response: [XtreamSeriesCategoryResponse] = try await client.request(
                .seriesCategories(),
                credentials: credentials,
                decoder: makeDecoder()
            )
            let categories = response.map(XtreamSeriesCategory.init)

            if cacheConfiguration.categoriesTTL > 0, let cache {
                await cache.store(categories, for: cacheKey, ttl: cacheConfiguration.categoriesTTL)
            }

            logger?.event(
                .requestSucceeded(
                    endpoint: "get_series_categories",
                    duration: Date().timeIntervalSince(start)
                )
            )
            return categories
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_series_categories"))
            throw mapSeriesError(error)
        }
    }

    public func fetchSeries(credentials: XtreamCredentials, categoryID: String?) async throws -> [XtreamSeries] {
        let cacheKey = LiveCacheKey.series(username: credentials.username, categoryID: categoryID)
        if cacheConfiguration.streamsTTL > 0, let cache {
            if let cached: [XtreamSeries] = await cache.value(for: cacheKey, as: [XtreamSeries].self) {
                logger?.event(.cacheHit(key: cacheKey, source: .memoryOrDisk))
                if let diagnostics {
                    await diagnostics.recordCacheHit(for: cacheKey)
                }
                return cached
            }
        }

        if let diagnostics {
            await diagnostics.recordCacheMiss(for: cacheKey)
        }
        logger?.event(.cacheMiss(key: cacheKey))

        do {
            logger?.event(.requestStarted(endpoint: "get_series"))
            let start = Date()

            let response: [XtreamSeriesResponse] = try await client.request(
                .series(categoryID: categoryID),
                credentials: credentials,
                decoder: makeDecoder()
            )
            let series = response.map(XtreamSeries.init)

            if cacheConfiguration.streamsTTL > 0, let cache {
                await cache.store(series, for: cacheKey, ttl: cacheConfiguration.streamsTTL)
            }

            logger?.event(
                .requestSucceeded(
                    endpoint: "get_series",
                    duration: Date().timeIntervalSince(start)
                )
            )
            return series
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_series", categoryID: categoryID))
            throw mapSeriesError(error)
        }
    }

    public func fetchDetails(credentials: XtreamCredentials, seriesID: Int) async throws -> XtreamSeriesInfo {
        let cacheKey = LiveCacheKey.seriesInfo(username: credentials.username, seriesID: seriesID)
        if cacheConfiguration.streamDetailsTTL > 0, let cache {
            if let cached: XtreamSeriesInfo = await cache.value(for: cacheKey, as: XtreamSeriesInfo.self) {
                logger?.event(.cacheHit(key: cacheKey, source: .memoryOrDisk))
                if let diagnostics {
                    await diagnostics.recordCacheHit(for: cacheKey)
                }
                return cached
            }
        }

        if let diagnostics {
            await diagnostics.recordCacheMiss(for: cacheKey)
        }
        logger?.event(.cacheMiss(key: cacheKey))

        do {
            logger?.event(.requestStarted(endpoint: "get_series_info"))
            let start = Date()

            let response: XtreamSeriesInfo = try await client.request(
                .seriesInfo(seriesID: seriesID),
                credentials: credentials,
                decoder: makeDecoder()
            )

            if cacheConfiguration.streamDetailsTTL > 0, let cache {
                await cache.store(response, for: cacheKey, ttl: cacheConfiguration.streamDetailsTTL)
            }

            logger?.event(
                .requestSucceeded(
                    endpoint: "get_series_info",
                    duration: Date().timeIntervalSince(start)
                )
            )
            return response
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_series_info", seriesID: seriesID))
            throw mapSeriesError(error, seriesID: seriesID)
        }
    }

    public func fetchEpisodeURL(
        credentials: XtreamCredentials,
        seriesID: Int,
        season: Int,
        episode: Int
    ) async throws -> URL {
        let info = try await fetchDetails(credentials: credentials, seriesID: seriesID)

        guard let episodes = info.episodes?["\(season)"] else {
            throw XtreamError.episodeNotFound(seriesID: seriesID, season: season, episode: episode)
        }

        guard let targetEpisode = episodes.first(where: { $0.episodeNum == episode }) else {
            throw XtreamError.episodeNotFound(seriesID: seriesID, season: season, episode: episode)
        }

        if let directSource = targetEpisode.directSource,
           let directURL = URL(string: directSource),
           !directSource.isEmpty {
            return directURL
        }

        let fileExtension = (targetEpisode.containerExtension?.isEmpty == false) ? targetEpisode.containerExtension! : "mp4"
        let identifier = (targetEpisode.id?.isEmpty == false) ? targetEpisode.id! : String(episode)

        var url = client.baseURL
        url = url
            .appendingPathComponent("series")
            .appendingPathComponent(credentials.username)
            .appendingPathComponent(credentials.password)
            .appendingPathComponent(String(seriesID))
            .appendingPathComponent(String(season))
            .appendingPathComponent("\(identifier).\(fileExtension)")
        return url
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }

    private func mapSeriesError(_ error: Error, seriesID: Int? = nil) -> Error {
        if let clientError = error as? XtreamClientError {
            switch clientError {
            case let .http(statusCode, data):
                let message = decodeMessage(from: data)
                if statusCode == 404 {
                    return XtreamError.seriesUnavailable(seriesID: seriesID, reason: message ?? "Series not found")
                }
                return XtreamError.seriesUnavailable(seriesID: seriesID, reason: message ?? "HTTP \(statusCode)")
            default:
                return XtreamError.fromClientError(clientError)
            }
        }
        if let xtreamError = error as? XtreamError {
            return xtreamError
        }
        return XtreamError.unknown(underlying: error)
    }

    private func decodeMessage(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        if let string = String(data: data, encoding: .utf8) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return nil
    }
}

// MARK: - Error Extension
