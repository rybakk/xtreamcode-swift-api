import Foundation
#if canImport(XtreamClient)
import XtreamClient
#endif
#if canImport(XtreamModels)
import XtreamModels
#endif

public final class XtreamServiceRegistry {
    public let client: XtreamClient
    private let liveCacheStore: LiveCacheStore?
    private let liveCacheConfiguration: LiveCacheConfiguration
    private let logger: LiveLogger?
    private let diagnostics: LiveDiagnosticsRecording?

    public init(
        client: XtreamClient,
        liveCacheStore: LiveCacheStore? = nil,
        liveCacheConfiguration: LiveCacheConfiguration = LiveCacheConfiguration(),
        logger: LiveLogger? = nil,
        diagnostics: LiveDiagnosticsRecording? = nil
    ) {
        self.client = client
        self.liveCacheStore = liveCacheStore
        self.liveCacheConfiguration = liveCacheConfiguration
        self.logger = logger
        self.diagnostics = diagnostics
    }

    public func makeAuthService() -> XtreamAuthService {
        XtreamAuthService(client: client)
    }

    public func makeAccountService() -> XtreamAccountService {
        XtreamAccountService(client: client)
    }

    public func makeLiveService() -> XtreamLiveService {
        XtreamLiveService(
            client: client,
            cache: liveCacheStore,
            cacheConfiguration: liveCacheConfiguration,
            logger: logger,
            diagnostics: diagnostics
        )
    }

    public func makeEPGService() -> XtreamEPGService {
        XtreamEPGService(
            client: client,
            cache: liveCacheStore,
            cacheConfiguration: liveCacheConfiguration,
            logger: logger,
            diagnostics: diagnostics
        )
    }

    public func makeVODService() -> XtreamVODService {
        XtreamVODService(
            client: client,
            cache: liveCacheStore,
            cacheConfiguration: liveCacheConfiguration,
            logger: logger,
            diagnostics: diagnostics
        )
    }

    public func makeSeriesService() -> XtreamSeriesService {
        XtreamSeriesService(
            client: client,
            cache: liveCacheStore,
            cacheConfiguration: liveCacheConfiguration,
            logger: logger,
            diagnostics: diagnostics
        )
    }

    public func makeSearchService() -> XtreamSearchService {
        XtreamSearchService(
            client: client,
            logger: logger,
            diagnostics: diagnostics
        )
    }
}
