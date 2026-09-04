#!/usr/bin/env bash
# ==============================================================================
# Savings Tracker - Production Release Build & Archive Automation Script
# Targets: iOS 17.0+ | Configuration: Release | Distribution: App Store / TestFlight
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SCHEME="SavingsTrackerCore"
TEST_SCHEME="SavingsTrackerTests"
CONFIGURATION="Release"
BUILD_DIR="${SCRIPT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/SavingsTracker.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Export"

echo "=============================================================="
echo " 🚀  SAVINGS TRACKER - PRODUCTION RELEASE BUILD PIPELINE"
echo "=============================================================="
echo "  Configuration: ${CONFIGURATION}"
echo "  Deployment Target: iOS 17.0+"
echo "  Output Directory: ${BUILD_DIR}"
echo "=============================================================="

# 1. Clean Build Directory
echo "==> Cleaning previous build artifacts..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${EXPORT_PATH}"

# 2. Run Comprehensive Unit & Security Test Suites
echo "==> Running Automated Test Suites (swift test)..."
swift test -v

# 3. Build Release Archive
echo "==> Building Release Archive with xcodebuild..."
if command -v xcodebuild &>/dev/null; then
    xcodebuild archive \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -destination "generic/platform=iOS" \
        -archivePath "${ARCHIVE_PATH}" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

    # 4. Export Release Package (.ipa) if ExportOptions.plist exists
    if [[ -f "${SCRIPT_DIR}/ExportOptions.plist" ]]; then
        echo "==> Exporting IPA for App Store / TestFlight..."
        xcodebuild -exportArchive \
            -archivePath "${ARCHIVE_PATH}" \
            -exportOptionsPlist "${SCRIPT_DIR}/ExportOptions.plist" \
            -exportPath "${EXPORT_PATH}"
        echo "✅ IPA exported successfully to: ${EXPORT_PATH}"
    fi
else
    echo "ℹ️  xcodebuild not found in local environment (Linux host)."
    echo "    Swift Package has been fully verified. Run this script on macOS / Xcode CI runner to create the final .xcarchive and .ipa."
fi

echo "=============================================================="
echo " 🎉  BUILD & VERIFICATION PIPELINE COMPLETED SUCCESSFULLY"
echo "=============================================================="
