#!/bin/bash

# Script to diagnose and fix missing Swift module issues

echo "🔍 Diagnosing Swift Module Issues..."
echo ""

# Check current DerivedData location
echo "📁 Current DerivedData Location:"
if [ -L ~/Library/Developer/Xcode/DerivedData ]; then
    TARGET=$(readlink ~/Library/Developer/Xcode/DerivedData)
    echo "   • Symbolic link: ~/Library/Developer/Xcode/DerivedData -> $TARGET"
else
    echo "   • Direct directory: ~/Library/Developer/Xcode/DerivedData"
fi
echo ""

# Check for missing swiftmodule files
echo "🔍 Checking for Missing Swift Module Files:"
PROJECT_DIR="CardiacIDver1-evoexuucehoxphcizvlxugmavvfl"
DERIVED_DATA_PATH=$(readlink ~/Library/Developer/Xcode/DerivedData 2>/dev/null || echo ~/Library/Developer/Xcode/DerivedData)

# Check main app module
MAIN_MODULE_PATH="$DERIVED_DATA_PATH/$PROJECT_DIR/Build/Intermediates.noindex/CardiacIDver1.build/Release-watchos/CardiacID_Watch_App.build/Objects-normal/arm64_32/CardiacID_Watch_App.swiftmodule"

if [ -f "$MAIN_MODULE_PATH" ]; then
    echo "   ✅ CardiacID_Watch_App.swiftmodule: EXISTS"
else
    echo "   ❌ CardiacID_Watch_App.swiftmodule: MISSING"
fi

# Check test modules
TEST_MODULE_PATH="$DERIVED_DATA_PATH/$PROJECT_DIR/Build/Intermediates.noindex/CardiacIDver1.build/Release-watchos/CardiacID_Watch_AppTests.build/Objects-normal/arm64_32/CardiacID_Watch_AppTests.swiftmodule"

if [ -f "$TEST_MODULE_PATH" ]; then
    echo "   ✅ CardiacID_Watch_AppTests.swiftmodule: EXISTS"
else
    echo "   ❌ CardiacID_Watch_AppTests.swiftmodule: MISSING"
fi

echo ""

# Check build artifacts
echo "📋 Build Artifacts Status:"
BUILD_DIR="$DERIVED_DATA_PATH/$PROJECT_DIR/Build/Intermediates.noindex/CardiacIDver1.build/Release-watchos/CardiacID_Watch_App.build/Objects-normal/arm64_32"

if [ -d "$BUILD_DIR" ]; then
    echo "   • Build directory exists: ✅"
    echo "   • Files in build directory:"
    ls -la "$BUILD_DIR" | grep -E "\.(swiftmodule|json|o)$" | sed 's/^/     /'
else
    echo "   • Build directory exists: ❌"
fi
echo ""

# Check for compilation errors
echo "🔍 Checking for Compilation Issues:"
if [ -f "$BUILD_DIR/CardiacID_Watch_App-dependencies-8.json" ]; then
    echo "   • Dependencies file exists: ✅"
    DEP_COUNT=$(grep -c '"swift"' "$BUILD_DIR/CardiacID_Watch_App-dependencies-8.json" 2>/dev/null || echo "0")
    echo "   • Swift dependencies found: $DEP_COUNT"
else
    echo "   • Dependencies file exists: ❌"
fi

if [ -f "$BUILD_DIR/CardiacID_Watch_App.SwiftFileList" ]; then
    echo "   • Swift file list exists: ✅"
    FILE_COUNT=$(wc -l < "$BUILD_DIR/CardiacID_Watch_App.SwiftFileList" 2>/dev/null || echo "0")
    echo "   • Swift files to compile: $FILE_COUNT"
else
    echo "   • Swift file list exists: ❌"
fi
echo ""

# Provide solutions
echo "🛠️  Recommended Solutions:"
echo ""

if [ ! -f "$MAIN_MODULE_PATH" ]; then
    echo "1. 🧹 Clean Build:"
    echo "   • Product → Clean Build Folder in Xcode"
    echo "   • Or run: rm -rf '$DERIVED_DATA_PATH/$PROJECT_DIR'"
    echo ""
fi

echo "2. 🔄 Rebuild Project:"
echo "   • Build → Build for Running in Xcode"
echo "   • Or run: xcodebuild -project CardiacIDver1.xcodeproj -scheme CardiacID_Watch_App -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build"
echo ""

echo "3. ⚙️  Check Build Settings:"
echo "   • Verify 'Build Active Architecture Only' is set correctly"
echo "   • Check 'Valid Architectures' includes arm64_32"
echo "   • Ensure 'Swift Compiler - Code Generation' settings are correct"
echo ""

echo "4. 🔍 Debug Compilation:"
echo "   • Check Xcode build log for Swift compilation errors"
echo "   • Look for 'error:' or 'warning:' messages"
echo "   • Verify all Swift files compile without errors"
echo ""

echo "5. 📱 Test Target Issues:"
echo "   • If testing is enabled, ensure test targets build successfully"
echo "   • Check for missing test dependencies"
echo "   • Verify test target configuration"
echo ""

echo "🎯 Next Steps:"
echo "   1. Clean the build folder"
echo "   2. Rebuild the project"
echo "   3. Check for compilation errors"
echo "   4. Verify the swiftmodule file is generated"
echo ""

echo "💡 The missing swiftmodule file indicates incomplete Swift compilation."
echo "   This is typically caused by compilation errors or interrupted builds."
