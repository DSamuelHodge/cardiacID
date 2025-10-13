#!/bin/bash

# Script to verify DerivedData configuration

echo "🔍 Verifying DerivedData Configuration..."
echo ""

# Check Xcode preferences
echo "📋 Xcode Preferences:"
BUILD_LOCATION=$(defaults read com.apple.dt.Xcode IDEBuildLocationStyle 2>/dev/null || echo "Not set")
CUSTOM_PATH=$(defaults read com.apple.dt.Xcode IDECustomDerivedDataLocation 2>/dev/null || echo "Not set")

echo "   • Build Location Style: $BUILD_LOCATION"
echo "   • Custom DerivedData Path: $CUSTOM_PATH"
echo ""

# Check symbolic link
echo "🔗 Symbolic Link Status:"
SYMLINK_PATH="$HOME/Library/Developer/Xcode/DerivedData"
if [ -L "$SYMLINK_PATH" ]; then
    TARGET=$(readlink "$SYMLINK_PATH")
    echo "   • Link exists: $SYMLINK_PATH -> $TARGET"
    if [ -d "$TARGET" ]; then
        echo "   • Target directory exists: ✅"
    else
        echo "   • Target directory exists: ❌"
    fi
else
    echo "   • No symbolic link found: ❌"
fi
echo ""

# Check environment variable
echo "🌍 Environment Variable:"
if [ -n "$XCODE_DERIVED_DATA_PATH" ]; then
    echo "   • XCODE_DERIVED_DATA_PATH: $XCODE_DERIVED_DATA_PATH"
else
    echo "   • XCODE_DERIVED_DATA_PATH: Not set"
fi
echo ""

# Check custom directory
echo "📁 Custom DerivedData Directory:"
CUSTOM_DIR="$HOME/Desktop/ARGOS - Project HeartID/DerivedData"
if [ -d "$CUSTOM_DIR" ]; then
    echo "   • Directory exists: ✅"
    echo "   • Path: $CUSTOM_DIR"
    echo "   • Contents:"
    ls -la "$CUSTOM_DIR" | sed 's/^/     /'
else
    echo "   • Directory exists: ❌"
fi
echo ""

echo "🎯 Summary:"
if [ "$BUILD_LOCATION" = "Custom" ] && [ -d "$CUSTOM_DIR" ] && [ -L "$SYMLINK_PATH" ]; then
    echo "   ✅ DerivedData configuration is properly set up!"
    echo "   🔄 Restart Xcode to ensure changes take effect"
else
    echo "   ⚠️  Some configuration may need attention"
    echo "   🔄 Run ./set_custom_deriveddata.sh again if needed"
fi
