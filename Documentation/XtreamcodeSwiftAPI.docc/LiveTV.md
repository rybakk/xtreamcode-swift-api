# ``XtreamcodeSwiftAPI`` Live & EPG

Apprenez à exploiter les API Live TV et EPG tout en profitant du cache hybride intégré.

## Avant de commencer

```swift
import XtreamcodeSwiftAPI

let api = XtreamcodeSwiftAPI(
    baseURL: URL(string: "https://portal.example.com")!,
    credentials: XtreamCredentials(username: "demo", password: "secret")
)
```

## Récupérer les catégories et canaux

```swift
let categories = try await api.liveCategories()

guard let category = categories.first else { return }
let streams = try await api.liveStreams(in: category.id)
```

Chaque appel lit d'abord les données en cache (`LiveCacheStore`), puis effectue une requête réseau si nécessaire. Utilisez `forceRefresh: true` pour invalider la clé ciblée.

## Obtenir l'EPG et les URLs multi-qualité

```swift
guard let stream = streams.first else { return }

let epgEntries = try await api.epg(for: stream.id, limit: 5)

let streamURL = try await api.liveStreamURL(for: stream.id, quality: "1080p")
```

La méthode `liveStreamURL(for:quality:)` retourne par défaut la première variante disponible et s'efforce de respecter la qualité demandée (fallback sur la meilleure alternative sinon).

## Catch-up TV

```swift
if let catchup = try await api.catchup(for: stream.id) {
    for segment in catchup.segments {
        print("Replay disponible:", segment.title ?? "Épisode")
    }
}
```

Les segments sont mis en cache (TTL 30 minutes) et automatiquement purgés lors d'un `logout()` ou d'un `refreshSession()`.

## Configurer finement le cache

```swift
import XtreamServices

var configuration = XtreamcodeSwiftAPI.Configuration(
    baseURL: URL(string: "https://portal.example.com")!,
    credentials: credentials
)

configuration.liveCacheConfiguration = LiveCacheConfiguration(
    streamURLsTTL: 120,
    diskOptions: .init(isEnabled: true, capacityInBytes: 80 * 1_024 * 1_024)
)

let api = XtreamcodeSwiftAPI(configuration: configuration)
```

Consultez ``XtreamcodeSwiftAPI/invalidateLiveCache()`` pour purger manuellement tous les artefacts (ex : changement profond de profil côté client).

## Gestion des erreurs

- ``XtreamError/liveUnavailable(statusCode:reason:)`` : aucune URL valide renvoyée ou refus serveur pour le flux demandé.
- ``XtreamError/epgUnavailable(reason:)`` : guide des programmes vide ou indisponible pour la fenêtre demandée.
- ``XtreamError/catchupDisabled(reason:)`` : fonctionnalité catch-up désactivée ou non fournie par le portail.

Ces erreurs sont propagées par ``XtreamcodeSwiftAPI/liveStreamURL(for:quality:forceRefresh:)``, ``XtreamcodeSwiftAPI/epg(for:start:end:forceRefresh:)`` et ``XtreamcodeSwiftAPI/catchup(for:start:forceRefresh:)``. Utilisez `forceRefresh` après avoir résolu le problème côté utilisateur pour relancer une requête réseau.

## Adaptateurs Combine & Closures

```swift
#if canImport(Combine)
import Combine

var cancellables = Set<AnyCancellable>()

api.liveCategoriesPublisher()
    .sink(receiveCompletion: { print($0) }, receiveValue: { print($0.count) })
    .store(in: &cancellables)
#endif

api.liveStreams(in: "6") { result in
    print("Résultat closure: \(result)")
}
```

Les méthodes `Publisher` retournent un `AnyPublisher` annulable (annulation = `Task.cancel()` interne). Les variantes closures retournent un `Task<Void, Never>` pour supporter l'annulation manuelle si nécessaire.
