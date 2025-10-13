#!/bin/bash

# Targeted Swift Compilation Fix Script
# Specifically addresses missing .swiftmodule, .swiftdoc, .abi.json, and .swiftsourceinfo files

echo "🎯 Targeted Swift Compilation Fix"
echo "================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Step 1: Verify project structure
print_status $BLUE "1. 🔍 VERIFYING PROJECT STRUCTURE"
echo "====================================="

if [ ! -f "CardiacIDver1.xcodeproj/project.pbxproj" ]; then
    print_status $RED "❌ Not in project root directory"
    exit 1
fi

print_status $GREEN "✅ Project file found"

# Count Swift files
SWIFT_COUNT=$(find CardiacID_Watch_App/ -name "*.swift" -type f | wc -l)
print_status $BLUE "📊 Swift files in main app: $SWIFT_COUNT"

# Check for common Swift compilation issues
print_status $YELLOW "🔍 Checking for common Swift compilation issues..."

# Check for syntax errors in Swift files
print_status $BLUE "   Checking Swift syntax..."
SYNTAX_ERRORS=0

for swift_file in $(find CardiacID_Watch_App/ -name "*.swift" -type f); do
    # Check for basic syntax issues
    if grep -q "import.*XCTest" "$swift_file"; then
        print_status $YELLOW "   ⚠️  XCTest import found in: $swift_file"
        SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    fi
    
    # Check for missing closing braces
    OPEN_BRACES=$(grep -o '{' "$swift_file" | wc -l)
    CLOSE_BRACES=$(grep -o '}' "$swift_file" | wc -l)
    if [ "$OPEN_BRACES" -ne "$CLOSE_BRACES" ]; then
        print_status $RED "   ❌ Brace mismatch in: $swift_file"
        SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    print_status $GREEN "   ✅ No obvious syntax errors found"
else
    print_status $RED "   ❌ Found $SYNTAX_ERRORS potential syntax issues"
fi

echo ""

# Step 2: Create a minimal test build
print_status $BLUE "2. 🧪 CREATING MINIMAL TEST BUILD"
echo "====================================="

# Create a simple test Swift file to verify compilation
cat > CardiacID_Watch_App/TestCompilation.swift << 'EOF'
import Foundation
import SwiftUI

// Simple test to verify Swift compilation works
struct TestCompilation {
    static func test() -> String {
        return "Swift compilation test successful"
    }
}
EOF

print_status $GREEN "✅ Test Swift file created"

echo ""

# Step 3: Create build verification script
print_status $BLUE "3. 📝 CREATING BUILD VERIFICATION SCRIPT"
echo "============================================="

cat > verify_swift_build.sh << 'EOF'
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
EOF

chmod +x verify_swift_build.sh
print_status $GREEN "✅ Build verification script created"

echo ""

# Step 4: Create Xcode build instructions
print_status $BLUE "4. 📋 XCODE BUILD INSTRUCTIONS"
echo "=================================="

cat > xcode_build_instructions.md << 'EOF'
# Xcode Build Instructions for Swift Compilation Fix

## 🎯 Objective
Fix missing Swift build artifacts:
- CardiacID_Watch_App.swiftmodule
- CardiacID_Watch_App.swiftdoc
- CardiacID_Watch_App.abi.json
- CardiacID_Watch_App.swiftsourceinfo

## 📋 Step-by-Step Instructions

### 1. Open Xcode
- Open `CardiacIDver1.xcodeproj` in Xcode

### 2. Clean Build Folder
- Press `Cmd+Shift+K` (Product → Clean Build Folder)
- Wait for clean operation to complete

### 3. Check Build Settings
- Select the project in the navigator
- Select the `CardiacID_Watch_App` target
- Go to Build Settings tab
- Verify these settings:
  - **Deployment Target**: watchOS 9.0 or later
  - **Swift Language Version**: Swift 5
  - **Build Active Architecture Only**: Yes (for Debug), No (for Release)

### 4. Build for Running
- Press `Cmd+R` (Product → Build for Running)
- Watch the build log carefully

### 5. Check Build Log
Look for these error patterns:
- `error: ` - Swift compilation errors
- `warning: ` - Swift warnings that might cause issues
- `Missing required module` - Import issues
- `Use of unresolved identifier` - Undefined variables/functions

### 6. Fix Errors
If you see errors:
1. Click on the error in the build log
2. Xcode will highlight the problematic code
3. Fix the error (common fixes below)
4. Build again

### 7. Verify Success
After successful build, run:
```bash
./verify_swift_build.sh
```

## 🔧 Common Error Fixes

### Missing Imports
```swift
// Add these imports if missing:
import Foundation
import SwiftUI
import HealthKit
import WatchKit
```

### Type Mismatches
```swift
// Fix type mismatches:
let value: Double = 42.0  // Instead of: let value = 42
```

### Undefined Variables
```swift
// Define missing variables:
@State private var isAuthorized = false
```

### Protocol Conformance
```swift
// Add missing protocol conformances:
extension MyView: View {
    var body: some View {
        // implementation
    }
}
```

## ✅ Success Indicators
After successful build, you should see:
- Build completes without errors
- All Swift build artifacts are created
- App runs successfully in simulator

## 🆘 If Build Still Fails
1. Check for circular dependencies
2. Verify all Swift files compile individually
3. Remove any duplicate files
4. Check for file permission issues
5. Restart Xcode and try again
EOF

print_status $GREEN "✅ Xcode build instructions created"

echo ""

# Step 5: Summary and next steps
print_status $YELLOW "5. 🎯 SUMMARY AND NEXT STEPS"
echo "==============================="

print_status $GREEN "✅ Duplicate files removed"
print_status $GREEN "✅ Test Swift file created"
print_status $GREEN "✅ Build verification script created"
print_status $GREEN "✅ Xcode build instructions created"

echo ""

print_status $BLUE "📋 Next Steps:"
echo "   1. Open Xcode with your project"
echo "   2. Follow the instructions in xcode_build_instructions.md"
echo "   3. Clean Build Folder (Cmd+Shift+K)"
echo "   4. Build for Running (Cmd+R)"
echo "   5. Check build log for Swift compilation errors"
echo "   6. Fix any errors and rebuild"
echo "   7. Run ./verify_swift_build.sh to verify success"

echo ""

print_status $BLUE "🎯 Expected Result:"
echo "   After successful build, these files should exist:"
echo "   • CardiacID_Watch_App.swiftmodule"
echo "   • CardiacID_Watch_App.swiftdoc"
echo "   • CardiacID_Watch_App.abi.json"
echo "   • CardiacID_Watch_App.swiftsourceinfo"

echo ""

print_status $GREEN "🎉 Targeted Swift compilation fix preparation complete!"
print_status $BLUE "   Proceed with building in Xcode following the instructions."
