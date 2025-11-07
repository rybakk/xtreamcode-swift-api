# Xtreamcode Swift API

SDK Swift multiplateforme pour interagir avec une instance Xtream Codes.  
Le projet se structure comme une suite de modules (`XtreamModels`, `XtreamClient`, `XtreamServices`, `XtreamSDKFacade`) afin de proposer une intégration testable et évolutive.

## Prérequis

- Swift 5.10+
- iOS 14 / macOS 12 / tvOS 15 minimum
- Alamofire 5.10.2 (déclaré via Swift Package Manager)

## Installation (SwiftPM)

```swift
dependencies: [
    .package(url: "https://github.com/<org>/xtreamcode-swift-api.git", from: "1.1.1")
]
```

La librairie exposée s’importe avec :

```swift
import XtreamcodeSwiftAPI
``` 

Les instructions pour CocoaPods et Carthage sont décrites dans `docs/distribution.md`.

## Scripts utiles

- `./scripts/build.sh` : compilation via `swift build`.
- `./scripts/test.sh` : exécution des tests (`swift test --parallel` par défaut).
- `./scripts/lint.sh` : SwiftFormat + SwiftLint.
- `./scripts/demo-live.sh` : scénario CLI du sprint Live/EPG.
- `./scripts/demo-vod-series.sh` : scénario CLI du sprint VOD/Séries.

## Exemple d'utilisation

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
        print("Bienvenue \(session.username)")

        let account = try await api.fetchAccountDetails()
        print("Connexions actives : \(account.session.activeConnections)/\(account.session.maxConnections)")

        let categories = try await api.liveCategories()
        print("Catégories live disponibles : \(categories.count)")

        if let firstCategory = categories.first {
            let streams = try await api.liveStreams(in: firstCategory.id)
            print("Canaux dans \(firstCategory.name): \(streams.count)")

            if let stream = streams.first {
                let entries = try await api.epg(for: stream.id, limit: 5)
                print("EPG rapide pour \(stream.name): \(entries.map(\.decodedTitle ?? stream.name))")

                if let url = try await api.liveStreamURL(for: stream.id) {
                    print("Flux HLS: \(url.absoluteString)")
                }
            }
        }
    } catch {
        print("Erreur: \(error)")
    }
}
```

Les cas d'erreurs typiques sont exposés via `XtreamAuthError` (`invalidCredentials`, `accountExpired`, `tooManyConnections`, etc.). Pour la partie live/EPG, reportez-vous à `XtreamError.liveUnavailable`, `XtreamError.epgUnavailable`, `XtreamError.catchupDisabled`.

### Exemple VOD & Séries

```swift
Task {
    do {
        let vodCategories = try await api.vodCategories()
        print("Catégories VOD : \(vodCategories.count)")

        if let actionCategory = vodCategories.first {
            let vodStreams = try await api.vodStreams(in: actionCategory.id)
            print("Films disponibles : \(vodStreams.count)")

            if let movie = vodStreams.first {
                let details = try await api.vodDetails(for: movie.streamID)
                print("Synopsis : \(details.info?.plot ?? "N/A")")
            }
        }

        let seriesCategories = try await api.seriesCategories()
        if let drama = seriesCategories.first {
            let series = try await api.series(in: drama.id)
            if let firstSeries = series.first {
                let info = try await api.seriesDetails(for: firstSeries.seriesID)
                print("Nombre de saisons : \(info.seasons?.count ?? 0)")
            }
        }

        let results = try await api.search(query: "demo")
        print("Résultats combinés (Live/VOD/Séries) : \(results.count)")

        // Suivi de progression local (ex : reprise d'un film)
        try await api.saveProgress(contentID: "vod-130529", position: 120, duration: 360)
        if let progress = try await api.loadProgress(contentID: "vod-130529") {
            print("Reprise à \(progress.position)s sur \(progress.duration)s")
        }
    } catch {
        print("Erreur : \(error)")
    }
}
```

Les erreurs spécifiques VOD/Séries sont exposées via `XtreamError.vodUnavailable`, `XtreamError.seriesUnavailable`, `XtreamError.episodeNotFound` et `XtreamError.searchFailed`.

### Utilisation Combine & Closures

```swift
#if canImport(Combine)
import Combine

var cancellables = Set<AnyCancellable>()

api.liveCategoriesPublisher()
    .sink { completion in
        if case let .failure(error) = completion {
            print("Erreur Combine: \(error)")
        }
    } receiveValue: { categories in
        print("Catégories reçues: \(categories.count)")
    }
    .store(in: &cancellables)
#endif

api.liveStreams(in: "6") { result in
    switch result {
    case let .success(streams):
        print("Streams disponibles: \(streams.count)")
    case let .failure(error):
        print("Erreur closure: \(error)")
    }
}
```

### Configuration avancée du cache Live/EPG

```swift
import XtreamcodeSwiftAPI
import XtreamServices

let credentials = XtreamCredentials(username: "demo", password: "secret")

var configuration = XtreamcodeSwiftAPI.Configuration(
    baseURL: URL(string: "https://portal.example.com")!,
    credentials: credentials
)

configuration.liveCacheConfiguration = LiveCacheConfiguration(
    categoriesTTL: 6 * 3_600,
    streamsTTL: 1_800,
    streamURLsTTL: 300,
    diskOptions: .init(isEnabled: true, capacityInBytes: 100 * 1_024 * 1_024)
)

let cachedAPI = XtreamcodeSwiftAPI(configuration: configuration)

// Invalidation manuelle (ex : pull-to-refresh sur la catégorie "6")
try await cachedAPI.liveStreams(in: "6", forceRefresh: true)
```

La stratégie détaillée est décrite dans [`docs/live-cache-policy.md`](docs/live-cache-policy.md).

### Compatibilité plateformes & fonctionnalités

| Plateforme | Live TV | EPG | Catch-Up | Notes |
| --- | --- | --- | --- | --- |
| iOS 14+ | ✅ | ✅ | ✅ | Tests UI recommandés pour la lecture HLS. |
| macOS 12+ | ✅ | ✅ | ✅ | Nécessite AVPlayer pour la lecture live. |
| tvOS 15+ | ✅ | ✅ | ✅ | Prévoir gestion du remote Siri + lecture continue. |

### FAQ (troubleshooting)

- **`XtreamError.liveUnavailable`** : le portail n’a renvoyé aucune URL valide. Vérifiez l’état du flux côté Xtream Codes ou forcez un refresh (`forceRefresh: true`).
- **`XtreamError.epgUnavailable`** : l’EPG est vide pour la fenêtre demandée. Ajustez la plage `start/end` ou la limite et réessayez.
- **`XtreamError.catchupDisabled`** : le fournisseur n’expose pas le catch-up sur ce flux. Côté client, masquez l’action correspondante.
- **`XtreamError.vodUnavailable` / `seriesUnavailable`** : le catalogue ou les métadonnées ne sont pas disponibles. Vérifiez l’ID côté portail, forcez un `forceRefresh: true` ou retentez plus tard.
- **`XtreamError.searchFailed`** : la recherche globale a échoué (souvent lors d’une indisponibilité serveur). Réduisez le périmètre (`type: .movie` par exemple) ou retentez.
- **Problèmes de cache** : appelez `invalidateMediaCache()` après un changement de profil/utilisateur ou lors d’un logout forcé.
- **Diagnostic** : utilisez `await api.diagnosticsSnapshot()` pour récupérer les compteurs (hits/miss/fallback) et `await api.resetDiagnostics()` après analyse.

## Roadmap & Qualité

- [Roadmap](docs/roadmap.md)
- [Checklist Sprint 0](docs/sprint0.md)
- [Architecture](docs/architecture.md)
- [Qualité & CI](docs/quality.md)
- [Stratégie de tests](docs/testing.md)
- [Guide tvOS](docs/tvos/live-integration.md)
- [Observabilité](docs/observability.md)

## Contribuer

1. Créez une branche de fonctionnalité.
2. Exécutez les scripts `lint.sh` et `test.sh` avant de pousser.
3. Ouvrez une pull request en mentionnant les documents mis à jour (roadmap, TODO…).

## Licence

À définir (placeholder).
