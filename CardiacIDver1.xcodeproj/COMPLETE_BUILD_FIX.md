# 🔧 COMPLETE WATCH APP BUILD FIX

## IMMEDIATE ACTIONS TO TAKE IN XCODE

### 1. CLEAN BUILD ENVIRONMENT (Critical First Step)

**In Terminal:**
```bash
# Navigate to your project directory first
cd /path/to/your/CardiacIDver1/project

# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/CardiacIDver1*

# Clear build folder
xcodebuild clean -project CardiacIDver1.xcodeproj
```

**In Xcode:**
1. Product → Clean Build Folder (⇧⌘K)
2. Quit Xcode completely
3. Restart Xcode

### 2. FIX TARGET NAMING (Root Cause)

The `lstat` errors are caused by inconsistent naming. Fix this:

**In Xcode Project Navigator:**
1. Click on your **project name** (top level)
2. Select the **Watch App target**
3. In **General tab**:
   - Change **Product Name** from `"CardiacID Watch App"` to `"CardiacID_Watch_App"`
   - Set **Display Name** to `"HeartID"`
4. In **Build Settings** tab:
   - Search for `PRODUCT_NAME`
   - Change all instances to `CardiacID_Watch_App` (no spaces)
   - Search for `PRODUCT_BUNDLE_IDENTIFIER`
   - Ensure it uses underscores: `com.yourcompany.CardiacID_Watch_App`

### 3. DISABLE TEST TARGETS TEMPORARILY

**For CardiacID_Watch_AppTests target:**
1. Select `CardiacID_Watch_AppTests` target
2. In **Build Settings**:
   - Set **"Skip Install"** to **"Yes"**
   - Set **"Enable Testing Search Paths"** to **"No"**
3. In **Build Phases**:
   - Remove all files from "Compile Sources" (just temporarily)

**For CardiacID_Watch_AppUITests target:**
1. Select `CardiacID_Watch_AppUITests` target  
2. In **Build Settings**:
   - Set **"Skip Install"** to **"Yes"**

### 4. VERIFY TARGET MEMBERSHIP

**Check these files are ONLY in Watch App target:**
1. Select each .swift file in your project
2. In **File Inspector** (right panel), ensure only `CardiacID_Watch_App` is checked
3. **Key files to verify:**
   - All View files (EnrollView.swift, etc.)
   - All Service files (HealthKitService.swift, etc.)
   - DataManager.swift
   - All Model files

### 5. FIX DUPLICATE FILES (If Any)

**Check for duplicates:**
1. In Project Navigator, search for "DataManager"
2. You should see only ONE: `CardiacID_Watch_App/Services/DataManager.swift`
3. If you see another `CardiacID_Watch_App/DataManager.swift` (not in Services), delete it

### 6. BUILD MAIN APP ONLY

1. **Select scheme**: Choose `CardiacID_Watch_App` scheme (not tests)
2. **Select destination**: Choose Apple Watch simulator or device
3. **Build**: Press ⌘B

## EXPECTED RESULTS

After these fixes:
✅ No more "lstat" errors
✅ No "Extraneous '}'" errors  
✅ No "Unable to find module dependency" errors
✅ Clean build success
✅ App runs on Apple Watch

## IF STILL HAVING ISSUES

### Emergency Option 1: Rename Everything
If naming issues persist:
1. Create new watchOS App target with clean name
2. Copy all source files to new target
3. Delete old target

### Emergency Option 2: Reset DerivedData Location
1. Xcode → Preferences → Locations
2. Change DerivedData location to a new folder
3. Build again

## VERIFICATION CHECKLIST

Before building, verify:
- [ ] DerivedData cleared
- [ ] Product Name uses underscores
- [ ] Test targets disabled/skip install = Yes  
- [ ] Only one DataManager.swift exists
- [ ] All .swift files have correct target membership
- [ ] Scheme selected is main app, not tests

## BUILD ORDER

1. ✅ Clean environment first
2. ✅ Fix target naming
3. ✅ Disable tests
4. ✅ Verify file membership
5. ✅ Build main app (⌘B)
6. ✅ Test on device/simulator

This should resolve ALL the build errors you're experiencing.