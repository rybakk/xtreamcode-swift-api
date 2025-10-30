import Foundation
import XtreamClient
import XtreamModels

public protocol XtreamLiveServicing {
    func fetchCategories(credentials: XtreamCredentials) async throws -> [XtreamLiveCategory]
    func fetchStreams(credentials: XtreamCredentials, categoryID: String?) async throws -> [XtreamLiveStream]
    func fetchStreamDetails(credentials: XtreamCredentials, streamID: Int) async throws -> XtreamLiveStream?
    func fetchStreamURLs(credentials: XtreamCredentials, streamID: Int) async throws -> [XtreamLiveStreamURL]
}

public final class XtreamLiveService: XtreamLiveServicing {
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

    public func fetchCategories(credentials: XtreamCredentials) async throws -> [XtreamLiveCategory] {
        let cacheKey = LiveCacheKey.liveCategories(username: credentials.username)
        if cacheConfiguration.categoriesTTL > 0, let cache {
            if let cached: [XtreamLiveCategory] = await cache.value(for: cacheKey, as: [XtreamLiveCategory].self) {
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
            logger?.event(.requestStarted(endpoint: "get_live_categories"))
            let start = Date()

            let response: [XtreamLiveCategoryResponse] = try await client.request(
                .liveCategories(),
                credentials: credentials,
                decoder: makeDecoder()
            )
            let categories = response.map(XtreamLiveCategory.init)

            if cacheConfiguration.categoriesTTL > 0, let cache {
                await cache.store(categories, for: cacheKey, ttl: cacheConfiguration.categoriesTTL)
            }

            logger?.event(.requestSucceeded(endpoint: "get_live_categories", duration: Date().timeIntervalSince(start)))
            return categories
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_live_categories"))
            throw mapGeneralLiveError(error)
        }
    }

    public func fetchStreams(credentials: XtreamCredentials, categoryID: String?) async throws -> [XtreamLiveStream] {
        let cacheKey = LiveCacheKey.liveStreams(username: credentials.username, categoryID: categoryID)
        if cacheConfiguration.streamsTTL > 0, let cache {
            if let cached: [XtreamLiveStream] = await cache.value(for: cacheKey, as: [XtreamLiveStream].self) {
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

        let endpoint = XtreamEndpoint.liveStreams(categoryID: categoryID)

        do {
            logger?.event(.requestStarted(endpoint: "get_live_streams"))
            let start = Date()

            let response: [XtreamLiveStreamResponse] = try await client.request(
                endpoint,
                credentials: credentials,
                decoder: makeDecoder()
            )
            let streams = response.map(XtreamLiveStream.init)

            if cacheConfiguration.streamsTTL > 0, let cache {
                await cache.store(streams, for: cacheKey, ttl: cacheConfiguration.streamsTTL)
            }

            logger?.event(.requestSucceeded(endpoint: "get_live_streams", duration: Date().timeIntervalSince(start)))
            return streams
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_live_streams", categoryID: categoryID))
            throw mapGeneralLiveError(error)
        }
    }

    public func fetchStreamDetails(credentials: XtreamCredentials, streamID: Int) async throws -> XtreamLiveStream? {
        let cacheKey = LiveCacheKey.liveStreamDetails(username: credentials.username, streamID: streamID)
        if cacheConfiguration.streamDetailsTTL > 0, let cache {
            if let cached: XtreamLiveStream = await cache.value(for: cacheKey, as: XtreamLiveStream.self) {
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

        let endpoint = XtreamEndpoint.liveStream(streamID: streamID)

        do {
            logger?.event(.requestStarted(endpoint: "get_live_streams"))
            let start = Date()

            let response: [XtreamLiveStreamResponse] = try await client.request(
                endpoint,
                credentials: credentials,
                decoder: makeDecoder()
            )
            let stream = response.first.map(XtreamLiveStream.init)

            if cacheConfiguration.streamDetailsTTL > 0, let cache, let stream {
                await cache.store(stream, for: cacheKey, ttl: cacheConfiguration.streamDetailsTTL)
            }

            logger?.event(.requestSucceeded(endpoint: "get_live_streams", duration: Date().timeIntervalSince(start)))
            return stream
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_live_streams", streamID: streamID))
            throw mapGeneralLiveError(error)
        }
    }

    public func fetchStreamURLs(credentials: XtreamCredentials, streamID: Int) async throws -> [XtreamLiveStreamURL] {
        let cacheKey = LiveCacheKey.liveStreamURLs(username: credentials.username, streamID: streamID)
        if cacheConfiguration.streamURLsTTL > 0, let cache {
            if let cached: [XtreamLiveStreamURL] = await cache.value(for: cacheKey, as: [XtreamLiveStreamURL].self) {
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

        let endpoint = XtreamEndpoint.liveStreamURL(streamID: streamID)

        do {
            logger?.event(.requestStarted(endpoint: "get_live_url"))
            let start = Date()

            let response: XtreamLiveURLResponse = try await client.request(
                endpoint,
                credentials: credentials,
                decoder: makeDecoder()
            )
            let urls = response.streamURLs.compactMap(XtreamLiveStreamURL.init)

            guard !urls.isEmpty else {
                throw XtreamError.liveUnavailable(
                    statusCode: nil,
                    reason: "Aucune URL valide renvoyée pour le flux \(streamID)"
                )
            }

            if cacheConfiguration.streamURLsTTL > 0, let cache {
                await cache.store(urls, for: cacheKey, ttl: cacheConfiguration.streamURLsTTL)
            }

            logger?.event(.requestSucceeded(endpoint: "get_live_url", duration: Date().timeIntervalSince(start)))
            return urls
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_live_url", streamID: streamID))
            throw mapStreamURLError(error)
        }
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = XtreamClient.makeDefaultDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }

    private func mapGeneralLiveError(_ error: Error) -> Error {
        if let xtreamError = error as? XtreamError {
            return xtreamError
        }
        if let clientError = error as? XtreamClientError {
            return XtreamError.fromClientError(clientError)
        }
        return XtreamError.unknown(underlying: error)
    }

    private func mapStreamURLError(_ error: Error) -> Error {
        if let clientError = error as? XtreamClientError {
            switch clientError {
            case let .http(statusCode, data):
                return XtreamError.liveUnavailable(
                    statusCode: statusCode,
                    reason: decodeMessage(from: data)
                )
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
        if let rawString = String(data: data, encoding: .utf8) {
            let trimmed = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }
}
