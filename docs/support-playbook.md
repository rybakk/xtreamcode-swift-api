# Support Playbook – Live & EPG

## 1. Informations à collecter
- Version SDK (`XtreamcodeSwiftAPI`), commit hash.
- Portail Xtream Codes (URL, version), environnement (prod/sandbox).
- Plateforme (iOS/macOS/tvOS), OS version, device.
- Logs `LiveLogger` (niveau debug) couvrant le scénario repro.
- Sortie `await api.diagnosticsSnapshot()` (cache hits/miss, offline fallback).
- Rapport `MediaIssueReport` via `await api.makeMediaIssueReport(domain:context:error:)` (JSON partageable avec le support).

## 2. Checklists rapides
1. **Connexion** : `./scripts/demo-auth.sh` doit réussir.
2. **Tests unitaires Live/EPG** : `./scripts/test.sh --live`.
3. **Intégration façade** : `./scripts/test.sh --integration`.
4. **Benchmarks cache** : `./scripts/test.sh --benchmarks` (optionnel, comparer au baseline).
5. **VOD/Séries** : `./scripts/test.sh --vod-series`.

## 3. Scénarios type
- **Live indisponible** : vérifier `XtreamError.liveUnavailable` + token TTL. Relancer `forceRefresh`.
- **EPG vide** : comparer la plage start/end, vérifier `get_epg` via cURL.
- **Catch-up** : confirmer que l’abonnement active `tv_archive` > 0.
- **Offline** : valider l’usage fallback (diagnostics `offlineFallbacks` > 0) puis reconnecter.
- **VOD indisponible** : `XtreamError.vodUnavailable` → vérifier l’ID de film, retenter avec `forceRefresh: true` et inspecter la réponse `get_vod_info`.
- **Série incomplète** : `XtreamError.seriesUnavailable` ou `episodeNotFound` → contrôler la saison/épisode coté portail et valider les métadonnées.
- **Recherche** : `XtreamError.searchFailed` → tester la recherche ciblée (`type: .movie`) et comparer les logs côté serveur.

## 4. Export de logs
```swift
struct SupportLogger: LiveLogger {
    func event(_ event: LiveLogEvent) { print("[Support] event:", event) }
    func error(_ error: Error, context: LiveContext?) { print("[Support] error:", error, context ?? LiveContext()) }
}
```
Injecter `logger: SupportLogger()` dans `XtreamcodeSwiftAPI.Configuration` puis reproduire le bug.

### Rapport d'incident Media
```swift
let report = await api.makeMediaIssueReport(
    domain: .live,
    context: LiveContext(endpoint: "get_live_streams", streamID: streamID),
    error: lastError,
    additionalNotes: ["device": "Apple TV 4K"]
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let json = try encoder.encode(report)

// Exemple pour un film indisponible
let vodReport = await api.makeMediaIssueReport(
    domain: .vod,
    context: LiveContext(endpoint: "get_vod_info", vodID: vodID),
    error: lastError
)
```
Transmettre le JSON généré au support avec les logs et étapes de reproduction.

## 5. Escalade
- Si le portail renvoie une erreur HTTP récurrente, joindre JSON brut (`StubURLProtocol` permet de capturer `payload`).
- Documenter les étapes exactes (catégorie, flux, timestamp, timezone).
- Fournir captures tvOS (Focus ring, Siri remote).
