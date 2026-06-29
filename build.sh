#!/bin/bash
# Builds Tempo.app (menu-bar app) without Xcode, using swiftc + a hand-made
# bundle. Command Line Tools' SwiftPM manifest linking is broken, so we invoke
# swiftc directly.
set -euo pipefail

APP="Tempo.app"
SDK="$(xcrun --show-sdk-path)"

echo "Compiling…"
swiftc -O -target arm64-apple-macosx13.0 -sdk "$SDK" \
  -framework AppKit -framework SwiftUI -framework Combine -framework IOKit \
  -o Tempo Sources/Tempo/*.swift

echo "Assembling $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Tempo "$APP/Contents/MacOS/Tempo"
cp Info.plist "$APP/Contents/Info.plist"
[ -f icon.icns ] && cp icon.icns "$APP/Contents/Resources/icon.icns" || true

echo "Signing (ad-hoc)…"
codesign --force --deep --sign - "$APP"

echo "Done → $APP"
