# 🔍 FINDING AND FIXING "CardiacID Watch App" REFERENCES

## 🎯 WHERE THE ERROR COMES FROM

The error `lstat(.../CardiacID Watch App.app)` means Xcode is configured to look for a file with spaces in the name. This reference is in your **Xcode project configuration**, not in your source code files.

## 📁 EXACT LOCATIONS TO CHECK AND FIX

### 1. **Xcode Project File (project.pbxproj)**
**Location**: `CardiacID.xcodeproj/project.pbxproj`

Search for and replace these entries:
```
Find: "CardiacID Watch App"
Replace with: "CardiacID_Watch_App"
```

**Specific entries to look for:**
- `PRODUCT_NAME = "CardiacID Watch App"`
- `name = "CardiacID Watch App"`
- `productName = "CardiacID Watch App"`
- Any target references with spaces

### 2. **Scheme Files**
**Location**: `CardiacID.xcodeproj/xcuserdata/[username]/xcschemes/`

Look for files like:
- `CardiacID Watch App.xcscheme`

**Action**: Rename file to `CardiacID_Watch_App.xcscheme`

### 3. **Info.plist Files**
Check for any Watch App Info.plist with:
```xml
<key>CFBundleName</key>
<string>CardiacID Watch App</string>
```

**Change to:**
```xml
<key>CFBundleName</key>
<string>CardiacID_Watch_App</string>
<key>CFBundleDisplayName</key>
<string>HeartID</string>
```

## 🛠️ EASIEST FIX METHOD

### Option A: Use Xcode Interface (Recommended)
1. **Open Xcode project**
2. **Select project in navigator**
3. **Select Watch App target**
4. **In "Identity" section:**
   - Change **Name** to: `CardiacID_Watch_App`
   - Change **Product Name** to: `CardiacID_Watch_App`
5. **In General tab:**
   - Change **Display Name** to: `HeartID`
6. **Build Settings tab:**
   - Search for "PRODUCT_NAME"
   - Change all instances to: `CardiacID_Watch_App`

### Option B: Direct File Edit
If you can access the project file directly:

1. **Right-click** on `CardiacID.xcodeproj` → **Show Package Contents**
2. **Open** `project.pbxproj` in text editor
3. **Find and replace ALL instances:**
   - `"CardiacID Watch App"` → `"CardiacID_Watch_App"`
4. **Save file**
5. **Reopen project in Xcode**

## 🔄 VERIFICATION COMMANDS

After making changes, verify with these Terminal commands:

```bash
cd /path/to/your/project
grep -r "CardiacID Watch App" *.xcodeproj/
```

Should return **no results** after fixing.

## 🎯 EXACT ERROR SOURCE

The `lstat` error occurs because:
1. **Xcode build system** tries to create: `CardiacID Watch App.app`
2. **Your file structure** expects: `CardiacID_Watch_App.app`
3. **Mismatch** causes the "No such file or directory" error

## ✅ AFTER THE FIX

Build output should show:
```
✅ Creating: CardiacID_Watch_App.app
✅ iOS Simulator works correctly
✅ No more lstat errors
```

## 🚨 CRITICAL FILES TO CHECK

The reference is definitely in one of these:
1. `CardiacID.xcodeproj/project.pbxproj` (most likely)
2. Scheme files in `xcuserdata/`
3. Any Watch App Info.plist
4. Build configuration files

**The fix is changing the target name in your Xcode project settings from spaces to underscores.**