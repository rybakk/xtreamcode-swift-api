# Observabilité & Support

## Objectifs
- Diagnostiquer rapidement latence, erreurs Live/EPG et comportements cache.
- Offrir un hook pour intégrer des outils existants (OSLog, Firebase, Datadog…).
- Centraliser les informations pour le support (captures, rapports structurés).

## Logger configurable
- `LiveLogger` (protocole) expose `event(_:)` et `error(_:context:)`.
- `DefaultLiveLogger` (stdout en debug) est utilisé si aucun logger custom n’est fourni.
- Injection via `XtreamcodeSwiftAPI.Configuration(logger:)`.

### Événements recommandés
- `requestSent(endpoint: LiveEndpoint, parameters: [String: String])`
- `cacheHit(key: LiveCacheKey, source: LiveCacheSource)`
- `fallbackTriggered(key: LiveCacheKey, reason: OfflineReason)`
- `playbackStarted(streamID: Int, quality: String?)`

## Diagnostics cache
- `XtreamDiagnostics` accessible via `await api.diagnosticsSnapshot()` renvoie hits/miss/offline fallback + dernier `forceRefresh`.
- Réinitialisation avec `await api.resetDiagnostics()` (utile après analyse support).

## Support Playbook
- Créer `docs/support-playbook.md` (ressources à rédiger) avec :
  1. Checklist initiale (version SDK, portail Xtream, logs).
  2. Scripts : `./scripts/test.sh --integration`, `./scripts/test.sh --live`.
  3. Procédure reproduction (pull logs `LiveLogger`, exporter caches).

■ TODO Sprint 3 :
- Implémenter `LiveLogger`.
- Ajouter remontée des métriques `cacheHits/miss`.
- Alimenter `docs/support-playbook.md`.
