import Foundation
#if canImport(XtreamModels)
import XtreamModels
#endif

public struct XtreamEndpoint: Sendable {
    public enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
    }

    public let path: String
    public let method: Method
    public let queryItems: [URLQueryItem]
    public let body: Data?
    public let headers: [String: String]
    public let requiresCredentials: Bool

    public init(
        path: String,
        method: Method = .get,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        headers: [String: String] = [:],
        requiresCredentials: Bool = true
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
        self.requiresCredentials = requiresCredentials
    }

    func makeRequest(
        baseURL: URL,
        credentials: XtreamCredentials?,
        defaultHeaders: [String: String]
    ) throws -> URLRequest {
        var resolvedURL = baseURL

        if !path.isEmpty {
            let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
            resolvedURL = resolvedURL.appendingPathComponent(trimmedPath)
        }

        guard var components = URLComponents(url: resolvedURL, resolvingAgainstBaseURL: false) else {
            throw XtreamClientError.invalidURL
        }

        var urlQueryItems = queryItems
        if requiresCredentials {
            guard let credentials else {
                throw XtreamClientError.missingCredentials
            }
            urlQueryItems.append(URLQueryItem(name: "username", value: credentials.username))
            urlQueryItems.append(URLQueryItem(name: "password", value: credentials.password))
        }

        if !urlQueryItems.isEmpty {
            components.queryItems = (components.queryItems ?? []) + urlQueryItems
        }

        guard let finalURL = components.url else {
            throw XtreamClientError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.httpBody = body

        let mergedHeaders = defaultHeaders.merging(headers) { _, new in new }
        for (field, value) in mergedHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }

        return request
    }
}

public extension XtreamEndpoint {
    static func playerAPI(
        action: String? = nil,
        additionalQueryItems: [URLQueryItem] = [],
        requiresCredentials: Bool = true
    ) -> XtreamEndpoint {
        var items = additionalQueryItems
        if let action {
            items.append(URLQueryItem(name: "action", value: action))
        }
        return XtreamEndpoint(
            path: "player_api.php",
            method: .get,
            queryItems: items,
            requiresCredentials: requiresCredentials
        )
    }

    static func login() -> XtreamEndpoint {
        playerAPI()
    }

    static func accountInfo() -> XtreamEndpoint {
        playerAPI(action: "get_user_info")
    }

    static func systemStatus() -> XtreamEndpoint {
        playerAPI(action: "system_status")
    }

    static func liveCategories() -> XtreamEndpoint {
        playerAPI(action: "get_live_categories")
    }

    static func liveStreams(categoryID: String? = nil) -> XtreamEndpoint {
        var items: [URLQueryItem] = []
        if let categoryID {
            items.append(URLQueryItem(name: "category_id", value: categoryID))
        }
        return playerAPI(action: "get_live_streams", additionalQueryItems: items)
    }

    static func liveStream(streamID: Int) -> XtreamEndpoint {
        playerAPI(
            action: "get_live_streams",
            additionalQueryItems: [URLQueryItem(name: "stream_id", value: String(streamID))]
        )
    }

    static func liveStreamURL(streamID: Int) -> XtreamEndpoint {
        playerAPI(
            action: "get_live_url",
            additionalQueryItems: [URLQueryItem(name: "stream_id", value: String(streamID))]
        )
    }

    static func shortEPG(streamID: Int, limit: Int?) -> XtreamEndpoint {
        var items = [URLQueryItem(name: "stream_id", value: String(streamID))]
        if let limit {
            items.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        return playerAPI(action: "get_short_epg", additionalQueryItems: items)
    }

    static func epg(streamID: Int, start: Date?, end: Date?) -> XtreamEndpoint {
        var items = [URLQueryItem(name: "stream_id", value: String(streamID))]
        if let start {
            items.append(URLQueryItem(name: "start", value: String(Int(start.timeIntervalSince1970))))
        }
        if let end {
            items.append(URLQueryItem(name: "end", value: String(Int(end.timeIntervalSince1970))))
        }
        return playerAPI(action: "get_epg", additionalQueryItems: items)
    }

    static func catchup(streamID: Int, start: Date?) -> XtreamEndpoint {
        var items = [URLQueryItem(name: "stream_id", value: String(streamID))]
        if let start {
            items.append(URLQueryItem(name: "start", value: String(Int(start.timeIntervalSince1970))))
        }
        return playerAPI(action: "get_tv_archive", additionalQueryItems: items)
    }

    // MARK: - VOD Endpoints

    static func vodCategories() -> XtreamEndpoint {
        playerAPI(action: "get_vod_categories")
    }

    static func vodStreams(categoryID: String? = nil) -> XtreamEndpoint {
        var items: [URLQueryItem] = []
        if let categoryID {
            items.append(URLQueryItem(name: "category_id", value: categoryID))
        }
        return playerAPI(action: "get_vod_streams", additionalQueryItems: items)
    }

    static func vodInfo(vodID: Int) -> XtreamEndpoint {
        playerAPI(
            action: "get_vod_info",
            additionalQueryItems: [URLQueryItem(name: "vod_id", value: String(vodID))]
        )
    }

    // MARK: - Series Endpoints

    static func seriesCategories() -> XtreamEndpoint {
        playerAPI(action: "get_series_categories")
    }

    static func series(categoryID: String? = nil) -> XtreamEndpoint {
        var items: [URLQueryItem] = []
        if let categoryID {
            items.append(URLQueryItem(name: "category_id", value: categoryID))
        }
        return playerAPI(action: "get_series", additionalQueryItems: items)
    }

    static func seriesInfo(seriesID: Int) -> XtreamEndpoint {
        playerAPI(
            action: "get_series_info",
            additionalQueryItems: [URLQueryItem(name: "series_id", value: String(seriesID))]
        )
    }

    // MARK: - Search Endpoint

    static func search(query: String, type: String? = nil) -> XtreamEndpoint {
        var items = [URLQueryItem(name: "search", value: query)]
        if let type {
            items.append(URLQueryItem(name: "type", value: type))
        }
        return playerAPI(action: "search", additionalQueryItems: items)
    }
}
