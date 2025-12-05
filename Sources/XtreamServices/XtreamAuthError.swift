import Foundation
#if canImport(XtreamClient)
import XtreamClient
#endif

public enum XtreamAuthError: Error, Sendable {
    case invalidCredentials(message: String?)
    case accountExpired(expiration: Date?)
    case tooManyConnections(active: Int, max: Int)
    case unauthorized(message: String?)
    case client(XtreamClientError)
}
