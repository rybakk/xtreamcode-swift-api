# Xtream Fixtures

Samples imported from public datasets (tellytv/go.xtream-codes) and trimmed with `jq` when necessary.

| File | Source | Notes |
| --- | --- | --- |
| `auth_login_success.json` | Eternal auth.json | Authenticated session sample (legacy) |
| `account_user_info.json` | Hellraiser auth.json | Alternative account payload (legacy) |
| `auth_login_success_current.json` | Live portal (`player_api.php`) | Authenticated session sample (credentials anonymised) |
| `account_user_info_current.json` | Live portal (`action=get_user_info`) | Account info sample (credentials anonymised) |
| `auth_login_failure.json` | Synthesized | Mimics Xtream failure structure |
| `auth_login_invalid.json` | Synthesized | `auth=0`, status Disabled -> invalid credentials |
| `auth_login_expired.json` | Synthesized | Status Expired with future-less expiration |
| `auth_login_toomany.json` | Synthesized | Active connections reaching max (too many connections) |
| `live_categories.json` | Hellraiser get_live_categories.json | Full list |
| `live_streams_sample.json` | Hellraiser get_live_streams.json | First 10 entries |
| `live_categories_tnt_sample.json` | TNT get_live_categories.json | Subset (6) focusing on UK/US entertainment |
| `live_streams_tnt_sample.json` | TNT get_live_streams.json | Subset (5) with archive metadata |
| `live_stream_details_sample.json` | Derived from `live_streams_tnt_sample.json` | Single stream (details use case) |
| `vod_categories.json` | Hellraiser get_vod_categories.json | Full list |
| `vod_streams_sample.json` | Hellraiser get_vod_streams.json | First 10 entries |
| `series_categories.json` | Hellraiser get_series_categories.json | Full list |
| `series_sample.json` | Iris get_series.json | First 10 entries |
| `epg_tf1_short.json` | Live portal (`action=get_short_epg`) | EPG sample for stream 366 (TF1) |
| `epg_bbc_one_full.json` | Synthesized (based on BBC schedule) | Full EPG window (3 entries) |
| `catchup_bbc_one_segments.json` | Synthesized (based on Xtream archive schema) | Archive entries with durations |
| `live_stream_url_sample.json` | Synthesized | Multiple quality URLs for player demo |
| `search_tf1.json` | Live portal (`action=search`) | Search results for TF1 |
