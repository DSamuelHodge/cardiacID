# 🛠 Watch App Build Fix Guide

## IMMEDIATE ACTIONS REQUIRED

### 1. Fix Duplicate DataManager Files

**Problem**: Multiple DataManager.swift files in project
```
Error: Filename "DataManager.swift" used twice
```

**Solution**:
1. Open Xcode Project Navigator
2. Search for "DataManager.swift" files
3. You should see:
   - `CardiacID_Watch_App/Services/DataManager.swift` ✅ (Keep this one)
   - `CardiacID_Watch_App/DataManager.swift` ❌ (Remove this duplicate)
4. Delete the duplicate file (not in Services folder)
5. Clean Build Folder: Product → Clean Build Folder

### 2. Fix Test Target Configuration

**Problem**: Test target can't find main app module
```
Unable to find module dependency: 'CardiacID_Watch_App'
```

**Solution A - Quick Fix (Disable Tests Temporarily)**:
1. Select your project in Navigator
2. Select "CardiacID_Watch_AppTests" target
3. In Build Settings, set "Skip Install" to "Yes"
4. Or remove test files from target membership temporarily

**Solution B - Proper Fix (Configure Tests)**:
1. Select "CardiacID_Watch_AppTests" target
2. Go to Build Phases → Dependencies
3. Add "CardiacID_Watch_App" as dependency
4. In Build Settings → Swift Compiler, ensure:
   - "Import Paths" includes main app
   - "Enable Testing Search Paths" is "Yes"

### 3. Clean Up Project Structure

**Recommended Actions**:
1. Product → Clean Build Folder
2. Delete DerivedData:
   - Xcode → Preferences → Locations → DerivedData → Arrow → Delete folder
3. Restart Xcode
4. Build again

### 4. Verify Target Membership

**For each Swift file, ensure it's only in correct targets**:
- Main app files → Only in "CardiacID_Watch_App" target
- Test files → Only in "CardiacID_Watch_AppTests" target
- Shared models → Both targets if needed for testing

## EXPECTED OUTCOME

After these fixes:
✅ No duplicate file errors
✅ Clean build for Watch App target
✅ Tests either disabled or properly configured
✅ All core app functionality working

## FILE ORGANIZATION (Correct Structure)

```
CardiacID_Watch_App/
├── Views/
│   ├── EnrollView.swift
│   ├── AuthenticateView.swift
│   ├── MenuView.swift
│   └── SettingsView.swift
├── Services/
│   ├── HealthKitService.swift
│   ├── AuthenticationService.swift
│   ├── DataManager.swift ← KEEP THIS ONE
│   └── EnhancedAuthenticationService.swift
├── Models/
│   ├── BiometricModels.swift
│   ├── HeartPattern.swift
│   └── EnhancedBiometricValidation.swift
└── App/
    ├── HeartIDWatchApp.swift
    └── ContentView.swift

CardiacID_Watch_AppTests/
├── WatchAppTests.swift ← NEW SIMPLIFIED TESTS
└── (Old test files - remove if causing issues)
```

## BUILD ORDER

1. Fix duplicate files first
2. Clean build folder
3. Try building main app target only
4. Once main app builds, then configure tests

This should resolve all build errors and get your Watch app running properly.