# App Signing Configuration Guide

This guide will help you configure app signing for Lesson Tracker Pro for production release.

## Why App Signing is Important

App signing is required for:
- Publishing to Google Play Store
- Updating your app in the future
- Verifying app authenticity
- Preventing unauthorized app modifications

## Step 1: Generate a Keystore File

### Using Android Studio:
1. Open Android Studio
2. Go to Build → Generate Signed Bundle/APK
3. Select "Android App Bundle" or "APK"
4. Click "Create new..."
5. Fill in the keystore information:
   - **Keystore path**: Choose a secure location (e.g., `android/app/release.keystore`)
   - **Password**: Create a strong password (save this securely!)
   - **Key alias**: `release` (or your preferred name)
   - **Key password**: Create a strong password (save this securely!)
   - **Validity**: At least 10,000 days (27+ years)
   - **Certificate**: First and Last Name, Organization, etc.

### Using Command Line:
```bash
keytool -genkey -v -keystore android/app/release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
```

**IMPORTANT:** Store your keystore file and passwords securely. If you lose them, you cannot update your app!

## Step 2: Configure build.gradle.kts

Update `android/app/build.gradle.kts` to add signing configuration:

```kotlin
android {
    namespace = "com.lessontrackerpro.lesson_tracker_pro"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.lessontrackerpro.lesson_tracker_pro"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Add signing configuration
    signingConfigs {
        create("release") {
            storeFile = file("release.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "YOUR_STORE_PASSWORD"
            keyAlias = System.getenv("KEY_ALIAS") ?: "release"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "YOUR_KEY_PASSWORD"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            minifyEnabled true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}
```

## Step 3: Secure Your Keystore Passwords

### Option 1: Environment Variables (Recommended)
Create a `local.properties` file (add to .gitignore):
```properties
KEYSTORE_PASSWORD=your_store_password
KEY_PASSWORD=your_key_password
```

Then update build.gradle.kts to read from local.properties:
```kotlin
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withInputStream { stream ->
        localProperties.load(stream)
    }
}

signingConfigs {
    create("release") {
        storeFile = file("release.keystore")
        storePassword = localProperties.getProperty("KEYSTORE_PASSWORD")
        keyAlias = localProperties.getProperty("KEY_ALIAS") ?: "release"
        keyPassword = localProperties.getProperty("KEY_PASSWORD")
    }
}
```

### Option 2: Gradle Properties
Add to `~/.gradle/gradle.properties`:
```properties
KEYSTORE_PASSWORD=your_store_password
KEY_PASSWORD=your_key_password
```

## Step 4: Add Keystore to .gitignore

Add the keystore file to `.gitignore` to prevent committing it:
```
android/app/release.keystore
android/local.properties
```

## Step 5: Build Release APK/AAB

### Build APK:
```bash
flutter build apk --release
```

### Build App Bundle (Recommended for Play Store):
```bash
flutter build appbundle --release
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

## Step 6: Verify the Build

Test the release build on a device:
```bash
flutter install --release
```

## Important Security Notes

1. **Never commit your keystore file** to version control
2. **Never share your keystore passwords**
3. **Back up your keystore file** in multiple secure locations
4. **Use strong passwords** for both keystore and key
5. **Document your passwords** in a secure password manager
6. **If you lose your keystore**, you cannot update your app on the Play Store

## Troubleshooting

**Problem:** Build fails with signing error
**Solution:** 
- Verify keystore file exists at the correct path
- Check that passwords are correct
- Ensure file permissions allow reading the keystore

**Problem:** "Invalid keystore format"
**Solution:** Regenerate the keystore file with a newer keytool version

**Problem:** "Key not found"
**Solution:** Verify the key alias matches what you used when generating the keystore

## Next Steps

After signing configuration:
1. Build release APK/AAB
2. Test thoroughly on physical devices
3. Upload to Google Play Console
4. Complete store listing
5. Submit for review

## Additional Resources

- [Android App Signing Documentation](https://developer.android.com/studio/publish/app-signing)
- [Flutter Release Builds](https://flutter.dev/docs/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
