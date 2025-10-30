# Live & EPG Cache Policy

Cette note décrit la stratégie de mise en cache adoptée pour le Sprint 2. Elle servira de référence pour l’implémentation des services `XtreamLiveService` et `XtreamEPGService` ainsi que pour la configuration exposée par la façade publique.

## Objectifs
- Réduire la charge réseau lorsque l’utilisateur parcourt les catalogues live/EPG.
- Garantir des données suffisament fraîches pour le guide des programmes.
- Faciliter l’invalidation manuelle (ex : pull-to-refresh) sans reboot du SDK.

## Stratégie par endpoint

| Endpoint | TTL par défaut | Conditions d’invalidation | Notes |
| --- | --- | --- | --- |
| `get_live_categories` | 6 heures | Invalidation manuelle (`forceRefresh`) / `logout` / `refreshSession` / changement de compte | Les catégories et regroupements évoluent rarement. |
| `get_live_streams` (tout catalogue) | 30 minutes | Invalidation manuelle / changement de compte / expiration TTL | Statut, icônes et drapeaux catch-up sont rafraîchis plusieurs fois/jour. |
| `get_live_streams` (filtré par `category_id`) | 30 minutes (mêmes clés de cache) | Idem + switch de catégorie (clé distincte) | Clé de cache différente par catégorie → navigation instantanée. |
| `get_live_streams&stream_id={id}` | 30 minutes | Invalidation manuelle / sélection d’un nouveau flux | Les métadonnées détaillées (numéro de chaîne, archive) sont stables mais doivent suivre le live. |
| `get_live_url` | 5 minutes | Invalidation manuelle / démarrage lecture / erreur token | URLs signées courte durée, fallback possible via `forceRefresh`. |
| `get_short_epg` | 10 minutes | Invalidation manuelle / dépassement de la fenêtre courante | Aperçu rapide (programme en cours + suivants). |
| `get_epg` (plage personnalisée) | 5 minutes | Invalidation manuelle / changement de fenêtre | Idéal pour timeline ou recherche précise. |
| `get_tv_archive` | 30 minutes | Invalidation manuelle / lecture catch-up réussie / changement de compte | Les segments sont générés par blocs horaires côté serveur. |

> ⚠️ Les TTL peuvent être ajustés via `LiveCacheConfiguration`. Un TTL ≤ 0 désactive le cache pour l’endpoint concerné.

## Implémentation
- `LiveCacheStore` définit `store(_:for:ttl:)`, `value(for:as:)`, `invalidate(for:)`, `invalidateAll()` avec des implémentations mémoire (`InMemoryLiveCacheStore`), disque (`DiskLiveCacheStore`) et hybride (`HybridLiveCacheStore`).
- `LiveCacheConfiguration` expose les TTL (table ci-dessus) et `DiskOptions` (capacité, dossier, activation). La façade instancie un cache hybride par défaut si aucun store custom n’est fourni.
- Les services `XtreamLiveService` et `XtreamEPGService` consomment le cache : lecture avant requête, écriture post-réponse, suppression automatique lors d’un logout ou d’un refresh session.
- `XtreamcodeSwiftAPI` expose `forceRefresh` sur les méthodes publiques (`liveCategories`, `liveStreams`, `epg`, `catchup`, `liveStreamURL`) ainsi qu’une méthode explicite `invalidateLiveCache()`. En cas d’erreur réseau lors d’un `forceRefresh`, la dernière valeur cache est restituée (fallback offline) et un évènement logger est émis.
- Les tests (`XtreamLiveServiceTests`, `XtreamEPGServiceTests`, `XtreamAPIIntegrationTests`) vérifient les hits cache et scénarios `forceRefresh`.

## Points d’attention
- Les clés de cache intègrent l’identifiant utilisateur afin d’éviter les fuites inter-comptes.
- Les dates EPG sont normalisées en timestamp UNIX pour conserver une granularité cohérente dans les clés.
- Le cache disque impose une limite (50 Mo par défaut) avec purge LRU simple.

## Prochaines étapes Doc & UX
- Ajouter la page DocC `LiveTV.md` (guide d’utilisation + exemples Combine/async).
- Décrire le playground `Live.playground` (séquence catalogue → EPG → catch-up).
- Documenter la configuration avançée (`LiveCacheConfiguration`, stores custom) dans la prochaine itération DocC.
