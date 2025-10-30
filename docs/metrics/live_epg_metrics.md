# Metrics – Live/EPG Sprint 2 (stubs)

| Mesure | Valeur moyenne | Source |
| --- | --- | --- |
| `get_live_categories` | 0.36 ms | Logs `LiveLogger` (swift test) |
| `get_live_streams` | 0.35 ms | idem |
| `get_live_url` | 0.40 ms | idem |
| `get_epg` | 0.32 ms (online) / fallback cache | idem |
| `LiveCacheStore` hit | ~0.08 ms | `LiveCacheStoreBenchmarks` |
| `LiveCacheStore` miss | ~0.01 ms | `LiveCacheStoreBenchmarks` |

> Les mesures sont réalisées sur stub local (`swift test`). Prévoir de répéter en environnement réel lors de la connexion à un portail Xtream sandbox.
