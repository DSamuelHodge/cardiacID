# CardiacID Project Configuration Fix

## Current Issue
Error: "Your target is built for iOS but contains embedded content built for the watchOS platform (CardiacID Watch App.app), which is not allowed."

## Root Cause
The iOS app target is incorrectly configured to embed the watchOS app as content, rather than treating it as a companion app.

## Fix Instructions

### Step 1: Remove Incorrect Watch App Embedding

1. **Open Xcode project**
2. **Select your project** in the navigator (top-level CardiacID)
3. **Select the iOS app target** (CardiacID)
4. **Go to General tab**
5. **In "Frameworks, Libraries, and Embedded Content" section:**
   - Look for any entry like "CardiacID Watch App.app" or "CardiacID_Watch_App.app"
   - If found, select it and click the "-" button to remove it
   - If you see any watchOS frameworks or content, remove them

### Step 2: Check Build Phases

1. **Still in iOS app target**
2. **Go to Build Phases tab**
3. **Check "Copy Bundle Resources" phase:**
   - Remove any Watch App references
   - Remove any .watchkitapp or .watchkitextension references
4. **Check for "Embed Watch Content" phase:**
   - This should NOT exist for iOS targets
   - If it exists, remove it entirely

### Step 3: Verify Watch App Target Configuration

1. **Select Watch App target** (Should be named CardiacID_Watch_App)
2. **Go to General tab**
3. **Verify settings:**
   - Platform: watchOS
   - Deployment Target: watchOS 9.0+ (or your minimum)
   - Bundle Identifier: com.yourcompany.CardiacID.watchkitapp (should be different from iOS)

### Step 4: Check Target Dependencies

1. **Select iOS app target**
2. **Go to Build Phases → Target Dependencies**
3. **Verify NO watchOS targets are listed here**
4. **Select Watch App target**
5. **Go to Build Phases → Target Dependencies**
6. **This SHOULD be empty or only contain Watch Extension if separate**

### Step 5: Verify Scheme Configuration

1. **Product → Scheme → Edit Scheme**
2. **Select your iOS scheme**
3. **Build section:** Only iOS targets should be checked
4. **Run section:** Only iOS app should be selected
5. **Create separate Watch App scheme if needed:**
   - Product → Scheme → New Scheme
   - Choose Watch App target
   - This allows separate testing of watch functionality

### Step 6: Clean and Rebuild

1. **Product → Clean Build Folder** (⇧⌘K)
2. **Delete DerivedData** (optional but recommended):
   - Xcode → Settings → Locations → Derived Data → Arrow button → Move to Trash
3. **Product → Build** (⌘B)

## Expected Project Structure

```
CardiacID (iOS App)
├── CardiacIDApp.swift ✓ (Found)
├── ContentView.swift ✓ (Found)
├── WatchConnectivityService.swift ✓ (Found)
└── ... other iOS files

CardiacID Watch App (watchOS App - Companion)
├── Watch App main file
├── Watch App Views
└── Watch Connectivity implementation
```

## Verification Steps

After applying fixes:

1. **Build iOS app** - Should succeed without embedding errors
2. **Install iOS app** on device
3. **Install Watch app** separately on paired Apple Watch
4. **Test WatchConnectivity** - Both apps should communicate properly
5. **Check app sizes** - iOS app should not include watchOS content

## Notes

- Your WatchConnectivityService.swift is properly implemented ✓
- iOS and watchOS apps should be separate but can communicate
- Watch app installs automatically when iOS app is installed from App Store
- For development, install both apps separately

## If Issues Persist

1. Create new iOS target and migrate code
2. Create new watchOS target and implement watch functionality
3. Ensure proper bundle identifiers (iOS: com.company.app, watchOS: com.company.app.watchkitapp)