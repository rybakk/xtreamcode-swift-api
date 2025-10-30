# Sprint 4 – Distribution & Documentation

Objectif : préparer le SDK pour une distribution multicanal (Swift Package Manager, CocoaPods, Carthage), finaliser la documentation complète (DocC, README, guides d'intégration), et créer des projets démo iOS/tvOS illustrant l'utilisation du SDK dans des contextes réels.

## 1. Pré-requis techniques
- [x] Valider que tous les sprints précédents (1, 2, 3) sont complétés et testés.
  - [x] Sprint 1 : Authentification & Compte ✓
  - [x] Sprint 2 : Live TV & EPG ✓
  - [x] Sprint 3 : VOD & Séries ✓
- [x] Vérifier la stabilité de la version Alamofire utilisée (actuellement 5.10.2).
- [x] S'assurer que tous les tests passent sur les 3 plateformes (iOS, macOS, tvOS).
- [ ] Vérifier la couverture de code (objectif ≥ 80%).
- [x] Valider que la documentation en ligne (`docs/*.md`) est à jour.

## 2. Swift Package Manager (SPM)
- [x] Mettre à jour `Package.swift` pour la release :
  - [x] Vérifier la version Swift minimale (`swift-tools-version: 6.2`).
  - [x] Confirmer les plateformes supportées (`.iOS(.v14)`, `.macOS(.v12)`, `.tvOS(.v15)`).
  - [x] Vérifier la dépendance Alamofire (`from: "5.10.2"`).
  - [x] S'assurer que tous les targets sont correctement définis (library, tests).
- [ ] Générer la documentation DocC via SPM :
  - [ ] Exécuter `swift package generate-documentation`.
  - [ ] Vérifier le rendu local avec `docc preview`.
  - [ ] Configurer l'hébergement DocC (GitHub Pages, Netlify, ou Cloudflare Pages).
- [ ] Créer/mettre à jour le script `./scripts/spm-build.sh` :
  - [ ] Build en mode release (`swift build -c release`).
  - [ ] Exécution des tests (`swift test`).
  - [ ] Génération DocC automatique.
- [ ] Ajouter un fichier `.spi.yml` pour Swift Package Index (optionnel) :
  - [ ] Définir les plateformes et versions Swift supportées.
  - [ ] Configurer la génération de documentation automatique.

## 3. CocoaPods
- [x] Créer/mettre à jour `xtreamcode-swift-api.podspec` :
  - [x] Définir `s.name`, `s.version`, `s.summary`, `s.description`.
  - [x] Configurer `s.homepage` et `s.source` (URL GitHub + tag).
  - [x] Définir `s.license` (MIT, Apache 2.0, ou autre).
  - [x] Spécifier `s.author` et `s.social_media_url`.
  - [x] Plateformes : `s.ios.deployment_target = '14.0'`, `s.osx.deployment_target = '12.0'`, `s.tvos.deployment_target = '15.0'`.
  - [x] Dépendance : `s.dependency 'Alamofire', '~> 5.10'`.
  - [x] Sources : `s.source_files = 'Sources/**/*.swift'`.
  - [x] Swift version : `s.swift_versions = ['5.10']`.
- [x] Mettre à jour le script `./scripts/pod-lint.sh` :
  - [x] Exécuter `pod lib lint xtreamcode-swift-api.podspec --allow-warnings`.
  - [x] Vérifier la compatibilité multi-plateformes.
- [ ] Ajouter un job GitHub Actions pour validation CocoaPods :
  - [ ] Job `cocoapods-lint` exécutant `./scripts/pod-lint.sh`.
- [ ] Préparer la documentation de publication CocoaPods :
  - [ ] Créer `docs/distribution/cocoapods-release.md` avec instructions `pod trunk push`.
  - [ ] Documenter l'inscription CocoaPods Trunk (si première publication).

## 4. Carthage (XCFramework)
- [ ] Créer/mettre à jour le script `./scripts/build-xcframework.sh` :
  - [ ] Archiver pour iOS (`generic/platform=iOS`).
  - [ ] Archiver pour iOS Simulator (`generic/platform=iOS Simulator`).
  - [ ] Archiver pour macOS (`platform=macOS`).
  - [ ] Archiver pour tvOS (`generic/platform=tvOS`).
  - [ ] Archiver pour tvOS Simulator (`generic/platform=tvOS Simulator`).
  - [ ] Créer l'XCFramework via `xcodebuild -create-xcframework`.
  - [ ] Générer les checksums (SHA256) pour vérification d'intégrité.
- [ ] Tester la construction XCFramework localement :
  - [ ] Exécuter `./scripts/build-xcframework.sh`.
  - [ ] Vérifier que le framework résultant contient toutes les architectures.
- [ ] Documenter l'utilisation Carthage :
  - [ ] Créer `docs/distribution/carthage-integration.md`.
  - [ ] Inclure exemple de `Cartfile` : `github "org/xtreamcode-swift-api" ~> 1.0`.
  - [ ] Documenter les étapes d'intégration dans Xcode.
- [ ] Ajouter un job GitHub Actions pour validation Carthage :
  - [ ] Job `carthage-build` exécutant `carthage build --use-xcframeworks --no-skip-current`.

## 5. Documentation DocC
- [ ] Créer une structure complète de documentation DocC :
  - [ ] Page d'accueil `XtreamcodeSwiftAPI.md` (overview, features, quick start).
  - [ ] `Authentication.md` (déjà existant, vérifier mise à jour).
  - [ ] `LiveTV.md` (déjà existant, vérifier mise à jour).
  - [ ] `VOD.md` (créer/mettre à jour pour Sprint 3).
  - [ ] `Series.md` (créer/mettre à jour pour Sprint 3).
  - [ ] `Search.md` (créer/mettre à jour pour Sprint 3).
  - [ ] `ErrorHandling.md` (gestion des erreurs, types `XtreamError`).
  - [ ] `Caching.md` (politiques de cache, configuration).
  - [ ] `AdvancedConfiguration.md` (Combine, closures, progress tracking).
- [ ] Ajouter des tutoriels DocC :
  - [ ] `BuildingYourFirstApp.tutorial` (authentification + live TV).
  - [ ] `WorkingWithVOD.tutorial` (catalogues VOD + lecture).
  - [ ] `IntegratingWithtvOS.tutorial` (spécificités tvOS).
- [ ] Documenter tous les types publics avec des commentaires de documentation :
  - [ ] Ajouter `/// Documentation` à tous les types, méthodes et propriétés publics.
  - [ ] Inclure des exemples de code dans les commentaires DocC.
- [ ] Générer et vérifier le rendu DocC :
  - [ ] Exécuter `swift package generate-documentation`.
  - [ ] Prévisualiser avec `docc preview`.
  - [ ] Corriger les warnings/erreurs de documentation.
- [ ] Configurer l'hébergement de la documentation :
  - [ ] GitHub Pages, Netlify, Cloudflare Pages, ou Swift Package Index.
  - [ ] Automatiser la publication via GitHub Actions (workflow `deploy-docs.yml`).

## 6. README & Guides d'intégration
- [ ] Mettre à jour `README.md` :
  - [ ] Section "Features" listant toutes les fonctionnalités (Auth, Live, EPG, VOD, Séries, Search).
  - [ ] Section "Requirements" (iOS 14+, macOS 12+, tvOS 15+, Swift 5.10+).
  - [ ] Section "Installation" avec exemples SPM, CocoaPods, Carthage.
  - [ ] Section "Quick Start" avec exemple complet (auth + live).
  - [ ] Section "Documentation" avec liens vers DocC hébergé.
  - [ ] Section "Examples" avec liens vers projets démo.
  - [ ] Section "Contributing" (guidelines, code of conduct).
  - [ ] Section "License" (MIT, Apache 2.0, ou autre).
  - [ ] Badges (build status, coverage, version, license, platform).
- [ ] Créer des guides d'intégration par plateforme :
  - [ ] `docs/integration/ios-integration.md` (UIKit + SwiftUI).
  - [ ] `docs/integration/macos-integration.md` (AppKit + SwiftUI).
  - [ ] `docs/integration/tvos-integration.md` (UIKit for tvOS, AVKit).
- [ ] Créer des guides thématiques :
  - [ ] `docs/guides/authentication-guide.md`.
  - [ ] `docs/guides/live-tv-guide.md`.
  - [ ] `docs/guides/vod-guide.md`.
  - [ ] `docs/guides/series-guide.md`.
  - [ ] `docs/guides/caching-strategy.md`.
  - [ ] `docs/guides/error-handling.md`.
  - [ ] `docs/guides/testing-guide.md`.
- [ ] Créer un guide de migration (si versions antérieures) :
  - [ ] `docs/migration/migration-guide.md` (breaking changes, deprecations).

## 7. Projets Démo
- [ ] Créer un projet démo iOS (`Examples/iOS-Demo`).
  - [ ] App UIKit montrant Auth, Live TV, EPG, VOD, Séries.
  - [ ] App SwiftUI alternative (ou sections SwiftUI).
  - [ ] Intégration AVPlayer pour lecture Live/VOD.
  - [ ] Gestion des erreurs et états de chargement.
  - [ ] Utilisation du cache et mode offline.
  - [ ] README dans `Examples/iOS-Demo/README.md` avec instructions.
- [ ] Créer un projet démo tvOS (`Examples/tvOS-Demo`).
  - [ ] Interface tvOS native (UIKit for tvOS).
  - [ ] Navigation par catégories Live/VOD/Séries.
  - [ ] Lecteur AVPlayerViewController optimisé pour tvOS.
  - [ ] Gestion Siri Remote et contrôles media.
  - [ ] README dans `Examples/tvOS-Demo/README.md`.
- [ ] Créer un projet démo macOS (optionnel) (`Examples/macOS-Demo`).
  - [ ] App AppKit ou SwiftUI pour macOS.
  - [ ] Navigation catalogues et lecture vidéo.
- [ ] Documenter l'architecture des démos :
  - [ ] Diagrammes d'architecture (MVVM, Combine, async/await).
  - [ ] Exemples de ViewModels et Services.
- [ ] Ajouter des captures d'écran/vidéos des démos :
  - [ ] Screenshots dans `Examples/Screenshots/`.
  - [ ] Vidéos démo sur YouTube ou hébergement similaire.

## 8. Versioning & Release
- [ ] Définir la stratégie de versioning (SemVer) :
  - [ ] `1.0.0` pour première release stable.
  - [ ] `MAJOR.MINOR.PATCH` pour évolutions futures.
- [ ] Mettre à jour `CHANGELOG.md` :
  - [ ] Section `[1.0.0] - YYYY-MM-DD` avec toutes les fonctionnalités.
  - [ ] Sections `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.
- [ ] Créer un tag Git pour la release :
  - [ ] `git tag -a v1.0.0 -m "Release 1.0.0"`.
  - [ ] `git push origin v1.0.0`.
- [ ] Créer une GitHub Release :
  - [ ] Titre : "v1.0.0 - Initial Release".
  - [ ] Description : résumé des fonctionnalités, liens documentation.
  - [ ] Attachments : XCFramework, checksums.
- [ ] Automatiser la release via GitHub Actions :
  - [ ] Workflow `release.yml` déclenché sur tags `v*`.
  - [ ] Build, tests, génération DocC, création XCFramework.
  - [ ] Publication automatique de la GitHub Release.

## 9. Validation & Livraison
- [ ] Exécuter tous les scripts de validation :
  - [ ] `./scripts/lint.sh` (SwiftLint + SwiftFormat).
  - [ ] `./scripts/test.sh` (tous les tests).
  - [ ] `./scripts/test.sh --live` (tests Live/EPG).
  - [ ] `./scripts/test.sh --vod-series` (tests VOD/Séries).
  - [ ] `./scripts/test.sh --benchmarks` (benchmarks cache).
  - [ ] `./scripts/demo-auth.sh` (démo auth).
  - [ ] `./scripts/demo-live.sh` (démo live).
  - [ ] `./scripts/demo-vod-series.sh` (démo VOD/Séries).
  - [ ] `./scripts/spm-build.sh` (build SPM).
  - [ ] `./scripts/pod-lint.sh` (validation CocoaPods).
  - [ ] `./scripts/build-xcframework.sh` (génération XCFramework).
- [ ] Vérifier la compilation sur toutes les plateformes :
  - [ ] iOS (device + simulator).
  - [ ] macOS.
  - [ ] tvOS (device + simulator).
- [ ] Vérifier la couverture de code :
  - [ ] Générer rapport LCOV : `./scripts/test.sh --enable-code-coverage`.
  - [ ] Vérifier couverture ≥ 80%.
- [ ] Exécuter les projets démo :
  - [ ] Lancer iOS-Demo et tester toutes les fonctionnalités.
  - [ ] Lancer tvOS-Demo et tester sur simulateur Apple TV.
  - [ ] Vérifier absence de crashes, fuites mémoire (Instruments).
- [ ] Valider la documentation :
  - [ ] Vérifier tous les liens (internes et externes).
  - [ ] Relire README, guides, DocC.
  - [ ] Vérifier les exemples de code (copier/coller et exécuter).
- [ ] Préparer la revue de sprint :
  - [ ] Démonstration des projets démo iOS/tvOS.
  - [ ] Présentation de la documentation DocC hébergée.
  - [ ] Walkthrough de l'installation via SPM/CocoaPods/Carthage.
  - [ ] Métriques : couverture de code, nombre de tests, taille du SDK.

## 10. Observabilité & Support
- [ ] Finaliser `docs/support-playbook.md` :
  - [ ] Procédures complètes pour tous les modules (Auth, Live, EPG, VOD, Séries, Search).
  - [ ] FAQ exhaustive (troubleshooting communs).
  - [ ] Contacts support (email, GitHub Issues, Discord/Slack si applicable).
- [ ] Mettre en place un système de tracking des issues :
  - [ ] Configurer GitHub Issues avec templates (bug report, feature request).
  - [ ] Labels : `bug`, `enhancement`, `documentation`, `question`, `platform:iOS`, `platform:tvOS`, etc.
  - [ ] Milestones pour versions futures.
- [ ] Configurer les discussions GitHub (optionnel) :
  - [ ] Section Q&A pour questions utilisateurs.
  - [ ] Section Announcements pour releases.
- [ ] Préparer un guide de contribution :
  - [ ] `CONTRIBUTING.md` (comment contribuer, guidelines de code, process PR).
  - [ ] `CODE_OF_CONDUCT.md` (code de conduite communautaire).

## 11. Marketing & Communication (optionnel)
- [ ] Créer un site web pour le SDK (optionnel) :
  - [ ] Landing page avec features, documentation, exemples.
  - [ ] Hébergement via GitHub Pages, Netlify, Vercel.
- [ ] Annoncer la release :
  - [ ] Post sur forums iOS/Swift (Swift Forums, Reddit r/swift).
  - [ ] Tweet avec hashtags #Swift #iOS #tvOS #SDK.
  - [ ] Article de blog détaillant les fonctionnalités.
- [ ] Créer une vidéo démo (optionnel) :
  - [ ] Walkthrough du SDK et des projets démo.
  - [ ] Publication sur YouTube.
- [ ] Soumettre au Swift Package Index :
  - [ ] Vérifier que le repo est public et tagged.
  - [ ] Le Swift Package Index devrait indexer automatiquement.

## Risques & Points d'attention
- Compatibilité multi-plateformes : certaines fonctionnalités peuvent nécessiter des ajustements selon la plateforme (ex: AVKit sur tvOS vs iOS).
- Taille du framework : vérifier que l'XCFramework n'est pas trop volumineux (optimisations de build).
- Dépendances : s'assurer que les versions Alamofire sont compatibles avec les contraintes de déploiement.
- Documentation : maintenir la documentation à jour avec les évolutions du code (automatiser via CI).
- Support communautaire : prévoir des ressources pour répondre aux issues et questions.
- App Store compliance : vérifier que les démos respectent les guidelines Apple (pas de contenu protégé par droits d'auteur dans les exemples).

## Definition of Done
- [ ] Toutes les sections 1-11 sont complétées.
- [ ] Tous les tests passent (≥ 99% de succès).
- [ ] Couverture de code ≥ 80%.
- [ ] Documentation DocC complète et hébergée.
- [ ] README complet avec badges et exemples.
- [ ] Projets démo iOS et tvOS fonctionnels.
- [ ] Distribution SPM, CocoaPods, Carthage validée.
- [ ] GitHub Release v1.0.0 publiée avec XCFramework.
- [ ] Workflows GitHub Actions tous verts (lint, tests, builds multi-plateformes).
- [ ] Revue de sprint effectuée avec validation stakeholders.
