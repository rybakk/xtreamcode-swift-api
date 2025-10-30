# Architecture Proposée

## Vue d’Ensemble

Le SDK s’articule autour d’une couche réseau pilotée par Alamofire, d’un modèle de données fortement typé (Codable),
et de services spécialisés pour la gestion de cache, d’état de session et des adaptateurs de consommation (async/await,
Combine, closures). L’objectif est de maintenir un découplage fort entre les services métiers et la bibliothèque réseau.

```
App → XtreamSDKFacade
    → XtreamClient (Alamofire)
    → XtreamModelStore (cache)
    → XtreamAuthService / XtreamCatalogService / XtreamPlaybackService
    → XtreamModels (Entities)
```

## Modules

### 1. XtreamSDKFacade (Module principal)
- Point d’entrée public exposant les méthodes de haut niveau (`login`, `fetchLiveChannels`, etc.).
- S’appuie sur des services internes et coordonne la gestion d’erreurs.
- Fournit des APIs `async/await` ainsi que des adaptateurs Combine (`Publisher`) et callbacks.

### 2. XtreamClient (Couche réseau)
- Wrapper autour d’Alamofire `Session` avec configuration injectée (`URLSessionConfiguration`, `RequestInterceptor`).
- Expose des méthodes génériques (`request<T: Decodable>(endpoint: XtreamEndpoint)`) retournant des `XtreamResponse`.
- Gère la transformation des erreurs réseau (HTTP, décodage, timeout) vers `XtreamError`.
- Intègre un système d’observabilité (logs, métriques) optionnel.

### 3. XtreamEndpoints
- Enum ou structure décrivant les routes Xtream Codes (path, paramètres, HTTP method).
- Produit des requêtes Alamofire (`URLRequestConvertible`), centralisant la construction d’URL, headers, query.
- Permet des tests contractuels sur la cohérence des endpoints.

### 4. XtreamModels
- Structures `Codable` correspondant aux schémas JSON/XML retournés (UserInfo, LiveChannel, VodItem, SeriesDetail, EPGEntry…).
- Encapsule la logique de parsing spécifique (dates, formats polymorphes).
- Fournit des sous-modèles pour la configuration (auth credentials, device info).

### 5. XtreamServices
- **XtreamAuthService** : login (implémenté), logout/refresh à compléter.
- Gestion des erreurs d’authentification exposées via `XtreamAuthError` (credentials invalides, compte expiré, connexions max).
- **XtreamLiveService** : catégories, chaînes, URL streaming, EPG, catch-up.
- **XtreamVodService** : catalogues films, métadonnées, playback.
- **XtreamSeriesService** : séries, saisons, épisodes.
- **XtreamSearchService** : recherche multi-supports.
- **XtreamFavoritesService** : gestion favoris (serveur/local).
- **XtreamDvrService** (optionnel) : enregistrements si support.
- Chaque service consomme `XtreamClient` et interagit avec `XtreamModelStore` pour le cache.

### 6. XtreamModelStore
- Gestionnaire de cache (mémoire + disque). Propose des politiques TTL configurables.
- Stocke EPG, listes de catalogues, métadonnées fréquemment réutilisées.
- Expose une interface `XtreamCache` testable (implémentations : in-memory, SQLite/CoreData optionnelle).

### 7. Adaptateurs et Utilitaires
- **XtreamAsyncAdapter** : expose des méthodes `async` appelant les services.
- **XtreamCombineAdapter** : publie des `AnyPublisher`.
- **XtreamCallbackAdapter** : API closures pour compatibilité.
- **Logging/Monitoring** : protocole `XtreamLogger` pour injecter des collecteurs.
- **Configuration** : `XtreamClientConfiguration` (baseURL, credentials, device info, cache policy, log level).

## Gestion des Erreurs

- Type central `XtreamError` avec cas : `network`, `decoding`, `unauthorized`, `notFound`, `server`, `unsupported`.
- Conversion automatique depuis `AFError`/`URLError` et les réponses HTTP.
- Fournir des informations additionnelles (status code, endpoint, payload de diagnostic).

## Sécurité

- Aucun stockage persistant des identifiants : ils sont fournis à l’instanciation du SDK (ou via un provider injecté) et restent gérés par l’application hôte.
- Pinning TLS optionnel (configurable dans `XtreamClientConfiguration`).
- Support multi-utilisateur possible via `profileId`.

## Tests & Mocks

- Protocole `NetworkSession` pour mocker Alamofire (utilisation de `URLProtocol` custom).
- Génération de fixtures JSON pour chaque endpoint (basées sur `docs/endpoints.md`).
- Tests unitaires ciblant les services (ex. `XtreamLiveServiceTests` vérifiant mapping).
- Tests d’intégration légers avec un serveur stub (ex. `swift test --filter Integration`).

## Points d’Évolution

- Modules optionnels : `XtreamStorage` (cache disque avancé), `XtreamAnalytics`.
- Prévoir la compatibilité future avec watchOS ou visionOS si demandé.
- Abstraction possible pour injection d’un moteur réseau autre qu’Alamofire (future proof).
