#!/bin/bash
set -e

# ============================================
# GrossUp - Build and Upload to App Store Connect
# ============================================
#
# Prerequisites:
# 1. Xcode installed with valid signing certificates
# 2. App registered in App Store Connect
# 3. App Store Connect API Key (recommended) OR Apple ID credentials
#
# Usage:
#   ./scripts/build-and-upload.sh [--skip-upload]
#
# Configuration:
#   Copy .env.example to .env and fill in your credentials
#   OR set environment variables directly
#
# Environment variables (for upload):
#   APP_STORE_CONNECT_API_KEY_ID     - API Key ID from App Store Connect
#   APP_STORE_CONNECT_ISSUER_ID      - Issuer ID from App Store Connect
#   APP_STORE_CONNECT_API_KEY_PATH   - Path to .p8 private key file
#
# OR (legacy method):
#   APPLE_ID                         - Your Apple ID email
#   APPLE_APP_SPECIFIC_PASSWORD      - App-specific password from appleid.apple.com

# Load .env file if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
if [ -f "$PROJECT_DIR/.env" ]; then
    echo "Loading credentials from .env..."
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# Configuration
PROJECT_NAME="GrossUp"
SCHEME="GrossUp"
BUNDLE_ID="com.jaredhilton.GrossUp"
TEAM_ID="S863LZ43ZG"

# Paths (SCRIPT_DIR and PROJECT_DIR already set above for .env loading)
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_step() {
    echo -e "${GREEN}==>${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

echo_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Parse arguments
SKIP_UPLOAD=false
for arg in "$@"; do
    case $arg in
        --skip-upload)
            SKIP_UPLOAD=true
            shift
            ;;
    esac
done

# Select export options based on upload mode
if [ "$SKIP_UPLOAD" = true ]; then
    EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions-local.plist"
    echo_step "Using local export options (no upload)"
else
    EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"
fi

# Clean build directory
echo_step "Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build archive
echo_step "Building archive..."
xcodebuild archive \
    -project "$PROJECT_DIR/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    | xcpretty || xcodebuild archive \
    -project "$PROJECT_DIR/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Automatic

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo_error "Archive failed - no archive created"
    exit 1
fi

echo_step "Archive created at: $ARCHIVE_PATH"

# Export IPA
echo_step "Exporting IPA for App Store..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    | xcpretty || xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS"

IPA_PATH="$EXPORT_PATH/$PROJECT_NAME.ipa"
if [ ! -f "$IPA_PATH" ]; then
    echo_error "Export failed - no IPA created"
    exit 1
fi

echo_step "IPA created at: $IPA_PATH"

# Upload to App Store Connect
if [ "$SKIP_UPLOAD" = true ]; then
    echo_warning "Skipping upload (--skip-upload flag set)"
    echo_step "Build complete! IPA ready at: $IPA_PATH"
    exit 0
fi

echo_step "Uploading to App Store Connect..."

# Check for API Key authentication (preferred)
if [ -n "$APP_STORE_CONNECT_API_KEY_ID" ] && [ -n "$APP_STORE_CONNECT_ISSUER_ID" ] && [ -n "$APP_STORE_CONNECT_API_KEY_PATH" ]; then
    echo "Using App Store Connect API Key authentication..."
    xcrun altool --upload-app \
        --type ios \
        --file "$IPA_PATH" \
        --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
        --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"

# Fall back to Apple ID authentication
elif [ -n "$APPLE_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    echo "Using Apple ID authentication..."
    xcrun altool --upload-app \
        --type ios \
        --file "$IPA_PATH" \
        --username "$APPLE_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD"

else
    echo_warning "No authentication credentials found."
    echo ""
    echo "To upload, set one of these environment variable combinations:"
    echo ""
    echo "Option 1 - API Key (recommended):"
    echo "  export APP_STORE_CONNECT_API_KEY_ID='your-key-id'"
    echo "  export APP_STORE_CONNECT_ISSUER_ID='your-issuer-id'"
    echo "  export APP_STORE_CONNECT_API_KEY_PATH='/path/to/AuthKey_XXXX.p8'"
    echo ""
    echo "Option 2 - Apple ID:"
    echo "  export APPLE_ID='your@email.com'"
    echo "  export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'"
    echo "  (Create app-specific password at https://appleid.apple.com)"
    echo ""
    echo "Then run this script again, or upload manually:"
    echo "  xcrun altool --upload-app --type ios --file \"$IPA_PATH\" --username YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD"
    exit 1
fi

echo_step "Upload complete! Check App Store Connect for processing status."
