# CardiacID Watch App Naming Fix - Wholistic Solution

## 🎯 Problem Identified
The error shows Xcode is looking for:
```
CardiacID Watch App.app (with spaces)
```
But your project files use:
```
CardiacID_Watch_App (with underscores)
```

## ✅ Solution: Standardize on Underscores (Easiest Method)

### Step 1: Update Xcode Target Names
1. Open Xcode project
2. Select your project in the navigator
3. Select the **Watch App target**
4. In the "Identity and Type" section, change:
   - **Display Name**: `HeartID`
   - **Bundle Name**: `CardiacID_Watch_App`
   - **Product Name**: `CardiacID_Watch_App`

### Step 2: Update Info.plist (if exists)
If you have a Watch App Info.plist:
1. Find `CFBundleDisplayName`
2. Change value to: `HeartID`
3. Find `CFBundleName` 
4. Change value to: `CardiacID_Watch_App`

### Step 3: Update Scheme Names
1. Go to **Product → Scheme → Manage Schemes**
2. Find any schemes with "CardiacID Watch App" (with spaces)
3. Rename them to: `CardiacID_Watch_App`

### Step 4: Update Bundle Identifiers
1. Watch App target → General tab
2. Ensure Bundle Identifier uses underscores:
   ```
   com.yourcompany.CardiacID_Watch_App
   ```

### Step 5: Verify Build Settings
1. Watch App target → Build Settings
2. Search for "Product Name"
3. Ensure all entries use: `CardiacID_Watch_App`

### Step 6: Clean and Rebuild
1. **Product → Clean Build Folder** (⇧⌘K)
2. **Delete DerivedData**:
   - Xcode → Settings → Locations → Derived Data → Arrow → Move to Trash
3. **Product → Build** (⌘B)

## 📁 Current File Structure (Correct - Keep As Is)
```
✅ CardiacID_Watch_AppTests.swift
✅ CardiacID_Watch_AppUITests.swift  
✅ CardiacID_Watch_AppUITestsLaunchTests.swift
✅ HeartID_Watch_App_Process_Flow.md
```

## 🎯 Expected Result After Fix
Xcode will build:
```
CardiacID_Watch_App.app (with underscores)
```
Instead of looking for:
```
CardiacID Watch App.app (with spaces)
```

## 🔍 Verification Steps
1. Build should complete without the `lstat` error
2. Simulator should show `CardiacID_Watch_App` 
3. Archive should work properly
4. Watch Connectivity should continue working

## ⚠️ Alternative Method (If Above Doesn't Work)
If standardizing on underscores doesn't work, you can go the other direction:

### Rename Files to Use Spaces:
1. In Xcode, rename test files:
   - `CardiacID_Watch_AppTests.swift` → `CardiacID Watch AppTests.swift`
   - `CardiacID_Watch_AppUITests.swift` → `CardiacID Watch AppUITests.swift`
   - etc.
2. Update any import statements or references

**But underscores are preferred** as they're more filesystem-friendly.

## 🎯 Why This Fix Works
- **Consistent naming** eliminates build system confusion
- **Underscores** are filesystem-safe across all platforms
- **Minimal changes** preserve your existing architecture
- **Build system alignment** matches file structure to target names

This is a **configuration fix**, not an architecture change. Your excellent project structure remains intact.