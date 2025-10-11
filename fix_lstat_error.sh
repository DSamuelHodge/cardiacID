#!/bin/bash

# Script to find and fix "CardiacID Watch App" references causing lstat error

echo "🔍 Searching for 'CardiacID Watch App' references in project files..."
echo "==============================================================="

# Navigate to project directory (run this script from your project root)
PROJECT_DIR="."

# Find all references to "CardiacID Watch App" in project configuration files
echo "📁 Checking Xcode project files..."

# Check project.pbxproj file
if [ -f "*.xcodeproj/project.pbxproj" ]; then
    echo "📋 Found references in project.pbxproj:"
    grep -n "CardiacID Watch App" *.xcodeproj/project.pbxproj || echo "   No references found in project.pbxproj"
else
    echo "❌ No project.pbxproj found"
fi

# Check scheme files
echo ""
echo "📋 Checking scheme files..."
find . -name "*.xcscheme" -exec grep -l "CardiacID Watch App" {} \; 2>/dev/null || echo "   No scheme files with references found"

# Check Info.plist files
echo ""
echo "📋 Checking Info.plist files..."
find . -name "Info.plist" -exec grep -l "CardiacID Watch App" {} \; 2>/dev/null || echo "   No Info.plist files with references found"

# Check for xcworkspace files
echo ""
echo "📋 Checking workspace files..."
find . -name "*.xcworkspace" -exec grep -r "CardiacID Watch App" {} \; 2>/dev/null || echo "   No workspace references found"

echo ""
echo "🛠️  AUTOMATED FIX OPTION"
echo "======================="
read -p "Do you want to automatically replace 'CardiacID Watch App' with 'CardiacID_Watch_App' in project files? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Making automated replacements..."
    
    # Backup project file first
    if [ -f "*.xcodeproj/project.pbxproj" ]; then
        cp *.xcodeproj/project.pbxproj *.xcodeproj/project.pbxproj.backup
        echo "✅ Created backup: project.pbxproj.backup"
    fi
    
    # Replace in project.pbxproj
    if [ -f "*.xcodeproj/project.pbxproj" ]; then
        sed -i.bak 's/CardiacID Watch App/CardiacID_Watch_App/g' *.xcodeproj/project.pbxproj
        echo "✅ Updated project.pbxproj"
    fi
    
    # Replace in scheme files
    find . -name "*.xcscheme" -exec sed -i.bak 's/CardiacID Watch App/CardiacID_Watch_App/g' {} \;
    echo "✅ Updated scheme files"
    
    # Replace in Info.plist files
    find . -name "Info.plist" -exec sed -i.bak 's/CardiacID Watch App/CardiacID_Watch_App/g' {} \;
    echo "✅ Updated Info.plist files"
    
    echo ""
    echo "🎯 NEXT STEPS:"
    echo "1. Open your project in Xcode"
    echo "2. Clean Build Folder (⇧⌘K)"
    echo "3. Delete DerivedData folder"
    echo "4. Build project (⌘B)"
    echo ""
    echo "✅ If successful, the lstat error should be resolved!"
else
    echo "❌ No automated changes made."
    echo ""
    echo "🔧 MANUAL FIX REQUIRED:"
    echo "1. Open your Xcode project"
    echo "2. Select Watch App target"
    echo "3. Change target name from 'CardiacID Watch App' to 'CardiacID_Watch_App'"
    echo "4. Change product name to 'CardiacID_Watch_App'"
    echo "5. Clean and rebuild"
fi

echo ""
echo "📋 VERIFICATION:"
echo "After fixing, run this command to verify no references remain:"
echo "grep -r 'CardiacID Watch App' *.xcodeproj/ || echo 'All references fixed!'"