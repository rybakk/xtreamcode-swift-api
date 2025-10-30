# ``XtreamcodeSwiftAPI`` VOD

Découvrez comment parcourir le catalogue VOD, récupérer les métadonnées complètes et générer les URLs de lecture.

## Avant de commencer

```swift
import XtreamcodeSwiftAPI

let api = XtreamcodeSwiftAPI(
    baseURL: URL(string: "https://portal.example.com")!,
    credentials: XtreamCredentials(username: "demo", password: "secret")
)
```

## Charger les catégories et films

```swift
let categories = try await api.vodCategories()

if let action = categories.first {
    let movies = try await api.vodStreams(in: action.id)
    print("Films disponibles dans \(action.name):", movies.count)
}
```

Les réponses sont automatiquement mises en cache (TTL configurables via ``LiveCacheConfiguration``). Utilisez `forceRefresh: true` pour rafraîchir la catégorie ciblée.

## Métadonnées détaillées & URL de lecture

```swift
let details = try await api.vodDetails(for: 130_529)
print(details.info?.plot ?? "-")

let playbackURL = try await api.vodStreamURL(for: 130_529)
print("URL de lecture:", playbackURL.absoluteString)
```

``XtreamVODInfo`` expose les données TMDB (affiches, synopsis, genres) ainsi que les informations codecs (`video`/`audio`). ``XtreamcodeSwiftAPI/vodStreamURL(for:forceRefresh:)`` retourne soit l’URL directe fournie par le portail, soit l’URL calculée (`movie/{user}/{password}/{stream}.{ext}`).

## Gestion du cache & offline

- Les clés VOD réutilisent `LiveCacheStore` (`vod::categories`, `vod::streams`, `vod::info`, `vod::streamUrls`).
- Avec `forceRefresh: true`, un échec réseau (`URLError.notConnectedToInternet`) déclenche automatiquement un fallback sur la dernière valeur en cache et incrémente les diagnostics (`offlineFallbacks`).

```swift
let diagnostics = await api.diagnosticsSnapshot()
print("Hits:", diagnostics.liveCacheHits, "Misses:", diagnostics.liveCacheMisses)
```

## Adaptateurs Combine & Closures

```swift
#if canImport(Combine)
import Combine

var cancellables = Set<AnyCancellable>()

api.vodCategoriesPublisher()
    .sink(receiveCompletion: { print($0) }, receiveValue: { print($0.count) })
    .store(in: &cancellables)
#endif

api.vodStreamURL(for: 130_529) { result in
    print(result)
}
```

Les adaptateurs reposent sur la même logique interne (cache + fallback offline) et retournent des `Task` annulables.
