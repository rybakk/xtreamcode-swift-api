# Sprint 2 – Retours UX Live & EPG

Date de la session : 30/10/2025 – Panel interne (Equipe Player & QA).

## Participants
- Laura (iOS) – focus navigation/ergonomie.
- Mehdi (tvOS) – expérience télécommande Siri.
- Sofia (QA) – couverture scénarios offline/catch-up.

## Synthèse
- Navigation Live (catégories → chaînes) validée : le chargement est jugé fluide (cache en place). Ajout demandé d’un indicateur visuel lors du premier fetch `forceRefresh`.
- Player tvOS : contrôle Siri Remote satisfaisant. Recommandation d’afficher un hint « Balayez vers le bas » pour accéder aux détails EPG.
- Catch-up : timeline jugée claire, mais besoin d’une alerte lorsque `tv_archive` est absent pour expliquer la limitation.
- Observabilité : export JSON via `LiveIssueReport` apprécié (partage Slack + prise en charge support en <5 min).

## Actions suivies
1. Ajouter un spinner discret lors du `forceRefresh` initial (Sprint 3 backlog).
2. Documenter dans `docs/tvos/live-integration.md` la hint Siri Remote (fait).
3. Exposer message dédié `XtreamError.catchupDisabled` dans l’UI (déjà disponible, intégrer dans apps clientes).
