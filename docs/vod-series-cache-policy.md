# Politique de Cache VOD & Séries

## Vue d'ensemble

Le SDK Xtreamcode Swift API réutilise l'infrastructure de cache existante (`LiveCacheStore`) pour les contenus VOD et Séries, garantissant une expérience utilisateur fluide et une réduction de la charge réseau.

## TTL par Type de Ressource

Le SDK utilise les mêmes TTL (Time To Live) que pour le contenu Live, configurables via `LiveCacheConfiguration` :

### Catalogues (Catégories & Listes)
- **VOD Categories** : `categoriesTTL` (défaut : 6 heures)
- **VOD Streams** : `streamsTTL` (défaut : 30 minutes)
- **Series Categories** : `categoriesTTL` (défaut : 6 heures)
- **Series** : `streamsTTL` (défaut : 30 minutes)

### Métadonnées Détaillées
- **VOD Info** : `streamDetailsTTL` (défaut : 30 minutes)
- **Series Info** : `streamDetailsTTL` (défaut : 30 minutes)

### Recherche
- **Search Results** : Non mis en cache (résultats dynamiques basés sur la requête)

## Configuration

### Configuration par Défaut

```swift
import XtreamcodeSwiftAPI

let api = XtreamcodeSwiftAPI(
    baseURL: URL(string: "https://example.com")!,
    credentials: XtreamCredentials(username: "user", password: "pass")
)
// Utilise LiveCacheConfiguration par défaut
```

### Configuration Personnalisée

```swift
var cacheConfig = LiveCacheConfiguration(
    categoriesTTL: 12 * 3600,      // 12 heures pour les catalogues
    streamsTTL: 1800,               // 30 minutes pour les listes
    streamDetailsTTL: 3600,         // 1 heure pour les métadonnées
    diskOptions: .init(
        isEnabled: true,
        capacityInBytes: 100 * 1024 * 1024  // 100 MB
    )
)

let api = XtreamcodeSwiftAPI(
    baseURL: URL(string: "https://example.com")!,
    credentials: XtreamCredentials(username: "user", password: "pass"),
    liveCacheConfiguration: cacheConfig
)
```

### Désactiver le Cache

```swift
let api = XtreamcodeSwiftAPI(
    baseURL: URL(string: "https://example.com")!,
    credentials: XtreamCredentials(username: "user", password: "pass"),
    liveCacheConfiguration: .disabled
)
```

## Clés de Cache

Les ressources VOD/Séries utilisent des clés de cache structurées :

### VOD
- `vod::categories::{username}` - Catégories VOD
- `vod::streams::{username}::{categoryID|all}` - Liste des films
- `vod::info::{username}::{vodID}` - Détails d'un film

### Séries
- `series::categories::{username}` - Catégories séries
- `series::items::{username}::{categoryID|all}` - Liste des séries
- `series::info::{username}::{seriesID}` - Détails d'une série (saisons/épisodes)

## Stratégie de Cache

### Cache Hybride (Mémoire + Disque)

Le SDK utilise un cache hybride à deux niveaux :

1. **Mémoire** (`InMemoryLiveCacheStore`) : Cache rapide avec éviction LRU
2. **Disque** (`DiskLiveCacheStore`) : Persistance entre sessions

```swift
// Configuration avancée avec cache custom
let memoryStore = InMemoryLiveCacheStore()
let diskStore = DiskLiveCacheStore(
    directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first,
    capacityInBytes: 200 * 1024 * 1024  // 200 MB
)
let customCache = HybridLiveCacheStore(
    memoryStore: memoryStore,
    diskStore: diskStore,
    ttlProvider: { cacheConfig.ttl(for: $0) }
)

let api = XtreamcodeSwiftAPI(
    baseURL: URL(string: "https://example.com")!,
    credentials: XtreamCredentials(username: "user", password: "pass"),
    liveCacheConfiguration: cacheConfig,
    liveCacheStore: customCache
)
```

## Invalidation Manuelle

### Invalidation Globale

```swift
// Invalider tout le cache (Live + VOD + Séries)
await api.invalidateMediaCache()
```

### Invalidation Sélective

```swift
// Via les clés de cache spécifiques (niveau avancé)
let cacheKey = LiveCacheKey.vodCategories(username: "user")
// Note : invalidation sélective nécessite accès direct au cache store
```

### Invalidation Automatique

Le cache est automatiquement invalidé lors de :
- Déconnexion (`logout()`)
- Changement de credentials
- Refresh d'authentification

## Mode Offline & Fallback

Lorsque `forceRefresh: true` est utilisé et qu'une erreur réseau survient, le SDK tente de restaurer les données en cache même si le TTL est expiré :

```swift
do {
    // Tente de récupérer les dernières données
    let categories = try await api.vodCategories(forceRefresh: true)
} catch {
    // Si offline, les données en cache expirées seront retournées si disponibles
    print("Erreur : \(error)")
}
```

### Détection des Erreurs Offline

Le SDK détecte automatiquement les erreurs réseau suivantes :
- `NSURLErrorNotConnectedToInternet`
- `NSURLErrorNetworkConnectionLost`
- `NSURLErrorTimedOut`
- `NSURLErrorCannotFindHost`
- `NSURLErrorCannotConnectToHost`

## Diagnostics & Métriques

Le SDK expose des compteurs de cache via `XtreamDiagnostics` :

```swift
let snapshot = await api.diagnosticsSnapshot()
print("Cache hits: \(snapshot.cacheHits)")
print("Cache misses: \(snapshot.cacheMisses)")
print("Offline fallbacks: \(snapshot.offlineFallbacks)")
```

## Logging

Pour débugger le comportement du cache :

```swift
import XtreamServices

let logger = DefaultLiveLogger()
let api = XtreamcodeSwiftAPI(
    baseURL: URL(string: "https://example.com")!,
    credentials: XtreamCredentials(username: "user", password: "pass"),
    logger: logger
)

// Les événements suivants seront loggés :
// - .cacheHit(key:source:)
// - .cacheMiss(key:)
// - .offlineFallback(key:)
```

## Bonnes Pratiques

1. **Catalogues** : Utiliser un TTL long (6-12h) car les catalogues changent rarement
2. **Métadonnées** : TTL moyen (30min-1h) pour équilibrer fraîcheur et performance
3. **Mode Offline** : Activer le cache disque pour une meilleure expérience hors ligne
4. **Recherche** : Ne pas cacher les résultats de recherche (dynamiques)
5. **Diagnostics** : Monitorer les métriques en production pour ajuster les TTL

## Exemples d'Usage

### Récupération avec Cache par Défaut

```swift
// Utilise le cache automatiquement
let vodCategories = try await api.vodCategories()
let series = try await api.series(in: "357")
let vodInfo = try await api.vodDetails(for: 130529)
```

### Force Refresh avec Fallback

```swift
// Ignore le cache, mais utilise fallback si offline
let freshCategories = try await api.vodCategories(forceRefresh: true)
```

### Gestion des Erreurs Cache

```swift
do {
    let categories = try await api.vodCategories()
} catch let error as XtreamError {
    switch error {
    case .vodUnavailable(let vodID, let reason):
        print("VOD \(vodID) indisponible : \(reason)")
    default:
        print("Erreur : \(error)")
    }
}
```

## Notes Importantes

- Le cache est **thread-safe** et compatible avec Swift Concurrency
- Les données en cache sont **sérialisées en JSON** (via `Codable`)
- Le cache disque utilise **gzip** pour réduire l'espace disque
- La **purge automatique** s'exécute périodiquement pour respecter la limite de capacité
- Le cache est **isolé par utilisateur** (inclus dans la clé de cache)
