# Troubleshooting Guide

## Common Issues and Solutions

### ❌ Camera Error: MissingPluginException

**Error Message:**
```
Failed to initialize camera:
MissingPluginException(No implementation found for method checkPermissionStatus 
on channel flutter.baseflow.com/permissions/methods)
```

**Cause:** Flutter plugins not properly registered or build cache issue.

**Solution:**

#### Step 1: Clean Build
```bash
flutter clean
flutter pub get
```

#### Step 2: For Android
```bash
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

#### Step 3: For iOS
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter pub get
flutter run
```

#### Step 4: If Still Not Working
1. Stop the app completely
2. Uninstall from device
3. Run: `flutter clean && flutter pub get`
4. Rebuild: `flutter run --release`

---

### ❌ Permission Denied Errors

**Error:** Camera or location permissions not granted

**Solution:**

1. **Check AndroidManifest.xml** has all permissions:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

2. **Check Info.plist** has all descriptions:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location access</string>
```

3. **Manually grant permissions:**
   - Go to device Settings → Apps → Your App → Permissions
   - Enable Camera and Location

4. **Request permissions in code:**
```dart
if (!await sdk.hasPermissions()) {
  await sdk.requestPermissions();
}
```

---

### ❌ GPS Timeout

**Error:** `TimeoutException: GPS location retrieval timed out`

**Solution:**

1. **Move to open area** with clear sky view
2. **Enable location services** in device settings
3. **Increase timeout:**
```dart
CdlPhotoGpsSDK(
  config: SDKConfig(
    gpsTimeout: Duration(seconds: 30), // Increase from 15 to 30
  ),
);
```
4. **Check location mode:** Set to "High accuracy" in device settings

---

### ❌ Build Errors

**Error:** Compilation or build failures

**Solution:**

#### For Android:
```bash
# Update gradle
cd android
./gradlew clean
./gradlew build
cd ..

# If still failing, check:
# android/app/build.gradle
android {
    defaultConfig {
        minSdkVersion 21  // Must be at least 21
    }
}
```

#### For iOS:
```bash
# Update pods
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# If still failing, check:
# ios/Podfile
platform :ios, '12.0'  # Must be at least 12.0
```

#### General:
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

---

### ❌ Camera Preview Black Screen

**Error:** Camera shows but preview is black

**Solution:**

1. **Check device camera works** in other apps
2. **Restart the app** completely
3. **Check no other app is using camera**
4. **Try different camera:**
```dart
await sdk.switchCamera(); // If device has multiple cameras
```
5. **Reinitialize:**
```dart
await sdk.dispose();
await sdk.initialize();
```

---

### ❌ Mock GPS Not Detected

**Issue:** Fake GPS apps not being caught

**Solution:**

1. **Ensure detection is enabled:**
```dart
CdlPhotoGpsSDK(
  config: SDKConfig(
    detectMockGPS: true, // Must be true
  ),
);
```

2. **Check the result:**
```dart
final result = await sdk.capturePhotoWithLocation();
print('Is mock: ${result.isMockLocation}');
print('Confidence: ${result.locationConfidence}');
```

3. **Note:** Detection works better on Android than iOS

4. **Use confidence score as backup:**
```dart
if (result.locationConfidence < 0.7) {
  // Low confidence, might be fake
}
```

---

### ❌ Image Upload Fails

**Error:** Photo upload to backend fails

**Solution:**

1. **Check image size:**
```dart
print('Photo size: ${result.photoSize} bytes');
// If too large, reduce quality:
CdlPhotoGpsSDK(
  config: SDKConfig(
    imageQuality: 70, // Reduce from 85
  ),
);
```

2. **Check format matches backend:**
```dart
// For base64 API
config: SDKConfig(outputFormat: OutputFormat.base64)

// For multipart
config: SDKConfig(outputFormat: OutputFormat.bytes)
```

3. **Test with curl:**
```bash
curl -X POST https://your-api.com/photos \
  -H "Content-Type: application/json" \
  -d '{"image":"base64string..."}'
```

---

### ❌ App Crashes on Launch

**Error:** App crashes immediately

**Solution:**

1. **Check logs:**
```bash
# Android
adb logcat | grep Flutter

# iOS
flutter logs
```

2. **Common causes:**
   - Missing permissions in manifest
   - Plugin version conflicts
   - Minimum SDK version too low

3. **Fix:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run --release
```

---

### ❌ Location Services Disabled

**Error:** `LocationServiceDisabledException`

**Solution:**

1. **Enable location on device:**
   - Android: Settings → Location → On
   - iOS: Settings → Privacy → Location Services → On

2. **Handle in code:**
```dart
try {
  final result = await sdk.capturePhotoWithLocation();
} on LocationServiceDisabledException {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Enable Location'),
      content: Text('Please enable location services'),
      actions: [
        TextButton(
          onPressed: () => sdk.openAppSettings(),
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}
```

---

### ❌ Emulator Issues

**Issue:** SDK doesn't work on emulator

**Solution:**

**The SDK requires physical device with real camera and GPS.**

Emulators have limitations:
- No real camera hardware
- Simulated GPS (detected as mock)
- Poor performance

**Always test on physical device.**

---

### ❌ iOS Specific Issues

#### Issue: "No such module 'permission_handler'"

**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter run
```

#### Issue: Signing errors

**Solution:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner → Signing & Capabilities
3. Select your team
4. Enable "Automatically manage signing"

---

### ❌ Android Specific Issues

#### Issue: "Execution failed for task ':app:processDebugManifest'"

**Solution:**
Check `android/app/src/main/AndroidManifest.xml`:
- All permissions are inside `<manifest>` tag
- No duplicate permissions
- Proper XML formatting

#### Issue: "Minimum supported Gradle version is X.X"

**Solution:**
Update `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-7.5-all.zip
```

---

## 🔍 Debug Checklist

When something goes wrong, check:

- [ ] Running on physical device (not emulator)
- [ ] All permissions in AndroidManifest.xml
- [ ] All permission descriptions in Info.plist
- [ ] Minimum SDK versions correct (Android 21, iOS 12.0)
- [ ] `flutter clean && flutter pub get` executed
- [ ] App uninstalled and reinstalled
- [ ] Location services enabled on device
- [ ] Camera works in other apps
- [ ] Internet connection available (for geocoding)
- [ ] Latest Flutter version: `flutter upgrade`

---

## 🆘 Still Having Issues?

1. **Check example app:** Run the example app in the repo to verify SDK works
```bash
cd example
flutter run
```

2. **Enable verbose logging:**
```dart
// Add print statements
final result = await sdk.capturePhotoWithLocation();
print('Result: ${result.locationData.latitude}');
print('Mock: ${result.isMockLocation}');
```

3. **Check Flutter doctor:**
```bash
flutter doctor -v
```

4. **Report issue:** https://github.com/habib2013/photo_gps/issues

Include:
- Error message
- Flutter version
- Device/OS version
- Steps to reproduce

---

## 📞 Quick Fixes Summary

| Issue | Quick Fix |
|-------|-----------|
| MissingPluginException | `flutter clean && flutter pub get` |
| Permission denied | Check manifest/plist, grant manually |
| GPS timeout | Move outdoors, increase timeout |
| Build errors | Clean, update gradle/pods |
| Black screen | Restart app, check camera works |
| Mock GPS not detected | Enable in config, check confidence |
| Upload fails | Check size, format, test API |
| Crashes | Check logs, clean build |
| Location disabled | Enable in device settings |
| Emulator issues | Use physical device |

---

## ✅ Prevention Tips

1. **Always test on physical device**
2. **Clean build after dependency changes**
3. **Check permissions before capture**
4. **Handle all exceptions**
5. **Test in different locations (indoor/outdoor)**
6. **Verify backend API works separately**
7. **Keep Flutter and dependencies updated**
8. **Read error messages carefully**

---

Good luck! 🚀
