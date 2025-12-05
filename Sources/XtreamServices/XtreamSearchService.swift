import Foundation
#if canImport(XtreamClient)
import XtreamClient
#endif
#if canImport(XtreamModels)
import XtreamModels
#endif

public enum XtreamSearchType: String, Codable, Sendable {
    case all
    case live
    case movie
    case series
}

public protocol XtreamSearchServicing {
    func search(
        credentials: XtreamCredentials,
        query: String,
        type: XtreamSearchType
    ) async throws -> [XtreamSearchResult]
}

public final class XtreamSearchService: XtreamSearchServicing {
    private let client: XtreamClient
    private let logger: LiveLogger?
    private let diagnostics: LiveDiagnosticsRecording?

    public init(
        client: XtreamClient,
        logger: LiveLogger? = nil,
        diagnostics: LiveDiagnosticsRecording? = nil
    ) {
        self.client = client
        self.logger = logger
        self.diagnostics = diagnostics
    }

    public func search(
        credentials: XtreamCredentials,
        query: String,
        type: XtreamSearchType = .all
    ) async throws -> [XtreamSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        do {
            logger?.event(.requestStarted(endpoint: "search"))
            let start = Date()

            let typeParam = type == .all ? nil : type.rawValue
            let response: [XtreamSearchResultResponse] = try await client.request(
                .search(query: query, type: typeParam),
                credentials: credentials,
                decoder: makeDecoder()
            )
            let results = response.map(XtreamSearchResult.init)

            logger?.event(.requestSucceeded(endpoint: "search", duration: Date().timeIntervalSince(start)))
            return results
        } catch {
            logger?.error(
                error,
                context: LiveContext(endpoint: "search", searchQuery: query, searchType: type)
            )
            throw mapSearchError(error, query: query)
        }
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }

    private func mapSearchError(_ error: Error, query: String) -> Error {
        if let clientError = error as? XtreamClientError {
            switch clientError {
            case let .http(statusCode, data):
                let message = decodeMessage(from: data)
                return XtreamError.searchFailed(query: query, reason: message ?? "HTTP \(statusCode)")
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
