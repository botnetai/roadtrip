#!/bin/bash
# Build and prepare app for App Store Connect upload
# Usage: ./scripts/build-for-asc.sh

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "📦 Building Roadtrip for App Store Connect..."
echo "Project: $PROJECT_DIR"

# Clean build directory
rm -rf build/Roadtrip.xcarchive build/export

# Archive
echo "🔨 Archiving..."
xcodebuild -project Roadtrip.xcodeproj \
  -scheme Roadtrip \
  -configuration Release \
  -archivePath build/Roadtrip.xcarchive \
  archive \
  -allowProvisioningUpdates \
  -quiet

echo "✅ Archive complete"

# Create export options
cat > build/ExportOptions.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>C4ZTUACCUP</string>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
PLIST

# Export IPA
echo "📤 Exporting IPA..."
xcodebuild -exportArchive \
  -archivePath build/Roadtrip.xcarchive \
  -exportOptionsPlist build/ExportOptions.plist \
  -exportPath build/export \
  -allowProvisioningUpdates \
  -quiet

echo "✅ Export complete: build/export/Roadtrip.ipa"

# Get build number
BUILD_NUM=$(defaults read "$PROJECT_DIR/build/Roadtrip.xcarchive/Info.plist" ApplicationProperties | grep CFBundleVersion | awk -F'"' '{print $2}')
echo "📱 Build: $BUILD_NUM"

# Open in Xcode Organizer for upload
echo "🚀 Opening Xcode Organizer..."
open -a Xcode build/Roadtrip.xcarchive

echo ""
echo "Next steps:"
echo "  1. In Xcode Organizer, select the archive"
echo "  2. Click 'Distribute App' → 'App Store Connect' → 'Upload'"
echo "  3. Follow prompts to upload"
