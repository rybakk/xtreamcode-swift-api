# Sprint 1 – Authentification & Compte

Objectif : livrer un SDK capable d’authentifier un utilisateur Xtream Codes, d’exposer les informations de compte et de mettre en place les fondations de gestion de session (refresh, erreurs typées).

## 1. Pré-requis techniques
- [x] Confirmer les endpoints d’authentification supportés par l’instance cible (appel direct `player_api.php`, `action=get_user_info`; fixtures `auth_login_success_current.json`, `account_user_info_current.json`).
- [x] Définir la convention de fourniture des identifiants : passage obligatoire à l’instanciation (aucun stockage persistant dans le SDK).
- [x] Étendre les fixtures JSON (`Tests/XtreamcodeSwiftAPITests/Fixtures`) avec des réponses réelles `player_api` / `get_user_info` (samples issus de `tellytv/go.xtream-codes`).
- [x] Mettre en place l’infrastructure de stubs réseau via `StubURLProtocol` (cf. `Tests/XtreamcodeSwiftAPITests/Support/StubURLProtocol.swift`).

## 2. Implémentation Client & Services
- [x] Créer `XtreamEndpoint` (enum / struct) décrivant les actions de login (`player_api.php`, `action=auth`, `get_user_info`).
- [x] Étendre `XtreamClient` :
  - Construction d’URL avec credentials.
  - Décodage JSON via `Decodable` générique.
  - Mapping des erreurs HTTP/JSON -> `XtreamError`.
- [x] Implémenter `XtreamAuthService` :
-  - `login(username:password:)` → retourne `XtreamAuthSession`.
-  - `refreshSession()` (réutilise le login pour actualiser les données).
-  - `logout()` (réinitialisation locale, en attente d’un endpoint serveur éventuel).
- [x] Implémenter `XtreamAccountService` :
  - `fetchAccountInfo()` retourne `XtreamAccountDetails` (session + infos serveur).
  - Structurer les modèles (`XtreamAuthSession`, `XtreamServerInfo`, `XtreamAccountInfoResponse`).
- [x] Mettre à jour `XtreamSDKFacade` :
  - API publique `authenticate(...)`, `refreshSession()`, `logout()`, `fetchAccountDetails()`.
  - Gestion centralisée de l’état (session courante, cache account).

## 3. Modèles & Erreurs
- [x] Définir les modèles `XtreamAuthSession`, `XtreamServerInfo`, `SubscriptionStatus`, helpers de mapping.
- [x] Introduire `XtreamAuthError` (invalidCredentials, accountExpired, tooManyConnections, etc.). `DeviceProfile` reste optionnel.
- [x] Ajouter un convertisseur des champs bruts (timestamp, booléens, ints).

- **Couverture** (19.9% globale suite à l'inclusion d'Alamofire, ~90% sur les tests maison ; à améliorer en filtrant les dépendances).

## 4. Tests
- [x] Tests unitaires `XtreamClientTests` couvrant la construction d’URL/login et la gestion d’erreurs.
- [x] Tests `XtreamAuthServiceTests` : succès + échec 401. (Scénarios compte expiré/too many connections à ajouter via nouvelles fixtures.)
- [x] Tests `XtreamAccountServiceTests` : parsing `get_user_info` et mapping session.
- [x] Tests d’intégration (stub) : scénario complet login + fetch account via `XtreamcodeSwiftAPI`.
- [x] Mesurer la couverture du module (>= 80% sur `XtreamClient`, `XtreamAuthService`). (`llvm-cov` filtré : ~81.5% global, >85% sur tous les modules maison.)

## 5. Documentation & Exemples
- [x] Mettre à jour `Documentation/XtreamcodeSwiftAPI.docc` avec la page `Authentication.md` :
  - Exemple `authenticate`, gestion erreurs, règles d’injection des identifiants (pas de persistance).
- [x] Ajouter une section Auth dans le `README.md` (snippet de code).
- [x] Rédiger des notes dans `CHANGELOG.md` sous `[Unreleased]`.

## 6. Validation & Livraison
- [x] Executer `./scripts/lint.sh`, `./scripts/test.sh`, `./scripts/test.sh --filter Integration`.
- [x] Vérifier la compatibilité iOS/macOS/tvOS (build via `xcodebuild`).
- [x] Mettre à jour `docs/sprint0.md` (case "point de revue" et lien) lorsque la démo est prête.
- [x] Préparer la revue de sprint : démonstration d’un workflow d’authentification fonctionnel. Voir `docs/sprint1-demo.md` pour le déroulé détaillé (script CLI, test UI, métriques attendues).
