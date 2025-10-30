# Qualité & CI – Choix d’Outils

## Lint & Format

- **SwiftFormat**  
  - Utilisé pour le formatage automatique.  
  - Configuration via fichier `.swiftformat` à la racine.  
  - Commandes cibles : `swiftformat Sources Tests --lint` (CI) et `swiftformat .` (développeurs).  
  - Règles envisagées : indentation 4 espaces, `--swiftversion 5.10`, forcer les imports triés.

- **SwiftLint**  
  - Détection de problèmes de style et bonnes pratiques.  
  - Fichier `.swiftlint.yml` comprenant règles personnalisées (ex. `line_length: 130`, `closure_spacing`, `force_cast`).  
  - Execution locale via `swiftlint lint --strict` et intégration CI avec rapporter en annotations GitHub (via `swiftlint lint --reporter github-actions-logging`).

- **Danger Swift** (optionnel, phase ultérieure)  
  - Analyse des pull requests pour vérifier la présence de tests, notes de changelog, modifications dans Podspec/SPM.  
  - Nécessite configuration tokens GitHub et job dédié dans la CI.

## Workflow CI (GitHub Actions)

Pipeline recommandé déclenché sur `pull_request` et `push` vers `main`/`develop` :

1. **Setup**  
   - Action `actions/checkout@v4`.  
   - Installation Swift via `swift-actions/setup-swift@v1` (fosus Swift 5.10+).  
   - Cache `.build` via `actions/cache`.

2. **Lint & Format**  
   - Job `lint` exécutant `swiftformat` en mode lint puis `swiftlint`.  
   - Faille le workflow si un problème est détecté ; instructions fournies dans la sortie.

3. **Build & Tests**  
   - `swift build -v` pour s’assurer de la compilation.  
   - `swift test --parallel`.  
   - Matrix possible iOS/macOS/tvOS via `xcodebuild` quand les targets seront configurées (stade ultérieur).

4. **Documentation** (optionnel)  
   - Génération DocC (`swift package generate-documentation`) et publication sur GitHub Pages si `main`.

5. **Artifacts**  
   - Archivage des rapports tests (`.xcresult`), logs lint, documentation générée.

## Intégration Locale

- Script `make lint` (appelle SwiftFormat + SwiftLint).  
- `pre-commit` Git hook (optionnel) exécutant `swiftformat --lint` pour prévenir les erreurs avant commit.

## Points de Vigilance

- Veiller à ce que SwiftFormat/SwiftLint soient accessible via Homebrew ou SPM (documenter installation dans README).  
- Les règles devront être ajustées selon la base de code réelle (p. ex. activer/désactiver `trailing_whitespace`).  
- Danger Swift nécessite des variables secrètes GitHub et ne sera activé qu’une fois le flux de PR stabilisé.

