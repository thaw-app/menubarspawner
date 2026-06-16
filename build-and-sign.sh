#!/usr/bin/env bash
set -euo pipefail

# build-and-sign.sh
# Usage: ./scripts/build-and-sign.sh [scheme] [configuration] [export_method] [team_id]
# Example: ./scripts/build-and-sign.sh MenuBarSpawner Release development TEAMID123
#
# This script archives the app and exports an IPA using Xcode's automatic signing
# and provisioning. It requires that you are logged into your Apple developer
# account in Xcode and that automatic signing is enabled for the target.

SCHEME=${1:-MenuBarSpawner}
CONFIG=${2:-Release}
EXPORT_METHOD=${3:-development} # development, ad-hoc, app-store, enterprise
TEAM_ID=${4:-}

PROJECT_NAME="MenuBarSpawner"
BUILD_DIR="${PWD}/build"
ARCHIVE_PATH="$BUILD_DIR/${SCHEME}.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"

mkdir -p "$BUILD_DIR"

# Determine whether to use workspace or project
if [[ -d "${PROJECT_NAME}.xcworkspace" ]]; then
  XCODE_ARG=( -workspace "${PROJECT_NAME}.xcworkspace" )
else
  XCODE_ARG=( -project "${PROJECT_NAME}.xcodeproj" )
fi

echo "Scheme: $SCHEME"
echo "Configuration: $CONFIG"
echo "Export method: $EXPORT_METHOD"
if [[ -n "$TEAM_ID" ]]; then echo "Team: $TEAM_ID"; fi

echo "Cleaning and archiving..."
xcodebuild clean "${XCODE_ARG[@]}" -scheme "$SCHEME" -configuration "$CONFIG"

ARCHIVE_CMD=( xcodebuild "${XCODE_ARG[@]}" -scheme "$SCHEME" -configuration "$CONFIG" -archivePath "$ARCHIVE_PATH" archive -allowProvisioningUpdates )
if [[ -n "$TEAM_ID" ]]; then
  ARCHIVE_CMD+=( DEVELOPMENT_TEAM="$TEAM_ID" CODE_SIGN_STYLE=Automatic )
fi

"${ARCHIVE_CMD[@]}"

echo "Generating exportOptions.plist..."
EXPORT_PLIST="$BUILD_DIR/exportOptions.plist"
cat > "$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>$EXPORT_METHOD</string>
  <key>compileBitcode</key>
  <false/>
  <key>thin</key>
  <true/>
  <key>signingStyle</key>
  <string>automatic</string>
</dict>
</plist>
EOF

if [[ -n "$TEAM_ID" ]]; then
  /usr/libexec/PlistBuddy -c "Add :teamID string $TEAM_ID" "$EXPORT_PLIST" >/dev/null 2>&1 || true
fi

echo "Exporting archive..."
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportOptionsPlist "$EXPORT_PLIST" -exportPath "$EXPORT_PATH" -allowProvisioningUpdates

echo "Build and export complete. See: $EXPORT_PATH"

# Try to locate a built macOS .app and launch it
ARCHIVED_APP="$ARCHIVE_PATH/Products/Applications/${SCHEME}.app"
if [[ -d "$ARCHIVED_APP" ]]; then
  echo "Found app in archive: $ARCHIVED_APP"
  echo "Launching $ARCHIVED_APP..."
  open "$ARCHIVED_APP"
  exit 0
fi

# Check exported products (some projects export .app instead of IPA)
if [[ -d "$EXPORT_PATH" ]]; then
  FOUND_APP=$(find "$EXPORT_PATH" -maxdepth 1 -type d -name "*.app" -print -quit || true)
  if [[ -n "$FOUND_APP" ]]; then
    echo "Found exported app: $FOUND_APP"
    echo "Launching $FOUND_APP..."
    open "$FOUND_APP"
    exit 0
  fi

  FOUND_IPA=$(find "$EXPORT_PATH" -maxdepth 1 -type f -name "*.ipa" -print -quit || true)
  if [[ -n "$FOUND_IPA" ]]; then
    echo "Exported an IPA at: $FOUND_IPA"
    echo "Note: IPA files are for iOS — cannot launch on macOS desktop."
    exit 0
  fi
fi

echo "No .app found to launch. Build/export completed." 

exit 0
