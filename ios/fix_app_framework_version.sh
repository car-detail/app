#!/bin/bash

# This script replaces placeholders in App.framework Info.plist with actual version numbers
# It reads from Generated.xcconfig and updates the App.framework Info.plist

set -e

# Get the Flutter build directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FLUTTER_BUILD_DIR="${PROJECT_ROOT}/build/ios"
GENERATED_XCCONFIG="${PROJECT_ROOT}/ios/Flutter/Generated.xcconfig"

# Read version from Generated.xcconfig
if [ -f "$GENERATED_XCCONFIG" ]; then
    FLUTTER_BUILD_NAME=$(grep "FLUTTER_BUILD_NAME=" "$GENERATED_XCCONFIG" | cut -d'=' -f2 | tr -d ' ')
    FLUTTER_BUILD_NUMBER=$(grep "FLUTTER_BUILD_NUMBER=" "$GENERATED_XCCONFIG" | cut -d'=' -f2 | tr -d ' ')
else
    echo "Warning: Generated.xcconfig not found, using defaults"
    FLUTTER_BUILD_NAME="1.6.0"
    FLUTTER_BUILD_NUMBER="1"
fi

# Find App.framework Info.plist
APP_FRAMEWORK_INFO_PLIST="${FLUTTER_BUILD_DIR}/iphoneos/Runner.app/Frameworks/App.framework/Info.plist"

if [ -f "$APP_FRAMEWORK_INFO_PLIST" ]; then
    echo "Updating App.framework Info.plist with version ${FLUTTER_BUILD_NAME} (${FLUTTER_BUILD_NUMBER})"
    
    # Use PlistBuddy to update the values
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${FLUTTER_BUILD_NAME}" "$APP_FRAMEWORK_INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${FLUTTER_BUILD_NUMBER}" "$APP_FRAMEWORK_INFO_PLIST"
    
    echo "App.framework Info.plist updated successfully"
else
    echo "Warning: App.framework Info.plist not found at ${APP_FRAMEWORK_INFO_PLIST}"
fi

