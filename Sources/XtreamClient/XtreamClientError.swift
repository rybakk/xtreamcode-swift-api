import Foundation

public enum XtreamClientError: Error, Sendable {
    case invalidURL
    case missingCredentials
    case invalidResponse
    case emptyResponse
    case unauthorized(data: Data?)
    case http(statusCode: Int, data: Data?)
    case decoding(underlying: Error, data: Data)
    case network(Error)
}
