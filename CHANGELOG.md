# Changelog

Tous les changements notables seront consignés dans ce fichier.

Le format est inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et ce projet suit [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-30

### Added

#### Fondation & Architecture (Sprint 0)
- Initialisation du package Swift avec swift-tools-version 6.2
- Configuration SwiftLint et SwiftFormat pour qualité de code
- Mise en place de GitHub Actions avec workflow CI multi-plateformes (iOS, macOS, tvOS)
- Configuration de la dépendance Alamofire 5.10.2
- Structure modulaire : `XtreamModels`, `XtreamClient`, `XtreamServices`, `XtreamSDKFacade`
- Documentation DocC et guides d'intégration

#### Authentification & Compte (Sprint 1)
- Client réseau basé sur Alamofire (`XtreamClient`, `XtreamEndpoint`)
- Services d'authentification : `login()`, `refreshSession()`, `logout()`
- Services de compte : `fetchAccountDetails()`, profil utilisateur, informations serveur
- Façade publique `XtreamcodeSwiftAPI` avec gestion sécurisée des credentials
- Gestion détaillée des erreurs (`XtreamAuthError`) : credentials invalides, compte expiré, trop de connexions
- Tests unitaires et d'intégration avec `StubURLProtocol`
- Documentation DocC `Authentication.md` et script de démo `demo-auth.sh`

#### Live TV & EPG (Sprint 2)
- Services Live TV : catégories, chaînes, URLs multi-qualités, statut en direct
- Services EPG : guide des programmes sur 7 jours, catch-up TV, favoris
- Cache hybride intelligent (`LiveCacheStore`) :
  - Cache mémoire (`InMemoryLiveCacheStore`) avec NSCache
  - Cache disque (`DiskLiveCacheStore`) avec FileManager
  - Configuration TTL par type de ressource
  - Invalidation automatique lors de logout/refresh session
- Méthodes publiques : `liveCategories()`, `liveStreams()`, `epg()`, `catchup()`, `liveStreamURL()`
- Support `forceRefresh` avec fallback offline graceful
- Adaptateurs Combine (publishers) et closures pour compatibilité legacy
- Erreurs typées : `liveUnavailable`, `epgUnavailable`, `catchupDisabled`
- Benchmarks de performance du cache
- Documentation : DocC `LiveTV.md`, guide tvOS, politique de cache
- Tests complets : unitaires, intégration, benchmarks

#### VOD & Séries TV (Sprint 3)
- Services VOD : catégories, catalogues films, métadonnées détaillées (TMDB/IMDB)
- Services Séries : catégories, séries, saisons, épisodes avec métadonnées complètes
- Service de recherche transversale unifié (Live/VOD/Séries)
- 7 nouveaux endpoints REST : `get_vod_categories`, `get_vod_streams`, `get_vod_info`, `get_series_categories`, `get_series`, `get_series_info`, `search`
- Méthodes publiques : `vodCategories()`, `vodStreams()`, `vodDetails()`, `vodStreamURL()`, `seriesCategories()`, `series()`, `seriesDetails()`, `seriesEpisodeURL()`, `search()`
- Support `direct_source` pour URLs de streaming optimisées
- Extension du cache hybride pour VOD/Séries avec TTL configurables
- Système de suivi de progression (`ProgressStore`, `UserDefaultsProgressStore`)
- Méthodes de progression : `saveProgress()`, `loadProgress()`, `clearProgress()`
- Parsing tolérant avec structures imbriquées : `Season`, `Episode`, `MovieInfo`, `AudioTrack`, `Subtitle`
- Erreurs typées : `vodUnavailable`, `seriesUnavailable`, `episodeNotFound`, `searchFailed`
- Adaptateurs Combine et closures pour toutes les APIs VOD/Séries
- Tests end-to-end avec cache et mode offline
- Documentation : DocC `VOD.md`, `Series.md`, `Search.md`, politique de cache VOD/Séries
- Job GitHub Actions `vod-series-tests`

#### Distribution & Tooling (Sprint 4)
- CocoaPods podspec v1.0.0 avec support iOS 14+, macOS 12+, tvOS 15+
- Scripts de build et validation : `spm-build.sh`, `pod-lint.sh`, `test.sh`
- Scripts de démo : `demo-auth.sh`, `demo-live.sh`, `demo-vod-series.sh`
- Workflow GitHub Actions complet : lint, tests unitaires, tests d'intégration, tests Live/EPG, tests VOD/Séries, benchmarks, build multi-plateformes

### Technical Details

- **Plateformes supportées** : iOS 14+, macOS 12+, tvOS 15+
- **Swift** : 5.10+ (avec support Swift 6.0)
- **Dépendances** : Alamofire 5.10.2+
- **API moderne** : async/await, Combine publishers, closures legacy
- **Tests** : 39 tests unitaires et d'intégration (100% de réussite)
- **Cache** : Hybride mémoire/disque avec TTL configurables
- **Documentation** : DocC complète avec guides et exemples

[1.0.0]: https://github.com/your-org/xtreamcode-swift-api/releases/tag/v1.0.0
