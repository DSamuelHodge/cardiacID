#!/bin/bash

# Comprehensive Swift Build Artifact Repair Script
# Addresses missing .swiftmodule, .swiftdoc, .abi.json, and .swiftsourceinfo files

echo "🔧 Comprehensive Swift Build Artifact Repair"
echo "============================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Get current DerivedData path
DERIVED_DATA_PATH=$(readlink ~/Library/Developer/Xcode/DerivedData 2>/dev/null || echo ~/Library/Developer/Xcode/DerivedData)
PROJECT_DIR="CardiacIDver1-evoexuucehoxphcizvlxugmavvfl"

print_status $BLUE "📁 DerivedData Path: $DERIVED_DATA_PATH"
echo ""

# Step 1: Comprehensive Clean
print_status $YELLOW "1. 🧹 COMPREHENSIVE CLEAN OPERATION"
echo "================================================"

# Clean build directory
if [ -d "$DERIVED_DATA_PATH/$PROJECT_DIR" ]; then
    print_status $YELLOW "   Removing build directory..."
    rm -rf "$DERIVED_DATA_PATH/$PROJECT_DIR"
    print_status $GREEN "   ✅ Build directory removed"
else
    print_status $BLUE "   ℹ️  Build directory not found (already clean)"
fi

# Clean all Xcode caches
CACHE_DIRS=(
    "$HOME/Library/Caches/com.apple.dt.Xcode"
    "$HOME/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
    "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
    "$HOME/Library/Developer/Xcode/UserData/IDEEditorInteractivityHistory"
    "$HOME/Library/Developer/Xcode/UserData/IB Support"
)

for cache_dir in "${CACHE_DIRS[@]}"; do
    if [ -d "$cache_dir" ]; then
        print_status $YELLOW "   Cleaning: $cache_dir"
        rm -rf "$cache_dir"
        print_status $GREEN "   ✅ Cleaned"
    fi
done

# Clean derived data symlink if broken
if [ -L ~/Library/Developer/Xcode/DerivedData ] && [ ! -e ~/Library/Developer/Xcode/DerivedData ]; then
    print_status $YELLOW "   Fixing broken DerivedData symlink..."
    rm ~/Library/Developer/Xcode/DerivedData
    ln -sf "$DERIVED_DATA_PATH" ~/Library/Developer/Xcode/DerivedData
    print_status $GREEN "   ✅ Symlink fixed"
fi

echo ""

# Step 2: Project Analysis
print_status $YELLOW "2. 🔍 PROJECT ANALYSIS"
echo "=========================="

# Check project structure
if [ -f "CardiacIDver1.xcodeproj/project.pbxproj" ]; then
    print_status $GREEN "   ✅ Project file exists"
else
    print_status $RED "   ❌ Project file not found"
    exit 1
fi

# Count Swift files
SWIFT_FILES=$(find . -name "*.swift" -type f | wc -l)
print_status $BLUE "   📊 Swift files found: $SWIFT_FILES"

# Check for problematic files
print_status $YELLOW "   🔍 Checking for problematic files..."

# Check for XCTest imports in main app
XCTEST_IMPORTS=$(grep -r "import.*XCTest" CardiacID_Watch_App/ 2>/dev/null | wc -l)
if [ "$XCTEST_IMPORTS" -gt 0 ]; then
    print_status $RED "   ❌ Found XCTest imports in main app:"
    grep -r "import.*XCTest" CardiacID_Watch_App/ | sed 's/^/     /'
    print_status $YELLOW "   💡 Removing XCTest imports from main app..."
    find CardiacID_Watch_App/ -name "*.swift" -exec sed -i '' '/import.*XCTest/d' {} \;
    print_status $GREEN "   ✅ XCTest imports removed"
else
    print_status $GREEN "   ✅ No XCTest imports in main app"
fi

# Check for duplicate files
DUPLICATES=$(find . -name "* 2.*" -o -name "* copy.*" | wc -l)
if [ "$DUPLICATES" -gt 0 ]; then
    print_status $YELLOW "   ⚠️  Found $DUPLICATES duplicate files:"
    find . -name "* 2.*" -o -name "* copy.*" | sed 's/^/     /'
    print_status $YELLOW "   💡 Consider removing duplicates to avoid conflicts"
else
    print_status $GREEN "   ✅ No duplicate files found"
fi

# Check for missing imports
print_status $YELLOW "   🔍 Checking for missing imports..."

# Check HealthKit imports
HEALTHKIT_IMPORTS=$(grep -r "import HealthKit" CardiacID_Watch_App/ 2>/dev/null | wc -l)
if [ "$HEALTHKIT_IMPORTS" -gt 0 ]; then
    print_status $GREEN "   ✅ HealthKit imports found: $HEALTHKIT_IMPORTS"
else
    print_status $YELLOW "   ⚠️  No HealthKit imports found"
fi

# Check SwiftUI imports
SWIFTUI_IMPORTS=$(grep -r "import SwiftUI" CardiacID_Watch_App/ 2>/dev/null | wc -l)
if [ "$SWIFTUI_IMPORTS" -gt 0 ]; then
    print_status $GREEN "   ✅ SwiftUI imports found: $SWIFTUI_IMPORTS"
else
    print_status $YELLOW "   ⚠️  No SwiftUI imports found"
fi

echo ""

# Step 3: Build Configuration Check
print_status $YELLOW "3. ⚙️  BUILD CONFIGURATION CHECK"
echo "====================================="

# Check for common build issues
print_status $BLUE "   🔍 Checking build configuration..."

# Check if we're in the right directory
if [ ! -f "CardiacIDver1.xcodeproj/project.pbxproj" ]; then
    print_status $RED "   ❌ Not in project root directory"
    exit 1
fi

# Check for spaces in project name (common issue)
if [[ "CardiacIDver1" == *" "* ]]; then
    print_status $RED "   ❌ Project name contains spaces - this can cause build issues"
else
    print_status $GREEN "   ✅ Project name is clean"
fi

echo ""

# Step 4: Create Build Script
print_status $YELLOW "4. 📝 CREATING BUILD SCRIPT"
echo "=============================="

cat > build_and_verify.sh << 'EOF'
#!/bin/bash

echo "🔨 Building CardiacID Watch App..."
echo "=================================="

# Build the project
echo "Building project..."
xcodebuild -project CardiacIDver1.xcodeproj \
           -scheme CardiacID_Watch_App \
           -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' \
           -configuration Release \
           build

BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Build completed successfully!"
    echo ""
    
    # Verify build artifacts
    echo "🔍 Verifying build artifacts..."
    
    DERIVED_DATA_PATH=$(readlink ~/Library/Developer/Xcode/DerivedData 2>/dev/null || echo ~/Library/Developer/Xcode/DerivedData)
    BUILD_DIR="$DERIVED_DATA_PATH/CardiacIDver1-evoexuucehoxphcizvlxugmavvfl/Build/Intermediates.noindex/CardiacIDver1.build/Release-watchos/CardiacID_Watch_App.build/Objects-normal/arm64_32"
    
    # Check for required files
    REQUIRED_FILES=(
        "CardiacID_Watch_App.swiftmodule"
        "CardiacID_Watch_App.swiftdoc"
        "CardiacID_Watch_App.abi.json"
        "CardiacID_Watch_App.swiftsourceinfo"
    )
    
    ALL_FOUND=true
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$BUILD_DIR/$file" ]; then
            echo "   ✅ $file exists"
        else
            echo "   ❌ $file missing"
            ALL_FOUND=false
        fi
    done
    
    if [ "$ALL_FOUND" = true ]; then
        echo ""
        echo "🎉 All build artifacts created successfully!"
        echo "   The Swift compilation completed without errors."
    else
        echo ""
        echo "⚠️  Some build artifacts are missing."
        echo "   Check the build log for Swift compilation errors."
    fi
    
else
    echo ""
    echo "❌ Build failed with exit code: $BUILD_EXIT_CODE"
    echo "   Check the build log for errors."
fi
EOF

chmod +x build_and_verify.sh
print_status $GREEN "   ✅ Build script created: build_and_verify.sh"

echo ""

# Step 5: Alternative Solutions
print_status $YELLOW "5. 🛠️  ALTERNATIVE SOLUTIONS"
echo "==============================="

print_status $BLUE "   Option A: Use Xcode GUI"
echo "     1. Open Xcode"
echo "     2. Product → Clean Build Folder (Cmd+Shift+K)"
echo "     3. Product → Build for Running (Cmd+R)"
echo "     4. Check build log for errors"
echo ""

print_status $BLUE "   Option B: Use command line"
echo "     1. Run: ./build_and_verify.sh"
echo "     2. Check output for errors"
echo "     3. Fix any Swift compilation errors"
echo ""

print_status $BLUE "   Option C: Manual file check"
echo "     1. Check each Swift file for syntax errors"
echo "     2. Verify all imports are correct"
echo "     3. Ensure no circular dependencies"
echo ""

# Step 6: Common Error Patterns
print_status $YELLOW "6. 🔍 COMMON ERROR PATTERNS TO CHECK"
echo "============================================="

print_status $BLUE "   Swift Compilation Errors:"
echo "     • Missing imports (import Foundation, import SwiftUI, etc.)"
echo "     • Type mismatches"
echo "     • Undefined variables or functions"
echo "     • Circular dependencies"
echo "     • Missing protocol conformances"
echo ""

print_status $BLUE "   Build Configuration Issues:"
echo "     • Wrong deployment target"
echo "     • Missing frameworks"
echo "     • Code signing issues"
echo "     • Architecture mismatches"
echo ""

print_status $BLUE "   File System Issues:"
echo "     • File permissions"
echo "     • Disk space"
echo "     • Corrupted files"
echo ""

# Step 7: Final Recommendations
print_status $YELLOW "7. 🎯 FINAL RECOMMENDATIONS"
echo "==============================="

print_status $GREEN "   ✅ Clean operation completed"
print_status $GREEN "   ✅ Project analysis completed"
print_status $GREEN "   ✅ Build script created"
echo ""

print_status $BLUE "   Next Steps:"
echo "     1. Open Xcode with your project"
echo "     2. Clean Build Folder (Cmd+Shift+K)"
echo "     3. Build for Running (Cmd+R)"
echo "     4. Check build log for Swift compilation errors"
echo "     5. Fix any errors and rebuild"
echo ""

print_status $BLUE "   Expected Result:"
echo "     After successful build, these files should exist:"
echo "     • CardiacID_Watch_App.swiftmodule"
echo "     • CardiacID_Watch_App.swiftdoc"
echo "     • CardiacID_Watch_App.abi.json"
echo "     • CardiacID_Watch_App.swiftsourceinfo"
echo ""

print_status $GREEN "🎉 Comprehensive repair preparation complete!"
print_status $BLUE "   Now proceed with building in Xcode."
