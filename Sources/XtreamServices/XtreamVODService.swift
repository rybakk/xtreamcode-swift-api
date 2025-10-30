import Foundation
import XtreamClient
import XtreamModels

public protocol XtreamVODServicing {
    func fetchCategories(credentials: XtreamCredentials) async throws -> [XtreamVODCategory]
    func fetchStreams(credentials: XtreamCredentials, categoryID: String?) async throws -> [XtreamVODStream]
    func fetchDetails(credentials: XtreamCredentials, vodID: Int) async throws -> XtreamVODInfo
}

public final class XtreamVODService: XtreamVODServicing {
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

    public func fetchCategories(credentials: XtreamCredentials) async throws -> [XtreamVODCategory] {
        let cacheKey = LiveCacheKey.vodCategories(username: credentials.username)
        if cacheConfiguration.categoriesTTL > 0, let cache {
            if let cached: [XtreamVODCategory] = await cache.value(for: cacheKey, as: [XtreamVODCategory].self) {
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
            logger?.event(.requestStarted(endpoint: "get_vod_categories"))
            let start = Date()

            let response: [XtreamVODCategoryResponse] = try await client.request(
                .vodCategories(),
                credentials: credentials,
                decoder: makeDecoder()
            )
            let categories = response.map(XtreamVODCategory.init)

            if cacheConfiguration.categoriesTTL > 0, let cache {
                await cache.store(categories, for: cacheKey, ttl: cacheConfiguration.categoriesTTL)
            }

            logger?.event(.requestSucceeded(endpoint: "get_vod_categories", duration: Date().timeIntervalSince(start)))
            return categories
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_vod_categories"))
            throw mapVODError(error)
        }
    }

    public func fetchStreams(credentials: XtreamCredentials, categoryID: String?) async throws -> [XtreamVODStream] {
        let cacheKey = LiveCacheKey.vodStreams(username: credentials.username, categoryID: categoryID)
        if cacheConfiguration.streamsTTL > 0, let cache {
            if let cached: [XtreamVODStream] = await cache.value(for: cacheKey, as: [XtreamVODStream].self) {
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
            logger?.event(.requestStarted(endpoint: "get_vod_streams"))
            let start = Date()

            let response: [XtreamVODStreamResponse] = try await client.request(
                .vodStreams(categoryID: categoryID),
                credentials: credentials,
                decoder: makeDecoder()
            )
            let streams = response.map(XtreamVODStream.init)

            if cacheConfiguration.streamsTTL > 0, let cache {
                await cache.store(streams, for: cacheKey, ttl: cacheConfiguration.streamsTTL)
            }

            logger?.event(.requestSucceeded(endpoint: "get_vod_streams", duration: Date().timeIntervalSince(start)))
            return streams
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_vod_streams", categoryID: categoryID))
            throw mapVODError(error)
        }
    }

    public func fetchDetails(credentials: XtreamCredentials, vodID: Int) async throws -> XtreamVODInfo {
        let cacheKey = LiveCacheKey.vodInfo(username: credentials.username, vodID: vodID)
        if cacheConfiguration.streamDetailsTTL > 0, let cache {
            if let cached: XtreamVODInfo = await cache.value(for: cacheKey, as: XtreamVODInfo.self) {
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
            logger?.event(.requestStarted(endpoint: "get_vod_info"))
            let start = Date()

            let response: XtreamVODInfo = try await client.request(
                .vodInfo(vodID: vodID),
                credentials: credentials,
                decoder: makeDecoder()
            )

            if cacheConfiguration.streamDetailsTTL > 0, let cache {
                await cache.store(response, for: cacheKey, ttl: cacheConfiguration.streamDetailsTTL)
            }

            logger?.event(.requestSucceeded(endpoint: "get_vod_info", duration: Date().timeIntervalSince(start)))
            return response
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_vod_info", vodID: vodID))
            throw mapVODError(error, vodID: vodID)
        }
    }

    public func fetchStreamURL(
        credentials: XtreamCredentials,
        vodID: Int,
        quality: String? = nil
    ) async throws -> URL {
        _ = quality // Qualité non différenciée pour l'instant (placeholder pour futurs profils).
        let info = try await fetchDetails(credentials: credentials, vodID: vodID)

        if let directSource = info.movieData?.directSource,
           let directURL = URL(string: directSource),
           !directSource.isEmpty {
            return directURL
        }

        guard let streamID = info.movieData?.streamID,
              let fileExtension = info.movieData?.containerExtension, !fileExtension.isEmpty else {
            throw XtreamError.vodUnavailable(vodID: vodID, reason: "Missing stream metadata")
        }

        var url = client.baseURL
        url = url
            .appendingPathComponent("movie")
            .appendingPathComponent(credentials.username)
            .appendingPathComponent(credentials.password)
            .appendingPathComponent("\(streamID).\(fileExtension)")
        return url
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }

    private func mapVODError(_ error: Error, vodID: Int? = nil) -> Error {
        if let clientError = error as? XtreamClientError {
            switch clientError {
            case let .http(statusCode, data):
                let message = decodeMessage(from: data)
                if statusCode == 404 {
                    return XtreamError.vodUnavailable(vodID: vodID, reason: message ?? "VOD not found")
                }
                return XtreamError.vodUnavailable(vodID: vodID, reason: message ?? "HTTP \(statusCode)")
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
