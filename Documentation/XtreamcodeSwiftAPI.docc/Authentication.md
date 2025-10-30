# Authentication

Learn how to authenticate against an Xtream Codes portal using ``XtreamcodeSwiftAPI``.

## Overview

1. Créez des identifiants ``XtreamCredentials``.
2. Instanciez ``XtreamcodeSwiftAPI`` avec l’URL du portail et la session Alamofire de votre choix.
3. Appelez ``XtreamcodeSwiftAPI/authenticate(forceRefresh:)`` puis ``XtreamcodeSwiftAPI/fetchAccountDetails(forceRefresh:)`` pour récupérer la session et les informations de compte.

## Example

```swift
import XtreamcodeSwiftAPI

let credentials = XtreamCredentials(username: "demo", password: "secret")
let api = XtreamcodeSwiftAPI(
    baseURL: URL(string: "https://portal.example.com")!,
    credentials: credentials
)

Task {
    do {
        let session = try await api.authenticate()
        print("Utilisateur authentifié: \(session.username)")

        let account = try await api.fetchAccountDetails()
        print("Max connexions: \(account.session.maxConnections)")
    } catch let error as XtreamAuthError {
        switch error {
        case .invalidCredentials:
            print("Identifiants invalides")
        case .accountExpired(let expiration):
            print("Abonnement expiré le: \(String(describing: expiration))")
        case .tooManyConnections(let active, let max):
            print("Connexions actives \(active)/\(max)")
        default:
            print("Erreur d’authentification: \(error)")
        }
    } catch {
        print("Erreur inattendue: \(error)")
    }
}
```

## Related Topics

- ``XtreamcodeSwiftAPI``
- ``XtreamAuthError``
- ``XtreamAccountDetails``
