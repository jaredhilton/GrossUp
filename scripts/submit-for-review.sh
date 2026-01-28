#!/bin/bash
# Submit app to App Store for review using App Store Connect API
# Requires: APP_STORE_CONNECT_API_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_API_KEY_PATH

set -e

# Configuration
APP_BUNDLE_ID="com.jaredhilton.GrossUp"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_step() { echo -e "${GREEN}==>${NC} $1"; }
echo_error() { echo -e "${RED}Error:${NC} $1"; }

# Load .env if exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# Generate JWT token for App Store Connect API
generate_jwt() {
    local key_id=$APP_STORE_CONNECT_API_KEY_ID
    local issuer_id=$APP_STORE_CONNECT_ISSUER_ID
    local key_path=$APP_STORE_CONNECT_API_KEY_PATH
    
    # JWT Header
    local header=$(echo -n '{"alg":"ES256","kid":"'$key_id'","typ":"JWT"}' | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
    
    # JWT Payload (20 min expiry)
    local now=$(date +%s)
    local exp=$((now + 1200))
    local payload=$(echo -n '{"iss":"'$issuer_id'","iat":'$now',"exp":'$exp',"aud":"appstoreconnect-v1"}' | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
    
    # Sign with ES256
    local signature=$(echo -n "$header.$payload" | openssl dgst -sha256 -sign "$key_path" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
    
    echo "$header.$payload.$signature"
}

# Get app ID from bundle ID
get_app_id() {
    local token=$1
    
    curl -s "https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]=$APP_BUNDLE_ID" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" | jq -r '.data[0].id'
}

# Get latest build waiting for review
get_latest_build() {
    local token=$1
    local app_id=$2
    
    # Get builds in "PROCESSING" or "VALID" state
    curl -s "https://api.appstoreconnect.apple.com/v1/builds?filter[app]=$app_id&sort=-uploadedDate&limit=1" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" | jq -r '.data[0].id'
}

# Get or create app store version
get_or_create_version() {
    local token=$1
    local app_id=$2
    local version=$3
    
    # Check for existing version in PREPARE_FOR_SUBMISSION state
    local existing=$(curl -s "https://api.appstoreconnect.apple.com/v1/apps/$app_id/appStoreVersions?filter[versionString]=$version&filter[platform]=IOS" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" | jq -r '.data[0].id')
    
    if [ "$existing" != "null" ] && [ -n "$existing" ]; then
        echo "$existing"
        return
    fi
    
    # Create new version
    local response=$(curl -s -X POST "https://api.appstoreconnect.apple.com/v1/appStoreVersions" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "{
            \"data\": {
                \"type\": \"appStoreVersions\",
                \"attributes\": {
                    \"platform\": \"IOS\",
                    \"versionString\": \"$version\"
                },
                \"relationships\": {
                    \"app\": {
                        \"data\": {
                            \"type\": \"apps\",
                            \"id\": \"$app_id\"
                        }
                    }
                }
            }
        }")
    
    echo "$response" | jq -r '.data.id'
}

# Update release notes (What's New)
update_release_notes() {
    local token=$1
    local version_id=$2
    local notes=$3
    
    # Get localization ID (assuming en-US)
    local loc_id=$(curl -s "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$version_id/appStoreVersionLocalizations" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" | jq -r '.data[] | select(.attributes.locale == "en-US") | .id')
    
    if [ -z "$loc_id" ] || [ "$loc_id" == "null" ]; then
        # Create localization
        curl -s -X POST "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d "{
                \"data\": {
                    \"type\": \"appStoreVersionLocalizations\",
                    \"attributes\": {
                        \"locale\": \"en-US\",
                        \"whatsNew\": $(echo "$notes" | jq -Rs .)
                    },
                    \"relationships\": {
                        \"appStoreVersion\": {
                            \"data\": {
                                \"type\": \"appStoreVersions\",
                                \"id\": \"$version_id\"
                            }
                        }
                    }
                }
            }"
    else
        # Update existing localization
        curl -s -X PATCH "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/$loc_id" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d "{
                \"data\": {
                    \"type\": \"appStoreVersionLocalizations\",
                    \"id\": \"$loc_id\",
                    \"attributes\": {
                        \"whatsNew\": $(echo "$notes" | jq -Rs .)
                    }
                }
            }"
    fi
}

# Link build to version
link_build_to_version() {
    local token=$1
    local version_id=$2
    local build_id=$3
    
    curl -s -X PATCH "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$version_id/relationships/build" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "{
            \"data\": {
                \"type\": \"builds\",
                \"id\": \"$build_id\"
            }
        }"
}

# Submit for review
submit_for_review() {
    local token=$1
    local version_id=$2
    
    curl -s -X POST "https://api.appstoreconnect.apple.com/v1/appStoreVersionSubmissions" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "{
            \"data\": {
                \"type\": \"appStoreVersionSubmissions\",
                \"relationships\": {
                    \"appStoreVersion\": {
                        \"data\": {
                            \"type\": \"appStoreVersions\",
                            \"id\": \"$version_id\"
                        }
                    }
                }
            }
        }"
}

# Main
VERSION=${1:-$(git describe --tags --abbrev=0 | sed 's/^v//')}
RELEASE_NOTES=${2:-"Bug fixes and improvements."}

echo_step "Submitting version $VERSION for App Store review..."

# Check for release notes file
if [ -f "/tmp/release_notes.txt" ]; then
    RELEASE_NOTES=$(cat /tmp/release_notes.txt)
    echo_step "Using AI-generated release notes"
fi

echo_step "Generating JWT token..."
TOKEN=$(generate_jwt)

echo_step "Getting app ID..."
APP_ID=$(get_app_id "$TOKEN")
echo "App ID: $APP_ID"

echo_step "Getting latest build..."
BUILD_ID=$(get_latest_build "$TOKEN" "$APP_ID")
echo "Build ID: $BUILD_ID"

echo_step "Creating/getting App Store version $VERSION..."
VERSION_ID=$(get_or_create_version "$TOKEN" "$APP_ID" "$VERSION")
echo "Version ID: $VERSION_ID"

echo_step "Updating release notes..."
update_release_notes "$TOKEN" "$VERSION_ID" "$RELEASE_NOTES"

echo_step "Linking build to version..."
link_build_to_version "$TOKEN" "$VERSION_ID" "$BUILD_ID"

echo_step "Submitting for review..."
RESULT=$(submit_for_review "$TOKEN" "$VERSION_ID")

if echo "$RESULT" | jq -e '.data' > /dev/null 2>&1; then
    echo_step "Successfully submitted for App Store review!"
    echo "Version $VERSION is now in review queue."
else
    echo_error "Submission failed:"
    echo "$RESULT" | jq .
    exit 1
fi
