#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
ARTIFACTS_DIR="$PROJECT_ROOT/Artifacts"
FRAMEWORK_NAME="XtreamcodeSwiftAPI"

echo "🏗️  Building XCFramework for Carthage distribution..."

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -rf "$ARTIFACTS_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$ARTIFACTS_DIR"

# Note: XCFramework generation from SPM packages requires creating a scheme first
# This is a template script - actual implementation depends on having Xcode schemes

echo "📦 Building for iOS..."
xcodebuild archive \
  -scheme "$FRAMEWORK_NAME" \
  -destination "generic/platform=iOS" \
  -archivePath "$BUILD_DIR/iOS" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  || echo "⚠️  iOS archive failed - Xcode scheme may not be configured"

echo "📦 Building for iOS Simulator..."
xcodebuild archive \
  -scheme "$FRAMEWORK_NAME" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$BUILD_DIR/iOS-Simulator" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  || echo "⚠️  iOS Simulator archive failed - Xcode scheme may not be configured"

echo "📦 Building for macOS..."
xcodebuild archive \
  -scheme "$FRAMEWORK_NAME" \
  -destination "platform=macOS" \
  -archivePath "$BUILD_DIR/macOS" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  || echo "⚠️  macOS archive failed - Xcode scheme may not be configured"

echo "📦 Building for tvOS..."
xcodebuild archive \
  -scheme "$FRAMEWORK_NAME" \
  -destination "generic/platform=tvOS" \
  -archivePath "$BUILD_DIR/tvOS" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  || echo "⚠️  tvOS archive failed - Xcode scheme may not be configured"

echo "📦 Building for tvOS Simulator..."
xcodebuild archive \
  -scheme "$FRAMEWORK_NAME" \
  -destination "generic/platform=tvOS Simulator" \
  -archivePath "$BUILD_DIR/tvOS-Simulator" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  || echo "⚠️  tvOS Simulator archive failed - Xcode scheme may not be configured"

# Create XCFramework
echo "🔨 Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "$BUILD_DIR/iOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -framework "$BUILD_DIR/iOS-Simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -framework "$BUILD_DIR/macOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -framework "$BUILD_DIR/tvOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -framework "$BUILD_DIR/tvOS-Simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -output "$ARTIFACTS_DIR/${FRAMEWORK_NAME}.xcframework" \
  || echo "⚠️  XCFramework creation failed - archives may be missing"

# Generate checksums
if [ -d "$ARTIFACTS_DIR/${FRAMEWORK_NAME}.xcframework" ]; then
    echo "🔐 Generating checksums..."
    cd "$ARTIFACTS_DIR"
    zip -r "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"
    shasum -a 256 "${FRAMEWORK_NAME}.xcframework.zip" > "${FRAMEWORK_NAME}.xcframework.zip.sha256"
    echo "✅ XCFramework created successfully!"
    echo "📍 Location: $ARTIFACTS_DIR/${FRAMEWORK_NAME}.xcframework"
    echo "📍 Checksum: $ARTIFACTS_DIR/${FRAMEWORK_NAME}.xcframework.zip.sha256"
    cat "${FRAMEWORK_NAME}.xcframework.zip.sha256"
else
    echo "❌ XCFramework generation failed"
    echo "💡 Note: This requires Xcode schemes to be properly configured"
    echo "💡 For SPM-only distribution, XCFramework may not be necessary"
    exit 1
fi
