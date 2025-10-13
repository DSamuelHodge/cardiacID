#!/bin/bash

# Manual clean and rebuild script (no sudo required)

echo "🧹 Manual Clean and Rebuild Script"
echo "=================================="
echo ""

# Get the current DerivedData path
DERIVED_DATA_PATH=$(readlink ~/Library/Developer/Xcode/DerivedData 2>/dev/null || echo ~/Library/Developer/Xcode/DerivedData)
PROJECT_DIR="CardiacIDver1-evoexuucehoxphcizvlxugmavvfl"

echo "📁 DerivedData Path: $DERIVED_DATA_PATH"
echo ""

# Step 1: Clean build artifacts
echo "1. 🧹 Cleaning build artifacts..."
if [ -d "$DERIVED_DATA_PATH/$PROJECT_DIR" ]; then
    rm -rf "$DERIVED_DATA_PATH/$PROJECT_DIR"
    echo "   ✅ Removed build directory: $DERIVED_DATA_PATH/$PROJECT_DIR"
else
    echo "   ℹ️  Build directory not found (already clean)"
fi
echo ""

# Step 2: Clean Xcode caches
echo "2. 🧹 Cleaning Xcode caches..."
CACHE_DIRS=(
    "$HOME/Library/Caches/com.apple.dt.Xcode"
    "$HOME/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
    "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
)

for cache_dir in "${CACHE_DIRS[@]}"; do
    if [ -d "$cache_dir" ]; then
        rm -rf "$cache_dir"
        echo "   ✅ Cleaned: $cache_dir"
    else
        echo "   ℹ️  Not found: $cache_dir"
    fi
done
echo ""

# Step 3: Check project files
echo "3. 🔍 Checking project files..."
if [ -f "CardiacIDver1.xcodeproj/project.pbxproj" ]; then
    echo "   ✅ Project file exists"
else
    echo "   ❌ Project file not found"
    exit 1
fi

# Count Swift files
SWIFT_FILES=$(find . -name "*.swift" -type f | wc -l)
echo "   📊 Swift files found: $SWIFT_FILES"
echo ""

# Step 4: Check for common issues
echo "4. 🔍 Checking for common issues..."

# Check for duplicate files
echo "   • Checking for duplicate files..."
DUPLICATES=$(find . -name "* 2.*" -o -name "* copy.*" | wc -l)
if [ "$DUPLICATES" -gt 0 ]; then
    echo "   ⚠️  Found $DUPLICATES potential duplicate files:"
    find . -name "* 2.*" -o -name "* copy.*" | sed 's/^/     /'
    echo "   💡 Consider removing duplicates to avoid conflicts"
else
    echo "   ✅ No duplicate files found"
fi
echo ""

# Check for missing imports
echo "   • Checking for common import issues..."
MISSING_IMPORTS=$(grep -r "import.*XCTest" CardiacID_Watch_App/ 2>/dev/null | wc -l)
if [ "$MISSING_IMPORTS" -gt 0 ]; then
    echo "   ⚠️  Found XCTest imports in main app target:"
    grep -r "import.*XCTest" CardiacID_Watch_App/ | sed 's/^/     /'
    echo "   💡 XCTest should only be imported in test targets"
else
    echo "   ✅ No XCTest imports in main app"
fi
echo ""

# Step 5: Recommendations
echo "5. 🎯 Next Steps:"
echo "   • Open Xcode"
echo "   • Product → Clean Build Folder (Cmd+Shift+K)"
echo "   • Product → Build for Running (Cmd+R)"
echo "   • Check build log for errors"
echo "   • Fix any Swift compilation errors"
echo ""

echo "6. 🔍 What to Look For:"
echo "   • Swift compilation errors in build log"
echo "   • Missing dependencies"
echo "   • Architecture mismatch warnings"
echo "   • Code signing issues"
echo ""

echo "7. ✅ Success Indicators:"
echo "   • Build completes without errors"
echo "   • CardiacID_Watch_App.swiftmodule file is created"
echo "   • CardiacID_Watch_App.swiftdoc file is created"
echo "   • App runs successfully"
echo ""

echo "🎉 Clean and rebuild preparation complete!"
echo "   Now open Xcode and build the project."
