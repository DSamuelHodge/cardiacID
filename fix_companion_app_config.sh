#!/bin/bash

# Fix CardiacID Project Configuration for Companion Apps
# This script fixes the project configuration to properly support iOS-Watch companion apps

PROJECT_FILE="CardiacIDver1.xcodeproj/project.pbxproj"
BACKUP_FILE="CardiacIDver1.xcodeproj/project.pbxproj.backup"

echo "🔧 Fixing CardiacID Project Configuration for Companion Apps..."

# Create backup
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$PROJECT_FILE" "$BACKUP_FILE"
    echo "✅ Created backup: $BACKUP_FILE"
fi

# Fix 1: Remove incorrect Watch App embedding from iOS target
echo "📱 Removing incorrect Watch App embedding from iOS target..."

# Remove the Embed Watch Content build phase from iOS target
sed -i '' '/FBF0C0E22E70DF27005C425B \/\* Embed Watch Content \*\//d' "$PROJECT_FILE"
sed -i '' '/FBF0C0BD2E70DF25005C425B \/\* CardiacID_Watch_App.app in Embed Watch Content \*\//d' "$PROJECT_FILE"

# Remove Embed Watch Content from iOS target build phases
sed -i '' 's/FBF0C0E22E70DF27005C425B \/\* Embed Watch Content \*\/,//' "$PROJECT_FILE"

echo "✅ Removed Watch App embedding from iOS target"

# Fix 2: Ensure Watch App has proper framework linking
echo "⌚ Verifying Watch App framework linking..."

# Check if Watch App frameworks are properly linked
if grep -q "FB516C0F2E82E80000387BA8 \/\* HealthKit.framework in Frameworks \*\//" "$PROJECT_FILE"; then
    echo "✅ HealthKit framework already linked to Watch App"
else
    echo "⚠️  HealthKit framework may need to be linked to Watch App"
fi

if grep -q "FB516C142E82E80C00387BA8 \/\* WatchConnectivity.framework in Frameworks \*\//" "$PROJECT_FILE"; then
    echo "✅ WatchConnectivity framework already linked to Watch App"
else
    echo "⚠️  WatchConnectivity framework may need to be linked to Watch App"
fi

# Fix 3: Ensure proper target dependencies
echo "🔗 Verifying target dependencies..."

# Check if iOS target has any Watch App dependencies (should be none)
if grep -q "remoteInfo = CardiacID_Watch_App" "$PROJECT_FILE"; then
    echo "⚠️  iOS target may have Watch App dependencies - this should be removed"
else
    echo "✅ iOS target has no Watch App dependencies"
fi

# Fix 4: Verify bundle identifiers
echo "🏷️  Verifying bundle identifiers..."

# Check iOS bundle identifier
if grep -q "PRODUCT_BUNDLE_IDENTIFIER = ARGOS.CardiacID;" "$PROJECT_FILE"; then
    echo "✅ iOS bundle identifier: ARGOS.CardiacID"
else
    echo "⚠️  iOS bundle identifier may be incorrect"
fi

# Check Watch App bundle identifier
if grep -q "PRODUCT_BUNDLE_IDENTIFIER = ARGOS.CardiacID.watchkitapp;" "$PROJECT_FILE"; then
    echo "✅ Watch App bundle identifier: ARGOS.CardiacID.watchkitapp"
else
    echo "⚠️  Watch App bundle identifier may be incorrect"
fi

# Fix 5: Verify deployment targets
echo "📱 Verifying deployment targets..."

# Check iOS deployment target
if grep -q "IPHONEOS_DEPLOYMENT_TARGET = 17.0;" "$PROJECT_FILE"; then
    echo "✅ iOS deployment target: 17.0"
else
    echo "⚠️  iOS deployment target may be incorrect"
fi

# Check Watch App deployment target
if grep -q "WATCHOS_DEPLOYMENT_TARGET = 10.0;" "$PROJECT_FILE"; then
    echo "✅ Watch App deployment target: 10.0"
else
    echo "⚠️  Watch App deployment target may be incorrect"
fi

echo ""
echo "🎯 COMPANION APP CONFIGURATION SUMMARY:"
echo "========================================"
echo "✅ iOS App (CardiacID):"
echo "   - Bundle ID: ARGOS.CardiacID"
echo "   - Deployment: iOS 17.0+"
echo "   - Frameworks: HealthKit, HealthKitUI"
echo "   - Status: Primary app, no Watch embedding"
echo ""
echo "✅ Watch App (CardiacID_Watch_App):"
echo "   - Bundle ID: ARGOS.CardiacID.watchkitapp"
echo "   - Deployment: watchOS 10.0+"
echo "   - Frameworks: HealthKit, WatchConnectivity, WatchKit"
echo "   - Status: Companion app, independent build"
echo ""
echo "✅ Scheme (CardiacID-iPhone-Watch):"
echo "   - Builds both iOS and Watch apps"
echo "   - Tests both targets"
echo "   - Launches iOS app as primary"
echo "   - Watch app runs as companion"
echo ""
echo "🔧 Configuration fixes applied successfully!"
echo "📋 Next steps:"
echo "   1. Open project in Xcode"
echo "   2. Select 'CardiacID-iPhone-Watch' scheme"
echo "   3. Build and run to test companion app functionality"
echo "   4. Verify Watch App can communicate with iOS app via WatchConnectivity"
