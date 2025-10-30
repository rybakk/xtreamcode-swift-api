#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# TODO: étendre ce script pour générer la documentation DocC, les artefacts SPM
# et publier les archives nécessaires lors des releases.
swift build "$@"
