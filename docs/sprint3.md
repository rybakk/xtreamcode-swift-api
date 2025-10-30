# Sprint 3 – VOD & Séries

Objectif : livrer un SDK capable de récupérer les catalogues VOD (films) et Séries TV avec métadonnées détaillées (titres, résumés, posters, saisons/épisodes, sous-titres), gérer la recherche transversale (live, VOD, séries) et le suivi de progression optionnel.

## 1. Pré-requis techniques
- [x] Valider la disponibilité des endpoints VOD/Séries sur l'instance cible (`get_vod_categories`, `get_vod_streams`, `get_vod_info`, `get_series_categories`, `get_series`, `get_series_info`). → cross-check avec `docs/endpoints.md` et fixtures publiques (validé via fixtures existantes).
- [x] Enrichir les fixtures JSON (`Tests/XtreamcodeSwiftAPITests/Fixtures`) avec des réponses réelles pour les catalogues VOD et Séries (métadonnées complètes, saisons multiples, sous-titres).
  - [x] Ajouter `vod_info_detailed_sample.json` (film avec multiples qualités, sous-titres, métadonnées TMDB).
  - [x] Ajouter `series_info_full_sample.json` (série multi-saisons avec épisodes, posters, résumés).
  - [x] Ajouter `search_results_mixed_sample.json` (résultats combinés live/vod/series).
- [x] Étendre l'infrastructure de stubs réseau pour supporter les réponses VOD/Séries volumineuses (ajustement `StubURLProtocol.Stub` si nécessaire) → modèles supportent parsing tolérant.
- [x] Définir la politique de cache pour VOD/Séries (TTL par endpoint, invalidation manuelle). → créer `docs/vod-series-cache-policy.md`.

## 2. Implémentation Client & Services
- [x] Étendre `XtreamEndpoint` avec les actions VOD/Séries :
  - [x] `get_vod_categories`
  - [x] `get_vod_streams` (avec paramètre `category_id` optionnel)
  - [x] `get_vod_info` (métadonnées détaillées film)
  - [x] `get_series_categories`
  - [x] `get_series` (avec paramètre `category_id` optionnel)
  - [x] `get_series_info` (métadonnées saisons/épisodes)
  - [x] `search` (recherche transversale avec type optionnel)
- [x] Créer un `XtreamVODService` responsable de :
  - [x] `fetchCategories()`
  - [x] `fetchStreams(categoryID:)`
  - [x] `fetchDetails(vodID:)`
  - [ ] `fetchVODStreamURL(vodID:quality:)` (à implémenter si nécessaire)
- [x] Créer un `XtreamSeriesService` gérant :
  - [x] `fetchCategories()`
  - [x] `fetchSeries(categoryID:)`
  - [x] `fetchDetails(seriesID:)` (avec saisons/épisodes)
  - [ ] `fetchEpisodeURL(seriesID:season:episode:)` (à implémenter si nécessaire)
- [x] Créer un `XtreamSearchService` pour :
  - [x] `search(query:type:)` (type: `.all`, `.live`, `.movie`, `.series`)
  - [x] Retourner résultats mixtes avec indicateur de type
- [x] Étendre le cache existant (`LiveCacheStore`) pour VOD/Séries :
  - [x] Utiliser TTL existants (streamsTTL, streamDetailsTTL) pour VOD/Séries.
  - [x] Injecter le cache dans les services VOD/Séries.
- [x] Ajouter les modèles Swift :
  - [x] `XtreamVODCategory`, `XtreamVODStream`, `XtreamVODInfo` (avec `MovieInfo`, qualités, sous-titres).
  - [x] `XtreamSeriesCategory`, `XtreamSeries`, `XtreamSeriesInfo` (avec `Season`, `Episode`).
  - [x] `XtreamSearchResult` (type discriminé : live/movie/series).
  - [x] Assurer compatibilité `Decodable` et parsing tolérant (champs optionnels).

## 3. Façade & API publique
- [x] Étendre `XtreamcodeSwiftAPI` :
  - [x] Méthodes VOD : `vodCategories()`, `vodStreams(in:)`, `vodDetails(for:)`.
  - [x] Méthodes Séries : `seriesCategories()`, `series(in:)`, `seriesDetails(for:)`.
  - [x] Méthode recherche : `search(query:type:)`.
  - [x] Support `forceRefresh` et fallback offline pour toutes les méthodes VOD/Séries.
- [x] Ajouter adaptateurs Combine/closures pour VOD/Séries (optionnel) :
  - [x] Combine : `vodCategoriesPublisher()`, `seriesDetailsPublisher(for:)`, `searchPublisher(query:type:)`.
  - [x] Closures legacy : `vodStreams(in:completion:)`, `seriesDetails(for:completion:)`.
- [x] Documenter la configuration du cache VOD/Séries :
  - [x] Créer `docs/vod-series-cache-policy.md` avec exemples de configuration custom.
  - [x] Mentionner l'invalidation manuelle via `XtreamcodeSwiftAPI.invalidateMediaCache()`.
- [x] Mettre à jour `XtreamError` avec cas spécifiques VOD/Séries :
  - [x] `XtreamError.vodUnavailable(vodID:reason:)`.
  - [x] `XtreamError.seriesUnavailable(seriesID:reason:)`.
  - [x] `XtreamError.episodeNotFound(series:season:episode:)`.
  - [x] `XtreamError.searchFailed(query:reason:)`.
  - [x] Ajouter traductions utilisateur (DocC/README).

## 4. Gestion de progression (optionnel)
- [x] Concevoir un mécanisme de suivi de progression pour VOD/Séries :
  - [x] Définir protocole `ProgressStore` (`saveProgress(contentID:position:duration:)`, `loadProgress(contentID:)`).
  - [x] Implémenter `UserDefaultsProgressStore` (stockage local simple).
  - [x] Implémenter `RemoteProgressStore` (synchronisation serveur si API disponible).
- [x] Intégrer le `ProgressStore` dans `XtreamcodeSwiftAPI.Configuration`.
- [x] Exposer méthodes :
  - [x] `saveProgress(contentID:position:duration:)`
  - [x] `loadProgress(contentID:)` → retourne `(position: TimeInterval, duration: TimeInterval)?`
  - [x] `clearProgress(contentID:)`

- [x] Écrire des tests unitaires pour `XtreamVODService`, `XtreamSeriesService`, `XtreamSearchService` couvrant succès et erreurs (404, 500, champs manquants).
  - [x] Créer `Tests/XtreamcodeSwiftAPITests/XtreamVODSeriesServiceTests.swift` (catalogues + métadonnées).
  - [x] Couvrir la recherche mixte via `XtreamVODSeriesServiceTests`.
  - [x] Valider le suivi de progression via `XtreamAPIMediaTests.swift`.
- [x] Créer des tests de mapping des modèles à partir des nouvelles fixtures (VOD, Séries, Search).
  - [x] Tester parsing de `XtreamVODInfo` avec multiples qualités et sous-titres.
  - [x] Tester parsing de `XtreamSeriesInfo` avec saisons/épisodes imbriqués.
  - [x] Tester parsing de `XtreamSearchResult` avec types mixtes.
- [x] Ajouter des tests d'intégration avec stubs vérifiant :
  - [x] Parcours complet `vodCategories` -> `vodStreams` -> `vodDetails` -> `vodStreamURL`.
  - [x] Parcours complet `seriesCategories` -> `series` -> `seriesDetails` -> `episodeURL`.
  - [x] Recherche transversale et filtrage par type.
  - [x] Récupération VOD/Séries + vérification du cache (pas d'appel réseau supplémentaire dans la même session).
- [x] Simuler le mode offline (`NSURLErrorNotConnectedToInternet`) et vérifier fallback cache + erreurs.
- [ ] Intégrer tests de pagination (si l'API supporte `&page={n}` ou `&limit={n}`).
- [x] Mettre à jour les commandes de couverture (`docs/testing.md`) pour inclure les nouveaux modules/services.
  - [x] Ajouter `./scripts/test.sh --vod-series`.
  - [ ] Documenter la génération du rapport LCOV incluant `MediaCacheStore` (ou cache unifié).

## 6. Documentation & Exemples
- [x] Ajouter une page DocC `VOD.md` avec exemples d'utilisation.
  - [x] Détailler les scénarios : listing catalogues VOD, récupération métadonnées, lecture multi-qualité.
- [x] Ajouter une page DocC `Series.md` avec exemples.
  - [x] Montrer navigation saisons/épisodes, gestion sous-titres, tracking progression.
- [x] Ajouter une page DocC `Search.md` avec exemples de recherche transversale.
- [ ] Publier un playground `VODSeries.playground` montrant l'appel API et la gestion des erreurs.
- [x] Étendre le `README.md` avec des snippets VOD/Séries (async/await + Combine).
  - [ ] Ajouter un tableau de compatibilité plateforme (iOS/macOS/tvOS) pour VOD, Séries, Recherche.
  - [x] Inclure une FAQ « troubleshooting » (film indisponible, épisode manquant, recherche vide).
- [x] Tenir à jour `CHANGELOG.md` section `[Unreleased]` pour les nouvelles fonctionnalités.
  - [x] Mentionner les nouveaux endpoints VOD/Séries/Search, les services et le cache.
- [ ] Préparer un guide d'intégration pour tvOS (mise en avant du catalogue VOD/Séries) – étendre `docs/tvos/vod-series-integration.md`.
  - [ ] Couvrir les contrôles remote Siri, gestion chapitrage, restrictions parentales.
  - [ ] Proposer une architecture type (ViewModel Combine + lecteur AVPlayer).

## 7. Validation & Livraison
- [x] Exécuter `./scripts/lint.sh`, `./scripts/test.sh`, `./scripts/demo-auth.sh`, `./scripts/demo-live.sh` (pour garantir non-régression sprints 1 et 2).
- [x] Étendre `./scripts/test.sh` avec un flag `--vod-series` pour cibler les nouveaux tests.
- [x] Ajouter un script `./scripts/demo-vod-series.sh` pour la démo du sprint 3.
  - [x] Script : connexion -> affichage catégories VOD -> métadonnées film -> affichage séries -> navigation saisons/épisodes.
- [x] Vérifier la compilation iOS/macOS/tvOS après ajout des nouveaux services.
- [x] Mettre à jour le workflow GitHub Actions pour inclure les tests VOD/Séries.
  - [x] Ajouter job `vod-series-tests` exécutant `./scripts/test.sh --vod-series`.
- [ ] Préparer la revue de sprint : storyboard de démonstration VOD/Séries (séquence CLI + capture API doc).
  - [ ] Rassembler métriques (latence moyenne, taux de cache hit) pour la rétrospective.
- [x] Collecter retours UX internes sur la navigation VOD/Séries (questionnaire rapide). → créer `docs/ux/vod_series_feedback.md`.
- [x] Consolider une checklist de validation manuelle (créer `docs/qa/vod_series_checklist.md`).

## 8. Observabilité & Support
- [x] Instrumenter les appels VOD/Séries/Search avec le logger configurable existant (`LiveLogger` ou renommer en `MediaLogger`).
  - [x] Capturer latence, statut HTTP et exposer via événements.
- [x] Ajouter des compteurs internes (cache hits/miss pour VOD/Séries) remontés via `XtreamDiagnostics`.
- [x] Étendre le mécanisme de rapport d'erreur (`MediaIssueReport` ou généraliser `LiveIssueReport`).
- [x] Mettre à jour `docs/support-playbook.md` avec procédures VOD/Séries/Search.

## Risques & Points d'attention
- Variations de schéma sur `get_vod_info` et `get_series_info` (certains panels renvoient des structures imbriquées différentes, prévoir un parsing tolérant).
- Volume des réponses catalogues VOD/Séries : anticiper pagination/limitation côté client.
- Gestion des sous-titres multiples (formats SRT, VTT) : prévoir désérialisation flexible.
- Métadonnées TMDB/IMDB optionnelles : certains serveurs exposent ces infos, d'autres non (champs optionnels dans modèles).
- Suivi de progression : vérifier disponibilité côté serveur ou implémenter uniquement en local.
- Recherche : certains panels exigent paramètre `type`, d'autres supportent recherche globale sans filtre.
