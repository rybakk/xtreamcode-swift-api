#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== XtreamcodeSwiftAPI – Démo Sprint 3 (VOD/Séries & Progression) ==="
echo "1. Tests unitaires VOD/Séries (catalogues + recherche)"
swift test --filter "XtreamVODSeriesServiceTests"

echo
echo "2. Progression (ProgressStore)"
swift test --filter "XtreamAPIMediaTests/testProgressStoreRoundTrip"

echo
cat <<'EOF'
3. Exemple d'intégration :
    let vod = try await api.vodDetails(for: 130529)
    print(vod.info?.name ?? "-")

    try await api.saveProgress(contentID: "vod-130529", position: 120, duration: 360)
    if let resume = try await api.loadProgress(contentID: "vod-130529") {
        print("Reprise à \(resume.position)s")
    }

    let report = await api.makeMediaIssueReport(
        domain: .vod,
        context: LiveContext(endpoint: "get_vod_info", vodID: 130529),
        error: nil
    )
EOF
