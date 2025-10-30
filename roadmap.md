# Xtreamcode Swift API – Roadmap

## Vision
- Livrer un SDK Swift multiplateforme (iOS, macOS, tvOS) intégrant l’ensemble des fonctionnalités Xtream Codes via Alamofire.
- Assurer une distribution harmonisée via Swift Package Manager, CocoaPods et Carthage.
- Fournir une API moderne (`async/await`) avec adaptateurs Combine/closures et une documentation complète pour accélérer l’intégration.

## Principes Directeurs
- Couverture fonctionnelle complète (authentification, live, VOD, séries, EPG, catch-up, gestion de compte).
- Qualité de service : résilience réseau, cache configurable, erreurs typées et sécurité des identifiants.
- Testabilité élevée (≥ 80 % de couverture unitaire) et CI multi-plateformes.

## Jalons

### Sprint 0 – Fondation
- Initialiser le package Swift (`swift-tools-version: 6.2`), configuration Alamofire et targets.
- Mettre en place SwiftLint/SwiftFormat (selon `docs/quality.md`), scripts de build et configuration DocC.
- Suivre la checklist détaillée du Sprint 0 (`docs/sprint0.md`).
- Configurer GitHub Actions (build, tests) et définir la structure des modules (`XtreamClient`, `XtreamModels`, `XtreamStore`).
- Documenter la version stable d’Alamofire retenue (actuellement 5.10.2) et prévoir une veille des mises à jour.

### Sprint 1 – Authentification & Compte
- Implémenter `XtreamClientConfiguration`, connexion login/token, refresh session, logout.
- Exposer les endpoints profil/abonnement, statut serveur, limitations.
- Ajouter tests unitaires et mocks Alamofire couvrant authentification et erreurs.
- Suivre le plan détaillé (`docs/sprint1.md`).

### Sprint 2 – Live TV & EPG
- Récupération des catégories live, chaînes, URLs multi-qualités, statut.
- Intégrer EPG, catch-up et gestion des favoris live.
- Mettre en place cache mémoire/disque et politique TTL pour EPG.
- Tests de mapping (données live/EPG) + scenarios offline/cache.
- **Stories clés** :
  - En tant qu’utilisateur authentifié, consulter la liste des catégories live et les chaînes associées avec métadonnées complètes (statut, icônes, langues, DRM).
  - En tant qu’utilisateur, accéder au programme en direct avec bascule multi-qualité et fallback automatique réseau.
  - En tant qu’utilisateur, consulter le guide EPG sur 7 jours, lancer un replay catch-up compatible HLS et gérer mes favoris live.
- **Tâches techniques** :
  - Structurer `LiveService` et `EPGService` dans `XtreamClient`, définir DTO et modèles domaine alignés avec `XtreamModels`.
  - Implémenter les endpoints live (`get_live_categories`, `get_live_streams`, `get_live_stream_url`), EPG (`get_epg`, `get_catchup_stream`), favoris (`set_favorite`, `get_favorites`).
  - Configurer un cache hybride (`NSCache` + `FileManager`) avec stratégie TTL configurable et invalidation manuelle post-auth.
  - Assurer un fallback graceful en mode offline : servir le cache, exposer un état précis dans Combine/async.
  - Ajouter instrumentation (log niveau debug) pour les métriques temps de réponse/cache hits.
- **Qualité & Tests** :
  - Générer des fixtures JSON live/EPG variées (timezone, doublons, flux sans catch-up) et couvrir parsing avec XCTest.
  - Créer tests d’intégration simulées via `URLProtocol` custom pour valider le comportement cache/offline.
  - Vérifier la compatibilité tvOS (remote events, lecture continue) via tests UI automatisés minimaux ou plan manuel (`docs/tests/tvos-live.md`).
- **Livrables** :
  - Documentation d’usage rapide Live/EPG dans DocC (`Guides/Live.md`) + playground d’exemple.
  - Table de support (`docs/compatibility/live_epg_matrix.md`) référençant devices/protocoles.
- **Definition of Done** :
  - Taux de succès ≥ 99 % sur tests live/EPG, pas de fuite mémoire détectée via Instruments.
  - Couverture ≥ 85 % sur `LiveService`/`EPGService`, revues pair complètes, tickets Jira fermés.

### Sprint 3 – VOD & Séries
- Catalogues VOD/séries, métadonnées détaillées, saisons/épisodes, sous-titres, progrès optionnel.
- Recherche transversale (live, VOD, séries) avec filtrage.
- Couverture de tests sur la désérialisation et la pagination.

### Sprint 4 – Distribution & Documentation
- Préparer Podspec, script Carthage (XCFramework) et vérifier intégration SPM (voir `docs/distribution.md`).
- Rédiger DocC, README, guides d’intégration (iOS/macOS/tvOS) et échantillons de code.
- Publier projets démo iOS et tvOS illustrant la configuration Alamofire et l’appel des APIs.

### Release Candidate
- Optimiser performances (latence, parallélisme), revue sécurité (gestion sécurisée des identifiants fournis à l’instanciation, pinning optionnel).
- Tests d’intégration contre environnement Xtream Codes, vérification App Store compliance.
- Préparer versionnement (tag Git), changelog et plan de support.

## Dépendances & Pré-requis
- Alamofire (dernière version stable, 5.10.2 à la date de rédaction).
- Accès à une instance Xtream Codes sandbox ou mocks exhaustifs.
- Comptes développeur Apple pour tests sur plateformes cibles.

## Suivi & Risques
- **Risques principaux** : variations d’API Xtream Codes, disponibilité sandbox, complexité multi-distribution.
- **Mitigation** : contrats de schéma, mocks générés, automatisation build xcframework, documentation à jour.
- Revues hebdomadaires pour ajuster priorités et vérifier la couverture de tests/statut CI.
