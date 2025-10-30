#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== XtreamcodeSwiftAPI – Démo d'authentification (Sprint 1) ==="
echo "1) Compilation & exécution du test d'intégration principal"
swift test --filter XtreamAPIIntegrationTests/testAuthenticateThenFetchAccountUsesCache

cat <<'EOF'

Succès attendu :
- Authentification du compte factice (fixtures `auth_login_success_current.json`).
- Récupération des informations de compte (`account_user_info_current.json`).
- Utilisation du cache : l'appel `get_user_info` n'est exécuté qu'une seule fois.

Cette démonstration s'appuie sur les stubs réseau (`StubURLProtocol`) pour garantir un scénario reproductible.
EOF
