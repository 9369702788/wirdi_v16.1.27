# 🔧 TROUBLESHOOTING GUIDE

## Common Issues & Solutions

### Issue 1: "File not found" errors

**Problem:** Some files are not copied correctly

**Solution:**
1. Check FILE_MAPPING.txt for correct locations
2. Ensure all 23 files are copied
3. Verify file names match exactly
4. Run: flutter clean

### Issue 2: "Undefined class" or "Import not found"

**Problem:** Files are in wrong location or provider not imported

**Solution:**
1. Check if all providers are in lib/providers/
2. Check if all models are in lib/models/
3. Check if all services are in lib/services/
4. Update import statements if needed

### Issue 3: "pubspec.yaml has errors"

**Problem:** Dependencies are missing or invalid

**Solution:**
1. Use WIRDI_v3.0.0_PUBSPEC_COMPLETE.yaml
2. Run: flutter pub get
3. Run: flutter clean
4. Run: flutter pub get again

### Issue 4: "Build fails with error"

**Problem:** Compilation error in the code

**Solution:**
1. Check that you copied the COMPLETE files from personal_files
2. Not the placeholder files from the ZIP
3. Ensure all 23 files are the actual implementation files
4. Run: flutter clean
5. Run: flutter pub get

### Issue 5: "App crashes on startup"

**Problem:** Missing initialization or configuration

**Solution:**
1. Check main.dart is updated
2. Check all providers are initialized
3. Check Firebase configuration is set
4. Check pubspec.yaml has all dependencies

### Issue 6: "Screens not showing"

**Problem:** Screen files not imported in main.dart

**Solution:**
1. Check main.dart imports all screens
2. Check navigation is configured
3. Check bottom navigation includes new screens
4. Verify screen file names match imports

## ✅ Verification Checklist

After installation, verify:
- ✅ All 23 files copied
- ✅ File locations are correct
- ✅ No compilation errors
- ✅ App starts without crashes
- ✅ All screens load
- ✅ All features work
- ✅ Navigation works
- ✅ Providers initialized

## 📞 Still Having Issues?

1. Double-check FILE_MAPPING.txt
2. Ensure files are from personal_files (not placeholders)
3. Run: flutter clean && flutter pub get
4. Rebuild the app
5. Check console for error messages

---

**Most issues are caused by:**
1. Wrong file locations
2. Placeholder files instead of real files
3. Missing dependencies
4. Incorrect imports

**Solution: Follow the FILE_MAPPING.txt exactly!**
