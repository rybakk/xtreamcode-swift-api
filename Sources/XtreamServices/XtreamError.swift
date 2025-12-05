import Foundation
#if canImport(XtreamClient)
import XtreamClient
#endif

public enum XtreamError: Error, Sendable {
    case network(underlying: Error)
    case decoding(underlying: Error)
    case unauthorized
    case forbidden
    case notFound
    case server(statusCode: Int, data: Data?)
    case unsupported
    case liveUnavailable(statusCode: Int?, reason: String?)
    case epgUnavailable(reason: String?)
    case catchupDisabled(reason: String?)
    case vodUnavailable(vodID: Int?, reason: String?)
    case seriesUnavailable(seriesID: Int?, reason: String?)
    case episodeNotFound(seriesID: Int, season: Int, episode: Int)
    case searchFailed(query: String, reason: String?)
    case unknown(underlying: Error)
}

// swiftlint:disable cyclomatic_complexity
public extension XtreamError {
    static func fromClientError(_ error: XtreamClientError) -> XtreamError {
        switch error {
        case .invalidURL:
            .unsupported
        case .missingCredentials, .unauthorized:
            .unauthorized
        case let .http(statusCode, data):
            switch statusCode {
            case 401:
                .unauthorized
            case 403:
                .forbidden
            case 404:
                .notFound
            case 500 ... 599:
                .server(statusCode: statusCode, data: data)
            default:
                .server(statusCode: statusCode, data: data)
            }
        case let .decoding(underlying, _):
            .decoding(underlying: underlying)
        case let .network(underlying):
            .network(underlying: underlying)
        case .invalidResponse:
            .server(statusCode: 0, data: nil)
        case .emptyResponse:
            .server(statusCode: 204, data: nil)
        }
    }
}

// swiftlint:enable cyclomatic_complexity

extension XtreamError {
    static func map(_ error: Error) -> XtreamError {
        if let clientError = error as? XtreamClientError {
            return XtreamError.fromClientError(clientError)
        }
        return .unknown(underlying: error)
    }
}
