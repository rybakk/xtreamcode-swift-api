# Distribution & Packaging

## 1. Swift Package Manager

- **Structure** : conserver la bibliothèque principale dans `Sources/xtreamcode-swift-api`.  
- **Dependencies** : déclarer Alamofire (`.package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.2")`).  
- **Targets** : 
  - `xtreamcode-swift-api` (library) exposant le SDK.
  - `xtreamcode-swift-apiTests` (test target) dépendant de `Testing` ou `XCTest`.
- **Resources** : prévoir un dossier `Resources` pour fixtures JSON (utilisé en tests).  
- **Documentation** : activer DocC (`.target(..., resources: [.copy("DocC")])`) à planifier.
- **Script** : fournir un `Makefile` ou script `./scripts/spm-build.sh` exécutant `swift build`, `swift test` et `swift package generate-documentation`.

## 2. CocoaPods

- **Podspec** : fichier `xtreamcode-swift-api.podspec` contenant :
  - `s.source = { :git => "https://github.com/<org>/xtreamcode-swift-api.git", :tag => "v#{version}" }`
  - `s.platform = { :ios => "14.0", :osx => "12.0", :tvos => "15.0" }`
  - `s.dependency "Alamofire", "~> 5.10"`
  - `s.swift_versions = ["5.10"]`
  - `s.source_files = "Sources/**/*.swift"`
- **Tests** : configurer `pod lib lint` dans la CI (job additionnel).  
- **Script** : `./scripts/pod-lint.sh` lançant `pod spec lint xtreamcode-swift-api.podspec --allow-warnings`.
- **Distribution** : utilisation de tags git. Prévoir instructions pour `pod trunk push`.

## 3. Carthage

- **XCFramework** : générer un `XtreamcodeSwiftAPI.xcframework` via `xcodebuild` pour iOS, macOS, tvOS.  
- **Script** : `./scripts/build-xcframework.sh` :
  1. `xcodebuild archive` pour chaque destination (`ios`, `ios simulator`, `macosx`, `appletvos`, `appletvsimulator`).  
  2. `xcodebuild -create-xcframework` pour assembler.  
  3. Dépôt de l’XCFramework dans `Carthage/Build/`.
- **Cartfile** : documenter l’entrée `github "org/xtreamcode-swift-api" ~> 1.0`.
- **Validation** : ajouter un job CI `carthage build --use-xcframeworks --no-skip-current`.

## 4. Versioning & Release

- Utiliser SemVer (`MAJOR.MINOR.PATCH`).  
- Tague Git `vX.Y.Z` déclenchant la pipeline de release (GitHub Actions) :
  1. Build & testes.
  2. Génération DocC.
  3. Publication des artifacts (`.xcframework`, DocC bundle).  
- Rédiger un `CHANGELOG.md` (Keep a Changelog).
- Signer les releases (optionnel) et inclure les checksums pour l’XCFramework.

## 5. Check-list Publication

- [ ] Mettre à jour `Package.swift` avec la version Alamofire et le numéro de version du SDK.
- [ ] Exécuter `swift test`, `swiftformat --lint`, `swiftlint`.
- [ ] Générer DocC et vérifier le rendu local.  
- [ ] `pod lib lint` réussi.  
- [ ] `carthage build --use-xcframeworks --no-skip-current` exécuté.  
- [ ] Créer un tag Git et publier la release GitHub.  
- [ ] Pousser la spec vers CocoaPods (si release publique).

## 6. Guides Plateformes

- tvOS : suivre `docs/tvos/live-integration.md` (focus Siri Remote, audio de fond, AVPlayerViewController).
