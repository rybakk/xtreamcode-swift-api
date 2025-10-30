#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# TODO: ajouter les options spécifiques (ex: --sources, --no-clean) si nécessaire.
if command -v pod >/dev/null 2>&1; then
  pod spec lint xtreamcode-swift-api.podspec --allow-warnings "$@"
else
  echo "error: CocoaPods (pod) non disponible dans le PATH" >&2
  exit 1
fi
