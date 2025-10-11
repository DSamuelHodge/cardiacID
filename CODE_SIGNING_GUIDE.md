# 🔐 Code Signing Configuration Guide

## Issue Analysis
The error "Embedded binary is not signed with the same certificate as the parent app" occurs when the Watch App and iOS App have different code signing settings.

## Solution Steps

### 1. **Open Xcode Project Settings**
- Open `CardiacIDver1.xcodeproj` in Xcode
- Select the project root in the navigator
- Go to the "Signing & Capabilities" tab

### 2. **Configure iOS App Target**
- Select `CardiacID` target
- Ensure "Automatically manage signing" is checked
- Set the correct Team
- Verify Bundle Identifier: `com.yourcompany.CardiacID`

### 3. **Configure Watch App Target**
- Select `CardiacID_Watch_App` target
- Ensure "Automatically manage signing" is checked
- Set the **SAME** Team as the iOS app
- Verify Bundle Identifier: `com.yourcompany.CardiacID.watchkitapp`

### 4. **Configure Watch Extension Target**
- Select `CardiacID_Watch_App` extension target
- Ensure "Automatically manage signing" is checked
- Set the **SAME** Team as the iOS app
- Verify Bundle Identifier: `com.yourcompany.CardiacID.watchkitapp.watchkitextension`

### 5. **Verify Provisioning Profiles**
- All targets should use the same Development Team
- Provisioning profiles should be automatically managed
- If using manual signing, ensure all profiles are from the same team

## Alternative Solution (If Above Doesn't Work)

### Manual Configuration:
1. **Disable Automatic Signing** for all targets
2. **Create matching provisioning profiles** for:
   - iOS App
   - Watch App
   - Watch Extension
3. **Assign the same certificate** to all targets
4. **Ensure Bundle IDs match** the provisioning profiles

## Verification Steps
1. Clean Build Folder (Cmd+Shift+K)
2. Build the project
3. Verify no code signing errors
4. Test on device/simulator

## Common Issues & Solutions

### Issue: "No matching provisioning profile found"
**Solution**: Ensure Bundle IDs match exactly between project and provisioning profile

### Issue: "Certificate not found"
**Solution**: Download the correct certificate from Apple Developer portal

### Issue: "Team ID mismatch"
**Solution**: Ensure all targets use the same Development Team

## Code Integrity Impact
- ✅ **No code changes required**
- ✅ **No functionality affected**
- ✅ **Pure build configuration issue**
- ✅ **Testing framework remains intact**

This is a build configuration issue that does not affect the code integrity or functionality of the HeartID Watch App.
