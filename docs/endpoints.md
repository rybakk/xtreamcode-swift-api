# Xtream Codes – Endpoints Inventory (à valider)

> Cette liste recense les endpoints publics couramment exposés par une instance Xtream Codes v2/v3.  
> Les noms/paramètres exacts peuvent varier selon l’hébergeur ou les personnalisations. Chaque endpoint devra être vérifié
> dans l’environnement cible avant implémentation définitive.
>
> Des exemples de réponses JSON sont disponibles dans `Tests/XtreamcodeSwiftAPITests/Fixtures` (sources publiques issues de `tellytv/go.xtream-codes`).

## 1. Authentification & Session

- `GET player_api.php?username={user}&password={pass}`  
  Retourne `user_info`, `server_info`, `available_channels` (selon config). Utilisé pour valider les identifiants et initialiser la session.
- `GET player_api.php?username={user}&password={pass}&action=auth` (optionnel suivant version)  
  Fournit un booléen de validité ; à utiliser pour pings rapides sans charges supplémentaires.
- `POST player_api.php` avec body `{"username": "...", "password": "...", "action": "handshake"}` (certaines implémentations)  
  Permet de récupérer un token temporaire lorsqu’activé.

## 2. Compte & Informations Serveur

- `GET player_api.php?username={user}&password={pass}&action=get_user_info`  
  Donne statut de l’abonnement, connexions actuelles, droits, expiration, quotas.
- `GET player_api.php?username={user}&password={pass}&action=get_account_info` (alias sur certains panels)  
  Synthèse des détails utilisateur.
- `GET player_api.php?username={user}&password={pass}&action=system_status`  
  Indique l’état du serveur, message de maintenance éventuel.
- `GET player_api.php?username={user}&password={pass}&action=player_api`  
  Endpoint générique retournant JSON complet (utilisé pour réduire les appels).

## 3. Live TV

- `GET player_api.php?username={user}&password={pass}&action=get_live_categories`  
  Liste des catégories live (`category_id`, `category_name`, `parent_id`).
- `GET player_api.php?username={user}&password={pass}&action=get_live_streams`  
  Catalogue complet des chaînes live (possibilité d’utiliser `&category_id={id}` pour filtrer).
- `GET player_api.php?username={user}&password={pass}&action=get_live_streams&stream_id={id}`  
  Détails individuels (titre, liens HLS/TS, timeshift).
- `GET player_api.php?username={user}&password={pass}&action=get_live_url&stream_id={id}` (selon panel)  
  Renvoie directement l’URL du flux (m3u8/ts) pour le player.
- `GET {base_url}/{stream_id}.{format}?token=...`  
  URL directe de streaming (utilisation après authentification, format `.m3u8`/`.ts`/`.mp4`).

## 4. EPG & Catch-Up

- `GET player_api.php?username={user}&password={pass}&action=get_short_epg&stream_id={id}&limit={n}`  
  Programmes à venir pour une chaîne (limite configurable).
- `GET player_api.php?username={user}&password={pass}&action=get_epg&stream_id={id}&start={timestamp}&end={timestamp}`  
  Programme détaillé entre deux dates (souvent limitée à 7 jours).
- `GET player_api.php?username={user}&password={pass}&action=get_tv_archive&stream_id={id}&start={timestamp}`  
  Liste les segments catch-up disponibles.
- `GET player_api.php?username={user}&password={pass}&action=get_simple_data_table&stream_id={id}`  
  Variante des données catch-up (titre, heure, durée).
- `GET timeshift/{user}/{password}/{duration}/{stream_id}.m3u8`  
  Flux catch-up direct (nécessite timeshift activé).

## 5. VOD (Films)

- `GET player_api.php?username={user}&password={pass}&action=get_vod_categories`
- `GET player_api.php?username={user}&password={pass}&action=get_vod_streams` (option `&category_id={id}`).
- `GET player_api.php?username={user}&password={pass}&action=get_vod_info&vod_id={id}`  
  Métadonnées détaillées (résumé, durée, genre, vidéos, sous-titres).
- `GET vod/{user}/{password}/{stream_id}.{format}`  
  URL de playback VOD.

## 6. Séries TV

- `GET player_api.php?username={user}&password={pass}&action=get_series_categories`
- `GET player_api.php?username={user}&password={pass}&action=get_series` (option `&category_id={id}`).
- `GET player_api.php?username={user}&password={pass}&action=get_series_info&series_id={id}`  
  Contient saisons, épisodes, sous-titres, posters.
- `GET series/{user}/{password}/{series_id}/{season}/{episode}.{format}`  
  URL d’épisode.

## 7. Enregistrements & Gestion DVR (selon support serveur)

- `GET player_api.php?username={user}&password={pass}&action=get_recordings`  
  Répertorie les enregistrements disponibles.
- `POST player_api.php` avec body `{ "action": "schedule_recording", "stream_id": ..., "start": ..., "duration": ... }`  
  Planifie un enregistrement (fonctionnalité activable côté serveur).
- `POST player_api.php` `{ "action": "delete_recording", "recording_id": ... }`  
  Supprime un enregistrement.

## 8. Recherche & Favoris

- `GET player_api.php?username={user}&password={pass}&action=search&search={keyword}`  
  Recherche multi-catalogues (films/séries/live). Certains panels exigent `type=live|movie|series`.
- `GET player_api.php?username={user}&password={pass}&action=get_favorites&type={live|movie|series}`  
  Liste des favoris côté serveur (si activé).
- `POST player_api.php` `{ "action": "add_favorite", "type": "...", "id": ... }`  
- `POST player_api.php` `{ "action": "remove_favorite", "type": "...", "id": ... }`  
  Favoris côté serveur optionnels. À défaut, prévoir une gestion locale.

## 9. Playlists & Utilitaires

- `GET get.php?username={user}&password={pass}&type=m3u_plus&output=ts`  
  Génère un fichier M3U complet.
- `GET panel_api.php?username={user}&password={pass}&action=get_reseller_info`  
  Pour comptes revendeurs (si requis).
- `GET player_api.php?username={user}&password={pass}&action=get_subreseller_panel_details`  
  Informations supplémentaires revendeur/sous-panel.

## 10. Administration (selon permissions)

- `GET panel_api.php?api_key={key}&action=servers`  
  Liste des serveurs backend (réservé admin).
- `POST panel_api.php` `{ "api_key": "...", "action": "set_user_status", ... }`  
  Gestion utilisateur côté admin (présent à titre informatif, souvent hors scope SDK utilisateur).

## Actions de Vérification Recommandées

- Tester chaque endpoint sur l’environnement cible pour confirmer les paramètres obligatoires et la forme des réponses.
- Documenter les variations (noms de champs, types, dates) par rapport à cette liste générique.
- Isoler les endpoints requis pour le MVP (Sprint 1 et 2) et noter leurs dépendances.
- Définir les stratégies d’authentification (token vs login/password) selon les fonctionnalités réellement activées.
- **Validation (portal de test)** : les endpoints `player_api.php`, `action=get_user_info`, `get_live_categories`, `get_live_streams`, `get_vod_categories`, `get_vod_streams`, `get_series_categories`, `get_series`, `get_short_epg`, `search` ont été appelés avec succès (voir fixtures dans `Tests/XtreamcodeSwiftAPITests/Fixtures/*_current.json`, `*sample.json`).
