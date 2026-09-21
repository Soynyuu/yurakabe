#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild -project Yurakabe.xcodeproj -scheme Yurakabe \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' build
app='build/Build/Products/Release/Yurakabe.app'
codesign --force --sign - --entitlements scripts/extension.entitlements "$app/Contents/Extensions/YurakabeExtension.appex"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
printf '\nBuilt locally signed app: %s\n' "$app"
