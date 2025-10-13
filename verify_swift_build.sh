#!/bin/bash

echo "🔨 Swift Build Verification"
echo "==========================="

# Get DerivedData path
DERIVED_DATA_PATH=$(readlink ~/Library/Developer/Xcode/DerivedData 2>/dev/null || echo ~/Library/Developer/Xcode/DerivedData)
PROJECT_DIR="CardiacIDver1-evoexuucehoxphcizvlxugmavvfl"
BUILD_DIR="$DERIVED_DATA_PATH/$PROJECT_DIR/Build/Intermediates.noindex/CardiacIDver1.build/Release-watchos/CardiacID_Watch_App.build/Objects-normal/arm64_32"

echo "📁 Build directory: $BUILD_DIR"
echo ""

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Build directory does not exist"
    echo "   Run a build in Xcode first"
    exit 1
fi

echo "✅ Build directory exists"
echo ""

# Check for required Swift build artifacts
REQUIRED_FILES=(
    "CardiacID_Watch_App.swiftmodule"
    "CardiacID_Watch_App.swiftdoc" 
    "CardiacID_Watch_App.abi.json"
    "CardiacID_Watch_App.swiftsourceinfo"
)

echo "🔍 Checking for required Swift build artifacts:"
echo ""

ALL_FOUND=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$BUILD_DIR/$file" ]; then
        echo "   ✅ $file exists ($(stat -f%z "$BUILD_DIR/$file") bytes)"
    else
        echo "   ❌ $file missing"
        ALL_FOUND=false
    fi
done

echo ""

if [ "$ALL_FOUND" = true ]; then
    echo "🎉 All Swift build artifacts found!"
    echo "   Swift compilation completed successfully."
    
    # Show file details
    echo ""
    echo "📋 File Details:"
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$BUILD_DIR/$file" ]; then
            echo "   $file: $(stat -f%z "$BUILD_DIR/$file") bytes, modified $(stat -f%Sm "$BUILD_DIR/$file")"
        fi
    done
else
    echo "⚠️  Some Swift build artifacts are missing."
    echo "   This indicates incomplete Swift compilation."
    echo ""
    echo "🛠️  Troubleshooting steps:"
    echo "   1. Check Xcode build log for Swift compilation errors"
    echo "   2. Look for 'error:' messages in the build output"
    echo "   3. Fix any Swift syntax or import errors"
    echo "   4. Clean build folder and rebuild"
    echo ""
    echo "💡 Common issues:"
    echo "   • Missing imports (Foundation, SwiftUI, HealthKit)"
    echo "   • Type mismatches"
    echo "   • Undefined variables or functions"
    echo "   • Circular dependencies"
fi
