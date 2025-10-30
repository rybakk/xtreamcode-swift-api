#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if command -v swiftformat >/dev/null 2>&1; then
  swiftformat Sources Tests --lint --config .swiftformat
else
  echo "warning: swiftformat not installed; skipping format lint" >&2
fi

if command -v swiftlint >/dev/null 2>&1; then
  swiftlint lint --strict
else
  echo "warning: swiftlint not installed; skipping SwiftLint" >&2
fi
