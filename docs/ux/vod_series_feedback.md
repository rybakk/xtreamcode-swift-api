# Sprint 3 – Retours UX VOD & Séries

Date de la session : 28/10/2025 – Panel interne (Equipe Contenus & QA).

## Participants
- Hugo (Produit) – parcours de découverte des films/séries.
- Clara (Design) – cohérence visuelle des fiches médias.
- Julien (Support) – attentes pour le suivi de progression et la recherche.

## Synthèse
- Catalogue VOD jugé « riche » : chargement initial bien perçu grâce au cache, mais suggestion d’un badge « nouveau » pour les ajouts récents.
- Fiche film : les métadonnées TMDB ressortent bien (affiche HQ + synopsis). Demande d’un bloc « codec » facultatif pour les power-users.
- Série : navigation saison/épisode claire. Besoin d’un indicateur de progression par épisode (à brancher sur `ProgressStore`).
- Recherche : résultats mixtes appréciés. Recommandation d’afficher le type (Live/Movie/Series) par un pictogramme pour éviter la confusion.
- Progression : reprise au bon timestamp validée sur iOS/tvOS. À documenter côté intégration pour synchroniser différents devices.

## Actions suivies
1. Ajouter un champ optionnel « codecs » dans la fiche média (Sprint 4 backlog, dépend du design).
2. Exposer dans la doc client un exemple d’utilisation du `ProgressStore` pour marquer les épisodes vus (fait dans README).
3. Mettre à jour la recherche UI pour afficher un badge de type (Design → Sprint 4).
