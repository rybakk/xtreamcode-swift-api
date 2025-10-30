#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

MODE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --live)
            MODE="live"
            shift
            ;;
        --integration)
            MODE="integration"
            shift
            ;;
        --benchmarks)
            MODE="benchmarks"
            shift
            ;;
        --vod-series)
            MODE="vod_series"
            shift
            ;;
        *)
            break
            ;;
    esac
done

case "$MODE" in
    live)
        swift test --filter "XtreamLiveServiceTests|XtreamEPGServiceTests" "$@"
        ;;
    integration)
        swift test --filter XtreamAPIIntegrationTests "$@"
        ;;
    benchmarks)
        swift test --filter LiveCacheStoreBenchmarks "$@"
        ;;
    vod_series)
        swift test --filter 'XtreamVODSeriesServiceTests|XtreamAPIMediaTests' "$@"
        ;;
    *)
        swift test --parallel "$@"
        ;;
esac
