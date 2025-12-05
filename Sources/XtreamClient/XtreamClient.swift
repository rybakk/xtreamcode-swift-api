import Alamofire
import Foundation
#if canImport(XtreamModels)
import XtreamModels
#endif

public final class XtreamClient {
    public struct Configuration {
        public let baseURL: URL
        public let session: Session
        public let defaultHeaders: [String: String]
        public let decoderFactory: @Sendable () -> JSONDecoder

        public init(
            baseURL: URL,
            session: Session = .default,
            defaultHeaders: [String: String] = [:],
            decoderFactory: @escaping @Sendable () -> JSONDecoder = { XtreamClient.makeDefaultDecoder() }
        ) {
            self.baseURL = baseURL
            self.session = session
            self.defaultHeaders = defaultHeaders
            self.decoderFactory = decoderFactory
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public var baseURL: URL {
        configuration.baseURL
    }

    // MARK: - Public API

    public func data(
        for endpoint: XtreamEndpoint,
        credentials: XtreamCredentials? = nil
    ) async throws -> Data {
        let urlRequest = try endpoint.makeRequest(
            baseURL: configuration.baseURL,
            credentials: credentials,
            defaultHeaders: configuration.defaultHeaders
        )

        let dataResponse = await configuration.session
            .request(urlRequest)
            .serializingData()
            .response

        if let error = dataResponse.error {
            throw XtreamClientError.network(error)
        }

        guard let httpResponse = dataResponse.response else {
            throw XtreamClientError.invalidResponse
        }

        let payload = dataResponse.data ?? Data()

        switch httpResponse.statusCode {
        case 200 ..< 300:
            break
        case 401:
            throw XtreamClientError.unauthorized(data: payload)
        case 400 ..< 600:
            throw XtreamClientError.http(statusCode: httpResponse.statusCode, data: payload)
        default:
            break
        }

        if payload.isEmpty, httpResponse.statusCode != 204 {
            throw XtreamClientError.emptyResponse
        }

        return payload
    }

    public func request<T: Decodable>(
        _ endpoint: XtreamEndpoint,
        credentials: XtreamCredentials? = nil,
        decoder: JSONDecoder? = nil
    ) async throws -> T {
        let data = try await self.data(for: endpoint, credentials: credentials)
        let effectiveDecoder = decoder ?? configuration.decoderFactory()

        do {
            return try effectiveDecoder.decode(T.self, from: data)
        } catch {
            throw XtreamClientError.decoding(underlying: error, data: data)
        }
    }

    // MARK: - Helpers

    public static func makeDefaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
