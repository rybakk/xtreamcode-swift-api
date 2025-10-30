# TODO – Xtreamcode Swift API

- [x] Vérifier (dès accès réseau) la version stable d’Alamofire et consigner toute mise à jour ; version de référence actuelle : 5.10.2.
- [x] Recenser les endpoints Xtream Codes (auth, live, VOD, séries, EPG, catch-up, favoris, compte) avec paramètres et formats de réponse (`docs/endpoints.md`).
- [x] Définir l’architecture détaillée des modules (`XtreamClient`, `XtreamModels`, `XtreamStore`, adaptateurs Combine/closures) (`docs/architecture.md`).
- [x] Choisir et configurer les outils de lint/format (SwiftLint, SwiftFormat) et structurer le workflow CI (`docs/quality.md`).
- [x] Planifier les scripts de distribution (SPM, CocoaPods, Carthage) y compris la génération d’XCFramework (`docs/distribution.md`).
- [x] Préparer les tâches Sprint 0 (initialisation package, config Alamofire, DocC, GitHub Actions) (`docs/sprint0.md`).
- [x] Concevoir la stratégie de tests (unitaires, intégration, contract tests) et les mocks réseau basés sur Alamofire (`docs/testing.md`).

## Sprint 1 – Authentification & Compte
- [x] Réaliser les actions du Sprint 1 selon `docs/sprint1.md` (authentification, services compte, tests et doc). Démo prête via `docs/sprint1-demo.md` et `./scripts/demo-auth.sh`.

## Sprint 2 – Live TV & EPG
- [x] Engager les actions du Sprint 2 selon `docs/sprint2.md` (services Live/EPG, cache, tests et documentation). → Sprint 2 complété : services, modèles, cache, tests (unitaires + intégration + benchmarks), documentation, et workflow CI multi-plateformes.

## Sprint 3 – VOD & Séries
- [ ] Réaliser les actions du Sprint 3 selon `docs/sprint3.md` (services VOD/Séries/Search, métadonnées détaillées, cache, tests et documentation).

## Sprint 4 – Distribution & Documentation
- [ ] Réaliser les actions du Sprint 4 selon `docs/sprint4.md` (distribution SPM/CocoaPods/Carthage, documentation DocC complète, projets démo iOS/tvOS, release v1.0.0).
