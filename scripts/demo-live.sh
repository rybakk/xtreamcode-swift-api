#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== XtreamcodeSwiftAPI – Démo Sprint 2 (Live/EPG) ==="
echo "1. Tests d'intégration façade (cache + fallback offline)"
swift test --filter XtreamAPIIntegrationTests/testLiveParcoursCompleteAvecCache

echo
cat <<'EOF'
2. Relevé diagnostics (dans l'app hôte) :
    let snapshot = await api.diagnosticsSnapshot()
    print(snapshot)
EOF
