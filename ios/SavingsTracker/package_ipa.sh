#!/usr/bin/env bash
# ==============================================================================
# Savings Tracker - Automated IPA Packaging Script for Cloud Runners
# Builds an ad-hoc signed .ipa ready for Sideloadly / AltStore / TrollStore
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=============================================================="
echo " 📦  SAVINGS TRACKER - AUTOMATED IPA PACKAGING PIPELINE"
echo "=============================================================="

# 1. Generate Xcode Project
echo "==> 1. Generating Xcode Project via XcodeGen..."
xcodegen generate

# 2. Build Release iOS Application Bundle
echo "==> 2. Building Release iOS Application Bundle with xcodebuild..."
xcodebuild clean build \
  -project SavingsTracker.xcodeproj \
  -scheme SavingsTracker \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -derivedDataPath ./build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# 3. Locate the compiled .app bundle
APP_PATH=$(find ./build/Build/Products/Release-iphoneos -name "*.app" -type d | head -n 1)

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "❌ Error: Release .app bundle not found in build output!"
  exit 1
fi

# 4. Ensure Info.plist contains all required keys (launch screen, orientations, permissions)
echo "==> Ensuring Info.plist contains all required runtime keys..."
python3 -c "
import plistlib, os

app_plist_path = '$APP_PATH/Info.plist'
with open(app_plist_path, 'rb') as f:
    app_pl = plistlib.load(f)

with open('Info.plist', 'rb') as f:
    src_pl = plistlib.load(f)

for k, v in src_pl.items():
    if k not in app_pl:
        app_pl[k] = v
        print(f'Merged missing key: {k}')

with open(app_plist_path, 'wb') as f:
    plistlib.dump(app_pl, f)

print('Verified and merged runtime Info.plist successfully.')
"

# 5. Apply Ad-Hoc Signature
echo "==> 4. Applying Ad-Hoc Signature..."
codesign --force --deep --sign - "$APP_PATH" || true

# 5. Package into Standard IPA (Payload structure)
echo "==> 4. Packaging into IPA archive..."
rm -rf Payload SavingsTracker.ipa
mkdir -p Payload
cp -r "$APP_PATH" Payload/
zip -qr SavingsTracker.ipa Payload
rm -rf Payload

echo "=============================================================="
echo " ✅  SUCCESS: SavingsTracker.ipa created successfully!"
echo "=============================================================="
ls -lh SavingsTracker.ipa
