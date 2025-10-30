# ``XtreamcodeSwiftAPI`` Recherche

Unifiez la recherche Live/VOD/Séries et filtrez les résultats selon le type souhaité.

## Recherche globale

```swift
let results = try await api.search(query: "demo")
for item in results {
    switch item.type {
    case .live:
        print("Live:", item.name)
    case .movie:
        print("Film:", item.name)
    case .series:
        print("Série:", item.name)
    case .all:
        break
    }
}
```

Les résultats contiennent l’identifiant (`id`), la catégorie, l’icône/cover et un `XtreamSearchResultType` discriminant (`live`, `movie`, `series`).

## Filtrer par type

```swift
let moviesOnly = try await api.search(query: "demo", type: .movie)
print("Films trouvés:", moviesOnly.count)
```

Pour les tests UI, combinez l’icône (`streamIcon`/`cover`) et la catégorie pour orienter l’utilisateur vers le bon parcours (Live Player, fiche VOD, vue épisode).

## Combine & closures

```swift
#if canImport(Combine)
import Combine

var cancellables = Set<AnyCancellable>()

api.searchPublisher(query: "demo", type: .series)
    .sink(receiveCompletion: { print($0) }, receiveValue: { print($0.count) })
    .store(in: &cancellables)
#endif

api.search(query: "demo") { result in
    print(result)
}
```

Les résultats ne sont pas mis en cache (données dynamiques). Gérez manuellement un cache applicatif si besoin (ex. `NSCache` ou `IdentifiedArray`).
