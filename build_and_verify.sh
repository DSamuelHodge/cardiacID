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
