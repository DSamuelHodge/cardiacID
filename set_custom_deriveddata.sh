#!/bin/bash

# Script to set custom DerivedData location for Xcode
# This will configure Xcode to use a custom DerivedData folder

echo "🔧 Setting up custom DerivedData location..."

# Create the custom DerivedData directory
CUSTOM_DERIVED_DATA_PATH="$HOME/Desktop/ARGOS - Project HeartID/DerivedData"
mkdir -p "$CUSTOM_DERIVED_DATA_PATH"

echo "📁 Created custom DerivedData directory: $CUSTOM_DERIVED_DATA_PATH"

# Method 1: Set Xcode preferences via defaults command
echo "⚙️  Configuring Xcode preferences..."

# Set the custom DerivedData path
defaults write com.apple.dt.Xcode IDEBuildLocationStyle -string "Custom"
defaults write com.apple.dt.Xcode IDECustomDerivedDataLocation -string "$CUSTOM_DERIVED_DATA_PATH"

echo "✅ Xcode preferences updated"

# Method 2: Create a symbolic link (alternative approach)
echo "🔗 Creating symbolic link as backup method..."
SYMLINK_PATH="$HOME/Library/Developer/Xcode/DerivedData"
if [ -L "$SYMLINK_PATH" ] || [ -d "$SYMLINK_PATH" ]; then
    echo "⚠️  Existing DerivedData found, backing up..."
    mv "$SYMLINK_PATH" "${SYMLINK_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
fi

ln -sf "$CUSTOM_DERIVED_DATA_PATH" "$SYMLINK_PATH"
echo "✅ Symbolic link created: $SYMLINK_PATH -> $CUSTOM_DERIVED_DATA_PATH"

# Method 3: Set environment variable for current session
echo "🌍 Setting environment variable..."
export XCODE_DERIVED_DATA_PATH="$CUSTOM_DERIVED_DATA_PATH"
echo "export XCODE_DERIVED_DATA_PATH=\"$CUSTOM_DERIVED_DATA_PATH\"" >> ~/.zshrc
echo "export XCODE_DERIVED_DATA_PATH=\"$CUSTOM_DERIVED_DATA_PATH\"" >> ~/.bash_profile

echo "✅ Environment variable set"

# Clean up old DerivedData
echo "🧹 Cleaning up old DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/CardiacIDver1-*

echo "🎉 Custom DerivedData setup complete!"
echo ""
echo "📋 Summary:"
echo "   • Custom DerivedData path: $CUSTOM_DERIVED_DATA_PATH"
echo "   • Xcode preferences configured"
echo "   • Symbolic link created"
echo "   • Environment variable set"
echo "   • Old DerivedData cleaned up"
echo ""
echo "🔄 Please restart Xcode for changes to take effect"
echo "💡 You can also restart Xcode from Terminal: killall Xcode && open -a Xcode"
