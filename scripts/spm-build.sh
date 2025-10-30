#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔨 Building Xtreamcode Swift API with Swift Package Manager..."

# Parse options
BUILD_MODE="release"
RUN_TESTS=false
GENERATE_DOCS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)
            BUILD_MODE="debug"
            shift
            ;;
        --release)
            BUILD_MODE="release"
            shift
            ;;
        --test)
            RUN_TESTS=true
            shift
            ;;
        --docs)
            GENERATE_DOCS=true
            shift
            ;;
        --all)
            RUN_TESTS=true
            GENERATE_DOCS=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Build the package
echo "📦 Building in $BUILD_MODE mode..."
swift build -c "$BUILD_MODE" "$@"
echo "✅ Build completed successfully"

# Run tests if requested
if [ "$RUN_TESTS" = true ]; then
    echo ""
    echo "🧪 Running tests..."
    swift test
    echo "✅ All tests passed"
fi

# Generate DocC documentation if requested
if [ "$GENERATE_DOCS" = true ]; then
    echo ""
    echo "📚 Generating DocC documentation..."
    if command -v docc >/dev/null 2>&1 || command -v swift-docc >/dev/null 2>&1; then
        swift package generate-documentation --target XtreamcodeSwiftAPI
        echo "✅ Documentation generated successfully"
        echo "💡 Preview with: docc preview .build/plugins/Swift-DocC/outputs/XtreamcodeSwiftAPI.doccarchive"
    else
        echo "⚠️  DocC not available. Install with: brew install swift-docc"
    fi
fi

echo ""
echo "🎉 SPM build process completed successfully!"
