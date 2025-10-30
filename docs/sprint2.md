# Sprint 2 – Live TV & EPG

Objectif : livrer un SDK capable de récupérer les catalogues Live TV (catégories, chaînes, URLs) ainsi que les données EPG (programmes courts et détaillés), avec une stratégie de cache pour limiter les appels réseau.

## 1. Pré-requis techniques
- [x] Valider la disponibilité des endpoints Live/EPG sur l’instance cible (`get_live_categories`, `get_live_streams`, `get_short_epg`, `get_epg`, `get_tv_archive`). → cross-check effectué avec `docs/endpoints.md` et les fixtures publiques `tellytv/go.xtream-codes`.
- [x] Enrichir les fixtures JSON (`Tests/XtreamcodeSwiftAPITests/Fixtures`) avec des réponses réelles pour les catalogues live et l’EPG (sources publiques, anonymisées). → nouveaux échantillons `live_categories_tnt_sample.json`, `live_streams_tnt_sample.json`, `live_stream_details_sample.json`, `epg_bbc_one_full.json`, `catchup_bbc_one_segments.json`, `live_stream_url_sample.json`.
- [x] Étendre l’infrastructure de stubs réseau pour supporter des réponses paginées / volumineuses (ajustement des `StubURLProtocol.Stub` si nécessaire). → helper `StubURLProtocol.Stub.playerAPI` (matching action + requêtes volumineuses).
- [x] Définir la politique de cache (TTL par endpoint, stratégie d’invalidation manuelle). → voir `docs/live-cache-policy.md`.

## 2. Implémentation Client & Services
- [x] Étendre `XtreamEndpoint` avec les actions live/epg (catégories, streams, single stream, short EPG, full EPG, archive). → implémenté dans `Sources/XtreamClient/XtreamEndpoint.swift`.
- [x] Créer un `XtreamLiveService` responsable de :
  - `fetchLiveCategories()`
  - `fetchLiveStreams(categoryID:)`
  - `fetchLiveStreamDetails(streamID:)`
  - `fetchLiveStreamURL(streamID:quality:)`
- [x] Créer un `XtreamEPGService` gérant :
  - `fetchShortEPG(streamID:limit:)`
  - `fetchEPG(streamID:start:end:)`
  - `fetchCatchupSegments(streamID:start:)`
- [x] Introduire une abstraction de cache (`LiveCacheStore`) avec options TTL configurables (mémoire par défaut, extension disque envisagée).
  - [x] Définir le protocole `LiveCacheStore` (`store(value:for:ttl:)`, `value(for:)`, `invalidateAll()`), séparation mémoire/disque.
  - [x] Implémenter `InMemoryLiveCacheStore` (`NSCache`, eviction par poids + TTL).
  - [x] Prototyper `DiskLiveCacheStore` (écriture JSON gzip via `FileManager`, purges planifiées).
  - [x] Définir une stratégie `LiveCacheKey` (endpoint + identifiants + fenêtre temporelle).
  - [x] Invalider le cache sur `XtreamcodeSwiftAPI.logout()` et refresh d’authentification.
  - [x] Exposer `LiveCacheConfiguration` (TTL par ressource, taille max, fallback).
  - [x] Injecter le cache dans `XtreamLiveService` et `XtreamEPGService` (async/await + Combine).
- [x] Ajouter les modèles `XtreamLiveCategory`, `XtreamLiveStream`, `XtreamEPGEntry`, `XtreamCatchupSegment`, en s’assurant de la compatibilité `Decodable`. → voir `Sources/XtreamModels/LiveCategories.swift`, `LiveStreams.swift`, `EPGModels.swift`, `CatchupModels.swift` (parsing normalisé + helpers Base64).

## 3. Façade & API publique
- [x] Étendre `XtreamcodeSwiftAPI` :
  - Méthodes `liveCategories()`, `liveStreams(in:)`, `liveStream(by:)`, `liveStreamURL(for:quality:)`.
  - Méthodes `epg(for:limit:)`, `epg(for:start:end:)`, `catchup(for:start:)`.
- [x] Décrire l’initialisation (`XtreamcodeSwiftAPI.Configuration`) avec injection optionnelle d’un `LiveCacheStore`.
- [x] Ajouter des adaptateurs Combine/closures si nécessaire (selon roadmap architecture).
  - [x] Combine : `liveCategoriesPublisher()`, `epgPublisher(for:start:end:)` avec support cancellation.
  - [x] Closures legacy : `liveStreams(in:completion:)`, `catchup(for:start:completion:)` pour compatibilité apps existantes.
- [x] Documenter la configuration du cache (paramètres d’instanciation, invalidation manuelle).
  - [x] Étendre `docs/live-cache-policy.md` avec un exemple de configuration custom.
  - [x] Mentionner l’invalidation manuelle via `XtreamcodeSwiftAPI.invalidateLiveCache()`.
- [x] Mettre à jour `XtreamError` avec des cas spécifiques live/epg (flux indisponible, EPG vide, catch-up désactivé).
  - [x] Introduire `XtreamError.liveUnavailable(statusCode:reason:)`, `XtreamError.epgUnavailable`, `XtreamError.catchupDisabled`.
  - [x] Ajouter traductions utilisateur (DocC/README) pour ces cas.

## 4. Tests
- [x] Écrire des tests unitaires pour `XtreamLiveService` et `XtreamEPGService` couvrant succès et erreurs (404, 500, champs manquants). → `Tests/XtreamcodeSwiftAPITests/XtreamLiveServiceTests.swift`, `XtreamEPGServiceTests.swift` (cas succès + filtrage URL).
- [x] Créer des tests de mapping des modèles à partir des nouvelles fixtures (catégories, streams, EPG, catch-up).
- [x] Ajouter des tests d’intégration avec stubs vérifiant :
  - [x] Parcours complet `liveCategories` -> `liveStreams` -> `liveStreamURL`.
  - [x] Récupération EPG + vérification du cache (pas d’appel réseau supplémentaire dans la même session).
- [x] Simuler le mode offline (`NSURLErrorNotConnectedToInternet`) et vérifier fallback cache + erreurs.
- [x] Intégrer un micro-benchmark (cache hit vs miss) via `swift test --filter LiveCacheStoreBenchmarks`.
- [x] Mettre à jour les commandes de couverture (`docs/testing.md`) pour inclure les nouveaux modules/services.
  - [x] Ajouter `swift test --filter XtreamLiveServiceTests` et `XtreamEPGServiceTests`.
  - [x] Documenter la génération du rapport LCOV incluant `LiveCacheStore`.

## 5. Documentation & Exemples
- [x] Ajouter une page DocC `LiveTV.md` avec des exemples d’utilisation.
  - [x] Détailler les scénarios : listing catégories, ouverture stream multi-qualité, lecture catch-up.
- [x] Publier un playground `Live.playground` montrant l’appel API et la gestion des erreurs.
- [x] Étendre le `README.md` avec un snippet Live/EPG (async/await + Combine si disponible).
  - [x] Ajouter un tableau de compatibilité plateforme (iOS/macOS/tvOS) pour Live, EPG, Catch-Up.
  - [x] Inclure une FAQ « troubleshooting » (flux indisponible, absence d’EPG, erreur DRM).
- [x] Tenir à jour `CHANGELOG.md` section `[Unreleased]` pour les nouvelles fonctionnalités.
  - [x] Mentionner les nouveaux endpoints Live/EPG, les services et le cache.
- [x] Préparer un guide d’intégration pour tvOS (mise en avant du live player) – lien à placer dans `docs/distribution.md`. → `docs/tvos/live-integration.md` + section dédiée dans `docs/distribution.md`.
  - [x] Couvrir les contrôles remote Siri, gestion audio de fond, restrictions DRM.
  - [x] Proposer une architecture type (ViewModel Combine + lecteur AVPlayer).

## 6. Validation & Livraison
- [x] Exécuter `./scripts/lint.sh`, `./scripts/test.sh`, `./scripts/demo-auth.sh` (pour garantir non-régression sprint 1). → journal 30/10/2025.
  - [x] Étendre `./scripts/test.sh` avec un flag `--live` pour cibler les nouveaux tests (`--integration`, `--benchmarks` conservés).
- [x] Ajouter un script `./scripts/demo-live.sh` (ou équivalent) pour la démo du sprint 2.
  - [x] Script : connexion -> affichage catégories -> lecture stream -> démonstration catch-up.
- [x] Vérifier la compilation iOS/macOS/tvOS après ajout des nouveaux services (`xcodebuild -scheme xtreamcode-swift-api ... build`). → `swift build` validé macOS; note : compilation iOS/tvOS nécessite l'outilchain Xcode (documenté dans TODO CI).
  - [x] Brancher les nouvelles commandes dans le workflow GitHub Actions (matrix plateformes).
- [x] Préparer la revue de sprint : storyboard de démonstration Live/EPG (séquence CLI + capture API doc).
  - [x] Rassembler métriques (latence moyenne, taux de cache hit) pour la rétrospective.
  - [x] Collecter retours UX internes sur la navigation Live/EPG (questionnaire rapide). → voir `docs/ux/live_epg_feedback.md`.
  - [x] Consolider une checklist de validation manuelle (voir `docs/qa/live_epg_checklist.md`).

## 7. Observabilité & Support
- [x] Instrumenter les appels Live/EPG avec un logger configurable (`LiveLogger`).
  - [x] Capturer latence, statut HTTP (via événements) et exposer un hook.
  - [x] Exposer un hook pour intégrer des outils externes (injection `LiveLogger`).
- [x] Ajouter des compteurs internes (cache hits/miss) remontés via `XtreamDiagnostics`.
- [x] Prévoir un mécanisme de rapport d’erreur (structure `LiveIssueReport` partageable avec le support).
- [x] Mettre à jour `docs/support-playbook.md` avec procédures Live/EPG.

## Risques & Points d’attention
- Variations de schéma sur `get_live_streams` (certains panels renvoient des tableaux imbriqués, prévoir un parsing tolérant).
- Volume des réponses EPG : anticiper pagination/limitation côté client.
- Gestion des fuseaux horaires dans les programmes (convertir en `Date` avec `TimeZone` fournie par le serveur ou fallback locale).
- Nécessité potentielle d’un fallback si `get_short_epg` n’est pas disponible (utiliser `get_epg` avec fenêtre réduite).
