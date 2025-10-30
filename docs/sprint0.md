# Sprint 0 – Fondation

Ce sprint prépare l’infrastructure du SDK avant d’implémenter les fonctionnalités Xtream Codes.

## 1. Initialisation du Package
- [x] Mettre à jour `Package.swift` :
  - Déclarer la bibliothèque `xtreamcode-swift-api` et dépendance Alamofire `from: 5.10.2`.
  - Ajouter la cible de tests avec ressources fixtures (placeholder).
- [x] Créer le squelette source :
  - Dossiers `Sources/XtreamSDKFacade`, `Sources/XtreamClient`, `Sources/XtreamModels`, `Sources/XtreamServices`.
  - Ajouter fichiers stub (`TODO`) pour compilation initiale.
- [x] Mettre en place les dossiers de tests (`Tests/Unit`, `Tests/Integration`, `Tests/Support`) et un exemple de test.

## 2. Outils Qualité & Scripts
- [x] Ajouter `.swiftformat` et `.swiftlint.yml` basés sur `docs/quality.md`.
- [x] Créer un `Makefile` ou scripts `./scripts/lint.sh`, `./scripts/test.sh`, `./scripts/build.sh`.
- [x] Ajouter un hook Git optionnel (`scripts/git-pre-commit.sh`) exécutant SwiftFormat en mode lint.

## 3. Configuration CI/CD
- [x] Mettre en place GitHub Actions :
  - Workflow `ci.yml` avec jobs `lint`, `test`, `integration-tests`.
  - Cache `.build`, `swiftformat`, `swiftlint`.
- [ ] Ajouter badge de statut dans `README.md` (si visible).

## 4. Documentation
- [x] Initialiser DocC :
  - Dossier `Documentation/XtreamcodeSwiftAPI.docc`.
  - Page `XtreamcodeSwiftAPI.md` avec introduction (bref aperçu des features).
- [x] Mettre à jour `README.md` :
  - Présentation du projet, prérequis (Swift 5.10, Alamofire 5.10.2), instructions de build (`make build`).
  - Lien vers la roadmap, endpoints, architecture.
- [x] Ajouter `CHANGELOG.md` (format Keep a Changelog, entrée `Unreleased`).

## 5. Distribution – Préparation
- [x] Créer l’ossature des scripts :
  - `scripts/spm-build.sh`, `scripts/pod-lint.sh`, `scripts/build-xcframework.sh` (stubs avec TODO).
- [x] Ajouter `xtreamcode-swift-api.podspec` (version placeholder) et `Cartfile` minimal.
- [x] Vérifier la compilation initiale `swift build` et `swift test`.

## 6. Suivi & Vérification
- [x] Mettre à jour `todo.md` à mesure des tâches complétées.
- [ ] Ouvrir des issues/tickets correspondants (si gestion de projet via GitHub Projects).
- [x] Préparer un point de revue en fin de sprint (checklist + démo lint/test/doc).
