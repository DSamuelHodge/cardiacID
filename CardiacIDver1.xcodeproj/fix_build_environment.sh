#!/bin/bash

# 🔧 Watch App Build Fix Script
# Run this script to clean your build environment

echo "🔧 Starting Watch App Build Fix..."

# 1. Clear DerivedData
echo "📁 Clearing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/CardiacIDver1*
echo "✅ DerivedData cleared"

# 2. Clear Xcode build caches
echo "🗑 Clearing Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode
echo "✅ Xcode caches cleared"

# 3. Clear simulator data (optional)
echo "📱 Resetting simulator data..."
xcrun simctl shutdown all
xcrun simctl erase all
echo "✅ Simulator data reset"

echo ""
echo "🎯 NEXT STEPS:"
echo "1. Open Xcode"
echo "2. Fix target naming (CardiacID Watch App → CardiacID_Watch_App)"
echo "3. Disable test targets (Skip Install = Yes)"
echo "4. Clean Build Folder (⇧⌘K)"
echo "5. Build main app (⌘B)"
echo ""
echo "✅ Environment cleanup complete!"