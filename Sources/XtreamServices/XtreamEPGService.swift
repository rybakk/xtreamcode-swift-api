import Foundation
#if canImport(XtreamClient)
import XtreamClient
#endif
#if canImport(XtreamModels)
import XtreamModels
#endif

public protocol XtreamEPGServicing {
    func fetchShortEPG(
        credentials: XtreamCredentials,
        streamID: Int,
        limit: Int?
    ) async throws -> [XtreamEPGEntry]

    func fetchEPG(
        credentials: XtreamCredentials,
        streamID: Int,
        start: Date?,
        end: Date?
    ) async throws -> [XtreamEPGEntry]

    func fetchCatchup(
        credentials: XtreamCredentials,
        streamID: Int,
        start: Date?
    ) async throws -> XtreamCatchupCollection?

    func fetchXMLTVEPG(
        credentials: XtreamCredentials
    ) async throws -> Data
}

public final class XtreamEPGService: XtreamEPGServicing {
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

    public func fetchShortEPG(
        credentials: XtreamCredentials,
        streamID: Int,
        limit: Int?
    ) async throws -> [XtreamEPGEntry] {
        let cacheKey = LiveCacheKey.shortEPG(
            username: credentials.username,
            streamID: streamID,
            limit: limit
        )
        if cacheConfiguration.shortEPGTTL > 0, let cache {
            if let cached: [XtreamEPGEntry] = await cache.value(for: cacheKey, as: [XtreamEPGEntry].self) {
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

        let endpoint = XtreamEndpoint.shortEPG(streamID: streamID, limit: limit)

        do {
            logger?.event(.requestStarted(endpoint: "get_short_epg"))
            let start = Date()

            let entries = try await fetchEPGEntries(endpoint: endpoint, credentials: credentials)

            guard !entries.isEmpty else {
                throw XtreamError.epgUnavailable(reason: "EPG court indisponible pour le flux \(streamID)")
            }

            if cacheConfiguration.shortEPGTTL > 0, let cache {
                await cache.store(entries, for: cacheKey, ttl: cacheConfiguration.shortEPGTTL)
            }

            logger?.event(.requestSucceeded(endpoint: "get_short_epg", duration: Date().timeIntervalSince(start)))
            return entries
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_short_epg", streamID: streamID))
            throw mapEPGError(error)
        }
    }

    public func fetchEPG(
        credentials: XtreamCredentials,
        streamID: Int,
        start: Date?,
        end: Date?
    ) async throws -> [XtreamEPGEntry] {
        let cacheKey = LiveCacheKey.fullEPG(
            username: credentials.username,
            streamID: streamID,
            start: start,
            end: end
        )
        if cacheConfiguration.fullEPGTTL > 0, let cache {
            if let cached: [XtreamEPGEntry] = await cache.value(for: cacheKey, as: [XtreamEPGEntry].self) {
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

        let endpoint = XtreamEndpoint.epg(streamID: streamID, start: start, end: end)

        do {
            logger?.event(.requestStarted(endpoint: "get_epg"))
            let startDate = Date()

            let entries = try await fetchEPGEntries(endpoint: endpoint, credentials: credentials)

            guard !entries.isEmpty else {
                throw XtreamError.epgUnavailable(reason: "EPG indisponible pour le flux \(streamID)")
            }

            if cacheConfiguration.fullEPGTTL > 0, let cache {
                await cache.store(entries, for: cacheKey, ttl: cacheConfiguration.fullEPGTTL)
            }

            logger?.event(.requestSucceeded(endpoint: "get_epg", duration: Date().timeIntervalSince(startDate)))
            return entries
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_epg", streamID: streamID))
            throw mapEPGError(error)
        }
    }

    public func fetchCatchup(
        credentials: XtreamCredentials,
        streamID: Int,
        start: Date?
    ) async throws -> XtreamCatchupCollection? {
        let cacheKey = LiveCacheKey.catchup(
            username: credentials.username,
            streamID: streamID,
            start: start
        )
        if cacheConfiguration.catchupTTL > 0, let cache {
            if let cached: XtreamCatchupCollection = await cache.value(
                for: cacheKey,
                as: XtreamCatchupCollection.self
            ) {
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

        let endpoint = XtreamEndpoint.catchup(streamID: streamID, start: start)

        do {
            logger?.event(.requestStarted(endpoint: "get_tv_archive"))
            let startDate = Date()

            let response: [XtreamCatchupResponse] = try await client.request(
                endpoint,
                credentials: credentials,
                decoder: makeDecoder()
            )
            let collection = response.first(where: { $0.streamID == streamID }).map(XtreamCatchupCollection.init)

            guard let collection else {
                throw XtreamError.catchupDisabled(reason: "Catch-up indisponible pour le flux \(streamID)")
            }

            guard collection.isCatchupEnabled else {
                throw XtreamError.catchupDisabled(reason: "Catch-up désactivé côté serveur pour le flux \(streamID)")
            }

            if cacheConfiguration.catchupTTL > 0, let cache {
                await cache.store(collection, for: cacheKey, ttl: cacheConfiguration.catchupTTL)
            }

            logger?.event(.requestSucceeded(endpoint: "get_tv_archive", duration: Date().timeIntervalSince(startDate)))
            return collection
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "get_tv_archive", streamID: streamID))
            throw mapCatchupError(error)
        }
    }

    public func fetchXMLTVEPG(
        credentials: XtreamCredentials
    ) async throws -> Data {
        let endpoint = XtreamEndpoint.xmltvEPG()

        do {
            logger?.event(.requestStarted(endpoint: "xmltv"))
            let startDate = Date()

            let data: Data = try await client.data(for: endpoint, credentials: credentials)

            logger?.event(.requestSucceeded(endpoint: "xmltv", duration: Date().timeIntervalSince(startDate)))
            return data
        } catch {
            logger?.error(error, context: LiveContext(endpoint: "xmltv", streamID: nil))
            throw mapEPGError(error)
        }
    }

    private func fetchEPGEntries(
        endpoint: XtreamEndpoint,
        credentials: XtreamCredentials
    ) async throws -> [XtreamEPGEntry] {
        do {
            let response: XtreamEPGResponse = try await client.request(
                endpoint,
                credentials: credentials,
                decoder: makeDecoder()
            )
            return response.epgListings.map(XtreamEPGEntry.init)
        } catch {
            throw error
        }
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = XtreamClient.makeDefaultDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }

    private func mapEPGError(_ error: Error) -> Error {
        if let clientError = error as? XtreamClientError {
            switch clientError {
            case let .http(statusCode, data):
                return XtreamError.epgUnavailable(reason: decodeMessage(
                    from: data,
                    fallback: "Erreur EPG (HTTP \(statusCode))"
                ))
            default:
                return XtreamError.fromClientError(clientError)
            }
        }
        if let xtreamError = error as? XtreamError {
            return xtreamError
        }
        return XtreamError.unknown(underlying: error)
    }

    private func mapCatchupError(_ error: Error) -> Error {
        if let clientError = error as? XtreamClientError {
            switch clientError {
            case let .http(statusCode, data):
                return XtreamError.catchupDisabled(reason: decodeMessage(
                    from: data,
                    fallback: "Catch-up indisponible (HTTP \(statusCode))"
                ))
            default:
                return XtreamError.fromClientError(clientError)
            }
        }
        if let xtreamError = error as? XtreamError {
            return xtreamError
        }
        return XtreamError.unknown(underlying: error)
    }

    private func decodeMessage(from data: Data?, fallback: String) -> String {
        guard let data, !data.isEmpty else { return fallback }
        if let rawString = String(data: data, encoding: .utf8) {
            let trimmed = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return fallback
    }
}
