# ``XtreamcodeSwiftAPI`` Séries

Gérez les catalogues séries, parcourez les saisons/épisodes et construisez les URLs de lecture.

## Initialisation

```swift
import XtreamcodeSwiftAPI

let api = XtreamcodeSwiftAPI(
    baseURL: URL(string: "https://portal.example.com")!,
    credentials: XtreamCredentials(username: "demo", password: "secret")
)
```

## Parcourir les séries

```swift
let categories = try await api.seriesCategories()

if let drama = categories.first {
    let shows = try await api.series(in: drama.id)
    print("Séries dans \(drama.name):", shows.map(\.name))
}
```

Les catégories/séries utilisent les mêmes TTL que le live (`categoriesTTL`, `streamsTTL`).

## Détails & URL d'épisode

```swift
let info = try await api.seriesDetails(for: 500)
print("Saisons:", info.seasons?.count ?? 0)

let episodeURL = try await api.seriesEpisodeURL(
    for: 500,
    season: 1,
    episode: 1
)
print("Lecture:", episodeURL)
```

L’URL est construite suivant le format Xtream Codes `series/{user}/{password}/{series_id}/{season}/{episode}.{ext}` (ou `direct_source` si fourni). En cas d’erreur, ``XtreamError/episodeNotFound(seriesID:season:episode:)`` est levé.

## Force refresh & offline fallback

```swift
do {
    let refresh = try await api.seriesEpisodeURL(for: 500, season: 1, episode: 1, forceRefresh: true)
    print(refresh)
} catch {
    print("Erreur série:", error)
}
```

- `forceRefresh: true` invalide la clé `series::episodeUrls` avant la requête.
- Une erreur réseau (`URLError.notConnectedToInternet`) sert automatiquement l’URL en cache et incrémente `offlineFallbacks`.

## Combine & closures

```swift
#if canImport(Combine)
import Combine

var cancellables = Set<AnyCancellable>()

api.seriesPublisher(in: nil)
    .sink(receiveCompletion: { print($0) }, receiveValue: { print($0.count) })
    .store(in: &cancellables)
#endif

api.seriesEpisodeURL(for: 500, season: 1, episode: 1) { result in
    print(result)
}
```
