# Checklist QA – Sprint 3 (VOD & Séries)

## Préparation
- [ ] Réinitialiser le cache (`await api.invalidateMediaCache()`).
- [ ] Disposer d’un compte Xtream Codes avec accès VOD/Séries.
- [ ] Charger les fixtures de test (`vod_info_detailed_sample`, `series_info_full_sample`).

## Catalogue VOD
- [ ] Récupérer les catégories (`vodCategories`) et vérifier qu’au moins une catégorie remonte.
- [ ] Charger les streams d’une catégorie (`vodStreams(in:)`) et valider que la pagination n’est pas requise.
- [ ] Ouvrir les détails d’un film (`vodDetails(for:)`) et contrôler l’affiche, le synopsis et les infos codec.
- [ ] Forcer un refresh (`forceRefresh: true`) et confirmer que le cache est invalidé.

## Séries
- [ ] Récupérer les catégories séries (`seriesCategories`).
- [ ] Charger la liste d’une catégorie (`series(in:)`) et vérifier la présence du poster.
- [ ] Charger les détails (`seriesDetails(for:)`) : valider le nombre de saisons, les épisodes et les métadonnées.
- [ ] Tester un épisode inexistant et confirmer le retour `XtreamError.episodeNotFound`.

## Recherche
- [ ] Exécuter une recherche globale (`search(query: "demo")`) et vérifier que les résultats couvrent les trois types (Live/Movie/Series).
- [ ] Tester un filtre (`type: .movie`) et confirmer que seules les entrées VOD remontent.
- [ ] Simuler une erreur réseau et valider `XtreamError.searchFailed`.

## Progression
- [ ] Sauvegarder une progression (`saveProgress`) et confirmer la reprise (`loadProgress`).
- [ ] Effacer la progression (`clearProgress`) et vérifier que `loadProgress` retourne `nil`.

## Observabilité & Support
- [ ] Générer un `MediaIssueReport` pour un film indisponible (`domain: .vod`).
- [ ] Vérifier que le logger remonte les événements `requestStarted/Succeeded` pour VOD/Séries.
