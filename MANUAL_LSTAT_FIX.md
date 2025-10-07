# 🎯 MANUAL FIX: lstat Error for "CardiacID Watch App.app"

## 🚨 THE EXACT PROBLEM

Xcode is configured to look for: `CardiacID Watch App.app` (with spaces)
But should be looking for: `CardiacID_Watch_App.app` (with underscores)

## 🛠️ STEP-BY-STEP MANUAL FIX

### Step 1: Open Xcode Project Settings
1. **Open your CardiacID project in Xcode**
2. **Click on the project name** at the top of the navigator (blue icon)
3. **You'll see your targets listed** in the main area

### Step 2: Locate the Watch App Target
1. **Look for a target named:** `CardiacID Watch App` (with spaces)
2. **This is the problematic target**

### Step 3: Rename the Target
1. **Select the Watch App target**
2. **In the "Identity and Type" section on the right:**
   - **Name**: Change from `CardiacID Watch App` to `CardiacID_Watch_App`
   - **Product Name**: Change to `CardiacID_Watch_App`
   - **Display Name**: Set to `HeartID` (for user-facing name)

### Step 4: Update Build Settings
1. **Still in the Watch App target**
2. **Click "Build Settings" tab**
3. **Search for "PRODUCT_NAME"**
4. **Set all entries to:** `CardiacID_Watch_App`

### Step 5: Fix Scheme
1. **Product → Scheme → Manage Schemes**
2. **Look for scheme named:** `CardiacID Watch App`
3. **Either:**
   - **Rename it to:** `CardiacID_Watch_App`
   - **Or delete it** (Xcode will recreate automatically)

### Step 6: Clean Everything
1. **Product → Clean Build Folder** (⇧⌘K)
2. **Xcode → Settings → Locations → Derived Data**
3. **Click arrow → Move entire DerivedData folder to Trash**
4. **Quit and restart Xcode**

### Step 7: Test Build
1. **Select iOS Simulator**
2. **Product → Build** (⌘B)
3. **Should build successfully without lstat error**

## 🔍 ALTERNATIVE: Check Project File Directly

If the above doesn't work, you can edit the project file directly:

### Option A: Text Editor Approach
1. **Quit Xcode completely**
2. **Right-click on** `CardiacID.xcodeproj` → **Show Package Contents**
3. **Open** `project.pbxproj` **in a text editor**
4. **Find all instances of:** `"CardiacID Watch App"`
5. **Replace with:** `"CardiacID_Watch_App"`
6. **Save the file**
7. **Reopen in Xcode**

### Option B: Terminal Command
```bash
cd /path/to/your/project
# Backup first
cp CardiacID.xcodeproj/project.pbxproj CardiacID.xcodeproj/project.pbxproj.backup
# Replace references
sed -i '' 's/CardiacID Watch App/CardiacID_Watch_App/g' CardiacID.xcodeproj/project.pbxproj
```

## ✅ VERIFICATION

After the fix, this command should return no results:
```bash
grep -r "CardiacID Watch App" CardiacID.xcodeproj/
```

And the build should succeed without the lstat error.

## 🎯 EXPECTED SUCCESS

After fixing:
- ✅ Build creates: `CardiacID_Watch_App.app`
- ✅ No more lstat errors
- ✅ iOS Simulator works correctly
- ✅ Watch Simulator works correctly

The key is ensuring **all references** in your Xcode project configuration use underscores instead of spaces.