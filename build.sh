#!/bin/bash
# Builds a universal (arm64 + x86_64) Shadow Fight 2 .app for macOS
# using WebKit (WKWebView) directly — no Electron, no Chromium.
#
# Run this ON A MAC that has Xcode / the Command Line Tools installed:
#   chmod +x build.sh
#   ./build.sh
#
# Output: ./Shadow Fight 2.app

set -e

APP_NAME="Shadow Fight 2"
EXECUTABLE_NAME="ShadowFight2"
BUILD_DIR="build"
APP_DIR="${APP_NAME}.app"

echo "==> Cleaning previous build"
rm -rf "$BUILD_DIR" "$APP_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Compiling for arm64 (Apple Silicon)"
swiftc -O -target arm64-apple-macos11.0 \
    Sources/main.swift \
    -o "$BUILD_DIR/${EXECUTABLE_NAME}-arm64" \
    -framework Cocoa -framework WebKit

echo "==> Compiling for x86_64 (Intel)"
swiftc -O -target x86_64-apple-macos11.0 \
    Sources/main.swift \
    -o "$BUILD_DIR/${EXECUTABLE_NAME}-x86_64" \
    -framework Cocoa -framework WebKit

echo "==> Merging into a universal binary with lipo"
lipo -create \
    "$BUILD_DIR/${EXECUTABLE_NAME}-arm64" \
    "$BUILD_DIR/${EXECUTABLE_NAME}-x86_64" \
    -output "$BUILD_DIR/${EXECUTABLE_NAME}"

echo "==> Verifying architectures"
lipo -info "$BUILD_DIR/${EXECUTABLE_NAME}"

echo "==> Assembling .app bundle"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/${EXECUTABLE_NAME}" "$APP_DIR/Contents/MacOS/${EXECUTABLE_NAME}"
cp Info.plist "$APP_DIR/Contents/Info.plist"

if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"
else
    echo "    (no AppIcon.icns found — app will use the default icon; see README)"
fi

chmod +x "$APP_DIR/Contents/MacOS/${EXECUTABLE_NAME}"

echo "==> Ad-hoc code signing (lets it run without a paid Developer ID)"
codesign --force --deep --sign - "$APP_DIR"

echo ""
echo "Done! Built: $(pwd)/$APP_DIR"
echo "Double-click it, or run: open \"$APP_DIR\""
