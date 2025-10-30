# Stratégie de Tests

## Principes

- Assurer ≥ 80 % de couverture sur les modules core (services, client réseau, modèles).  
- Séparer les tests unitaires, d’intégration et contractuels afin de diagnostiquer rapidement les régressions.  
- Utiliser des mocks réseau basés sur Alamofire pour simuler les réponses Xtream Codes.

## 1. Tests Unitaires

### Cibles
- `XtreamClientTests` : vérifie la construction des requêtes (`URLRequest`), gestion des erreurs, mapping `AFError` → `XtreamError`.
- `XtreamAuthServiceTests`, `XtreamLiveServiceTests`, etc. : validation de la logique métier (extraction des données, filtrage).  
- `XtreamModelTests` : décodage JSON pour chaque modèle (UserInfo, LiveChannel, VodItem, etc.).
- `XtreamModelStoreTests` : politique de cache, expiration TTL.

### Outils
- Utilisation de `Testing` (Swift 5.9+) ou `XCTest` selon compatibilité projet (décision finale à prendre).  
- Fixtures JSON dans `Tests/Fixtures/` pour simuler les payloads (`docs/endpoints.md` comme référence).
- Mocks : implémenter un `MockSession` conforme à Alamofire `SessionProtocol` permettant de renvoyer des réponses pré-enregistrées.

### Automatisation
- `swift test` exécuté en CI.  
- Option `--parallel` pour accélérer.  
- Génération de rapport couverture (`swift test --enable-code-coverage`).

## 2. Tests d’Intégration

### Objectif
- Valider l’interaction bout-en-bout entre `XtreamSDKFacade` et un serveur simulé.  
- Détecter les problèmes de sérialisation/désérialisation et de configuration session (timeouts, headers).

### Approche
- Créer un serveur stub (ex. `Vapor` ou `SwiftNIO`) dans `Tests/Integration/` qui répond aux endpoints essentiels avec des fixtures.  
- Alternative légère : utiliser `OHHTTPStubs` (pour cibles iOS) ou `URLProtocol` custom dans les tests.  
- Scénarios clés : login success/failure, récupération de catalogues, EPG, VOD, gestion catch-up.

### Exécution
- `swift test --filter Integration` ou scheme Xcode dédié.  
- CI : job spécifique déclenché après les unit tests.

## 3. Contract Tests

### But
- S’assurer que les schémas Xtream Codes n’ont pas changé.  
- Faciliter la détection de champs manquants ou modifiés côté serveur.

### Méthode
- Stocker des exemples de réponses JSON dans `Contracts/`.  
- Générer des snapshots (ex. via `swift-snapshot-testing`) ou utiliser `Codable` + assertion exhaustive sur les clés.  
- Comparer les réponses live (si sandbox accessible) avec les snapshots pour détecter les écarts.

## 4. Tests de Performance (optionnel)

- Mesurer le temps de décodage et de transformation des données volumineuses (EPG, catalogues).  
- Utiliser `measure` (XCTest) ou modules tiers.  
- Objectifs : décodage <150ms sur device cible (A14) pour jeux de données typiques.

## 5. Mocks & Fixtures

- `StubURLProtocol` (`Tests/XtreamcodeSwiftAPITests/Support/StubURLProtocol.swift`) pour intercepter les requêtes Alamofire dans les tests et renvoyer des réponses programmées (utilisé par `XtreamClientTests`).
- `MockCredentialStore`, `MockCache` pour tester les comportements sans dépendance système.  
- Fixtures organisées par domaine (`Auth/login_success.json`, `Live/get_live_streams.json`, etc.).

## Suites disponibles

- `XtreamClientTests` : vérifie la construction des requêtes, la gestion des credentials manquants et les erreurs HTTP.
- `XtreamAuthServiceTests` : s’assure que `login` mappe les payloads et relaie les erreurs 401.
- `XtreamAccountServiceTests` : confirme la transformation de `get_user_info` en `XtreamAccountDetails`.
- `XtreamLiveServiceTests`, `XtreamEPGServiceTests` : couvrent les scénarios succès/erreur, cache et validations métiers.
- `XtreamAPIIntegrationTests` : flux façade complet + scénarios cache/offline (tests live/EPG, fallback, forceRefresh).
- `XtreamAPIBridgeTests` : adaptateurs Combine/closures.
- `XtreamVODSeriesServiceTests` : catalogues VOD/séries, métadonnées détaillées et recherche mixte.
- `XtreamAPIMediaTests` : persistance du suivi de progression (ProgressStore).
- `LiveCacheStoreBenchmarks` : micro-benchmarks cache hit/miss.

## 6. Intégration CI

- Job `test` : `swift test --enable-code-coverage --parallel`.  
- Job `integration-tests` : exécuter `swift test --filter XtreamAPIIntegrationTests`.  
- Job `benchmarks` : `swift test --filter LiveCacheStoreBenchmarks`.  
- Publication des rapports (`.xcresult`, couverture) comme artifacts GitHub Actions.  
- Option : intégrer `slather` ou `xcov` pour analyser la couverture et poster un résumé dans la PR.

## Commandes utiles

- Tests unitaires : `swift test --filter XtreamLiveServiceTests` / `swift test --filter XtreamEPGServiceTests`.
- Intégration façade : `swift test --filter XtreamAPIIntegrationTests`.
- Benchmarks cache : `swift test --filter LiveCacheStoreBenchmarks`.
- Couverture : `swift test --enable-code-coverage` (puis exporter via `llvm-cov show .build/.../xtreamcode-swift-apiPackageTests.xctest`).
- Scripts orchestrateurs : `./scripts/test.sh --live`, `./scripts/test.sh --integration`, `./scripts/test.sh --benchmarks`, `./scripts/test.sh --vod-series`.

## Étapes Suivantes

- Décider si `Testing` (Swift 6+) ou `XCTest` sera la base principale (compatibilité plateformes).  
- Créer l’arborescence `Tests/Fixtures`, `Tests/Integration` et `Tests/Support`.  
- Implémenter `MockSession` et premiers jeux de fixtures dès Sprint 0 pour accélérer les développements suivants.
