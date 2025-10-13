//
//  🗑️ CLEANUP_GUIDE.md
//  HeartID Watch App
//
//  Files marked with "X" prefix are SAFE TO DELETE
//

# 🧹 HeartID Watch App Cleanup Guide

## Files Marked for Deletion (X Prefix)

### **❌ Disabled App Entry Points - SAFE TO DELETE**

| File | Status | Action | Reason |
|------|--------|--------|---------|
| `X_HeartIDApp.swift` | 🗑️ DELETE | Remove file | Conflicting @main entry point |
| `X_HeartIDiOSApp.swift` | 🗑️ DELETE | Remove file | iOS code in Watch target |
| `X_MinimalWatchApp.swift` | 🗑️ DELETE | Remove file | Fallback no longer needed |
| `X_BasicHealthKitService.swift` | 🗑️ DELETE | Remove file | Deprecated, use HealthKitService.swift |

### **✅ Active Files - KEEP THESE**

| File | Status | Action | Purpose |
|------|--------|--------|---------|
| `HeartIDWatchApp.swift` | ✅ ACTIVE | Keep | Main @main entry point |
| `SettingsView.swift` | ✅ ACTIVE | Keep | Primary settings interface |
| `HealthKitService.swift` | ✅ ACTIVE | Keep | Main health service |
| `DataManager.swift` | ✅ ACTIVE | Keep | Core data management |

## 🔍 How to Identify Files for Deletion

**Files marked with "X" prefix have:**
- ❌ Symbol at the beginning of comments
- 🗑️ "SAFE TO DELETE" labels
- Wrapped in `#if false` or comment blocks
- Explicit disable warnings

**Example markers to look for:**
```swift
//  X_FileName.swift
//  ❌ DISABLED - Description
//  🗑️ SAFE TO DELETE - Reason
```

## 📝 Deletion Steps

1. **Before Deleting**: Make sure your project builds successfully
2. **Delete Order**: Delete X-prefixed files one at a time
3. **Test Build**: After each deletion, verify build still works
4. **Final Clean**: Clean build folder after all deletions

## 🎯 Benefits of Cleanup

**After deleting X-prefixed files:**
- ✅ No more "Invalid redeclaration" errors
- ✅ Faster compile times
- ✅ Cleaner project structure
- ✅ Reduced confusion for developers
- ✅ Smaller project size

## ⚠️ Important Notes

- **X-prefixed files are completely disabled** and don't affect builds
- **Deletion is optional** but recommended for cleanliness
- **Keep all files without X prefix** - they are active
- **Take backup before mass deletion** if unsure

## 🔧 Alternative: Hide Instead of Delete

If you prefer to keep disabled files for reference:
1. Create a folder called "Disabled"
2. Move X-prefixed files there
3. Remove them from build targets

This keeps them accessible but out of the way.

---

**Total files safe to delete: 4**
**Expected cleanup benefit: Eliminates all redeclaration conflicts**