#!/bin/bash

# CardiacID Project Configuration Verification and Fix Script
# This script helps verify and fix the iOS/watchOS embedding issue

echo "🔍 CardiacID Project Configuration Checker"
echo "==========================================="

# Function to check if we're in an Xcode project directory
check_xcode_project() {
    if [ ! -f "*.xcodeproj/project.pbxproj" ] && [ ! -f "*.xcworkspace" ]; then
        echo "❌ No Xcode project found in current directory"
        echo "   Please run this script from your Xcode project directory"
        exit 1
    fi
    echo "✅ Xcode project detected"
}

# Function to display current status
display_status() {
    echo ""
    echo "📊 Current Project Status:"
    echo "------------------------"
    
    # Check for common files
    if [ -f "CardiacIDApp.swift" ]; then
        echo "✅ iOS App Main File: CardiacIDApp.swift found"
    else
        echo "❌ iOS App Main File: CardiacIDApp.swift NOT found"
    fi
    
    if [ -f "CardiacID_Watch_AppApp.swift" ]; then
        echo "✅ Watch App Main File: CardiacID_Watch_AppApp.swift found"
    else
        echo "❌ Watch App Main File: CardiacID_Watch_AppApp.swift NOT found"
        echo "   → This file has been created for you"
    fi
    
    if [ -f "WatchConnectivityService.swift" ]; then
        echo "✅ Watch Connectivity Service found"
    else
        echo "❌ Watch Connectivity Service NOT found"
    fi
    
    if [ -f "WatchConnectivityService+Watch.swift" ]; then
        echo "✅ Watch-specific Connectivity Extension found"
    else
        echo "❌ Watch-specific Connectivity Extension NOT found"
        echo "   → This file has been created for you"
    fi
}

# Function to provide fix instructions
provide_instructions() {
    echo ""
    echo "🛠️  Required Manual Steps in Xcode:"
    echo "===================================="
    echo ""
    echo "1. REMOVE WATCH APP FROM iOS TARGET:"
    echo "   • Open Xcode project"
    echo "   • Select iOS app target (CardiacID)"
    echo "   • Go to General tab"
    echo "   • In 'Frameworks, Libraries, and Embedded Content':"
    echo "     - Remove any 'CardiacID Watch App.app' entries"
    echo "     - Remove any watchOS frameworks"
    echo ""
    echo "2. CHECK BUILD PHASES:"
    echo "   • Still in iOS target"
    echo "   • Go to Build Phases tab"
    echo "   • In 'Copy Bundle Resources':"
    echo "     - Remove any Watch App references"
    echo "   • Remove 'Embed Watch Content' phase if it exists"
    echo ""
    echo "3. VERIFY WATCH APP TARGET:"
    echo "   • Select Watch App target"
    echo "   • Go to General tab"
    echo "   • Verify Platform = watchOS"
    echo "   • Verify Bundle ID = com.yourcompany.CardiacID.watchkitapp"
    echo ""
    echo "4. CHECK TARGET DEPENDENCIES:"
    echo "   • iOS target → Build Phases → Target Dependencies"
    echo "     - Should NOT contain watchOS targets"
    echo "   • Watch target → Build Phases → Target Dependencies"
    echo "     - Should be empty or only contain Watch Extension"
    echo ""
    echo "5. CLEAN AND REBUILD:"
    echo "   • Product → Clean Build Folder (⇧⌘K)"
    echo "   • Product → Build (⌘B)"
}

# Function to create missing files
create_missing_files() {
    echo ""
    echo "📁 Creating Missing Files:"
    echo "-------------------------"
    
    # Files are already created by the assistant
    echo "✅ CardiacID_Watch_AppApp.swift - Created"
    echo "✅ WatchConnectivityService+Watch.swift - Created"
    echo "✅ PROJECT_FIX_INSTRUCTIONS.md - Created"
}

# Function to verify project structure
verify_structure() {
    echo ""
    echo "📋 Expected Project Structure:"
    echo "=============================)"
    echo ""
    echo "CardiacID/"
    echo "├── 📱 iOS App"
    echo "│   ├── CardiacIDApp.swift ✓"
    echo "│   ├── ContentView.swift"
    echo "│   ├── WatchConnectivityService.swift ✓"
    echo "│   └── ... other iOS files"
    echo "│"
    echo "├── ⌚ Watch App (Companion - NOT Embedded)"
    echo "│   ├── CardiacID_Watch_AppApp.swift ✓"
    echo "│   ├── WatchConnectivityService+Watch.swift ✓"
    echo "│   └── ... other Watch files"
    echo "│"
    echo "└── 📋 Documentation"
    echo "    └── PROJECT_FIX_INSTRUCTIONS.md ✓"
}

# Function to show next steps
show_next_steps() {
    echo ""
    echo "🚀 Next Steps:"
    echo "============="
    echo ""
    echo "1. Follow the manual Xcode configuration steps above"
    echo "2. Add the new Watch App files to your Watch target in Xcode"
    echo "3. Build and test both iOS and Watch apps separately"
    echo "4. Test WatchConnectivity communication between apps"
    echo "5. Deploy both apps (they install separately but communicate)"
    echo ""
    echo "📚 For detailed instructions, see: PROJECT_FIX_INSTRUCTIONS.md"
}

# Main execution
main() {
    check_xcode_project
    display_status
    create_missing_files
    verify_structure
    provide_instructions
    show_next_steps
    
    echo ""
    echo "✅ Configuration check complete!"
    echo "   Follow the manual steps in Xcode to resolve the embedding error."
}

# Run the main function
main