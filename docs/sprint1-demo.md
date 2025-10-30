# Sprint 1 – Script de démonstration (Authentification)

Ce document décrit le déroulé de la démo à réaliser lors de la revue du sprint 1. Le but est de montrer que le SDK authentifie correctement un compte Xtream Codes, met en cache la session et expose les détails de compte au travers de la façade publique.

## Pré-requis
- macOS avec Swift 5.9+ installé (Xcode 15 ou toolchain équivalente).
- Dépendances déjà résolues (`swift package resolve` exécuté).
- `SwiftLint` et `SwiftFormat` installés (pour illustrer la qualité/lint si besoin).

## Scénario de démonstration (terminal)
1. `./scripts/demo-auth.sh`
   - Le script lance le test d’intégration `XtreamAPIIntegrationTests.testAuthenticateThenFetchAccountUsesCache`.
   - La sortie montre l’appel login, le fetch des informations de compte et la réutilisation du cache sans deuxième appel réseau.
2. `open Documentation/XtreamcodeSwiftAPI.docc` (optionnel) pour afficher la page `Authentication` générée par DocC et rappeler l’API publique.
3. Conclure en ouvrant `README.md` (section *Authentication*) pour souligner l’exemple de code identique à celui démontré.

## Points à mettre en avant pendant la démo
- Le SDK n’enregistre jamais les identifiants : ils sont injectés à l’instanciation de `XtreamcodeSwiftAPI`.
- Les erreurs d’authentification sont typées (`XtreamAuthError`) : invalid credentials, compte expiré, connexions simultanées.
- La session et les détails de compte sont mis en cache et invalidés correctement (`fetchAccountDetails()` ne relance pas de requête quand ce n’est pas nécessaire).
- Tests, lint et builds multiplateformes passent (`./scripts/lint.sh`, `./scripts/test.sh`, `./scripts/build.sh` ou `./scripts/build-xcframework.sh` selon la cible).

## Annexes
- Pour montrer la couverture : `swift test --enable-code-coverage && llvm-cov report` (cf. `docs/testing.md` pour les commandes précises).
- Les fixtures utilisées se trouvent dans `Tests/XtreamcodeSwiftAPITests/Fixtures/*_current.json` et proviennent de sources publiques.
