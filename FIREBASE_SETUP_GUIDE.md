# Firebase Setup Guide for Lesson Tracker Pro

This guide will help you set up Firebase Analytics and Crashlytics for your Flutter app.

## Prerequisites

1. Create a Firebase account at https://console.firebase.google.com/
2. Have your Flutter project ready
3. Android Studio or VS Code installed

## Step 1: Create Firebase Project

1. Go to Firebase Console: https://console.firebase.google.com/
2. Click "Add project"
3. Enter project name: "Lesson Tracker Pro"
4. Accept Firebase terms and click "Create project"
5. Wait for project creation to complete

## Step 2: Add Android App

1. In Firebase Console, click the Android icon to add an Android app
2. Enter package name: `com.lessontrackerpro.app` (check your android/app/build.gradle for the actual package name)
3. Download `google-services.json`
4. Place `google-services.json` in `android/app/` directory
5. Click "Next" to skip the remaining steps (we'll configure manually)

## Step 3: Add iOS App (Optional)

1. In Firebase Console, click the iOS icon to add an iOS app
2. Enter bundle ID: `com.lessontrackerpro.app` (check your iOS project for the actual bundle ID)
3. Download `GoogleService-Info.plist`
4. Place `GoogleService-Info.plist` in `ios/Runner/` directory
5. Click "Next" to skip the remaining steps

## Step 4: Add Dependencies to pubspec.yaml

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_analytics: ^11.3.3
  firebase_crashlytics: ^4.1.3
```

Then run:
```bash
flutter pub get
```

## Step 5: Configure Android

### 5.1 Add google-services classpath

Open `android/build.gradle` (project level) and add:

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

### 5.2 Apply google-services plugin

Open `android/app/build.gradle` (app level) and add:

```gradle
// Add this at the very top
apply plugin: 'com.google.gms.google-services'

android {
    // existing configuration
}
```

### 5.3 Enable Crashlytics in Android

In `android/app/build.gradle`, add:

```gradle
android {
    // existing configuration
    
    buildTypes {
        release {
            // Add this
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

## Step 6: Configure iOS (Optional)

### 6.1 Add Firebase SDK

Open `ios/Podfile` and add:

```ruby
pod 'Firebase/Core'
pod 'Firebase/Analytics'
pod 'Firebase/Crashlytics'
```

Then run:
```bash
cd ios
pod install
cd ..
```

### 6.2 Enable Crashlytics in iOS

Open `ios/Runner/Info.plist` and add:

```xml
<key>FirebaseCrashlyticsCollectionEnabled</key>
<true/>
```

## Step 7: Initialize Firebase in Flutter

Update your `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set up Crashlytics
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordError(
      details.exception,
      details.stack,
      fatal: true,
    );
  };
  
  // Other existing code...
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  Logger.info('App starting');
  runApp(const ProviderScope(child: LessonTrackerProApp()));
}
```

## Step 8: Add Analytics Tracking

Create a new file `lib/core/services/analytics_service.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }
  
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
  
  static Future<void> logLogin() async {
    await _analytics.logLogin(loginMethod: 'app');
  }
  
  static Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }
}
```

## Step 9: Test the Setup

1. Run the app on a physical device or emulator
2. Check Firebase Console for analytics data
3. Force a crash to test Crashlytics:
   ```dart
   // Add this temporarily to test
   FirebaseCrashlytics.instance.crash();
   ```

## Step 10: Verify in Firebase Console

1. Go to Firebase Console
2. Navigate to Analytics → Dashboard to see user engagement
3. Navigate to Crashlytics → Dashboard to see crash reports

## Important Notes

- Firebase Analytics and Crashlytics require a physical device or emulator with Google Play Services
- For iOS, you need an Apple Developer account
- Test thoroughly before releasing to production
- Review Firebase pricing (free tier is generous for most apps)

## Next Steps

After Firebase is set up:

1. Add analytics tracking to key user actions:
   - Screen views
   - Button clicks
   - Form submissions
   - Important events (lesson booking, payment recording, etc.)

2. Set up custom events for your specific use cases

3. Configure crash reporting alerts

4. Review analytics data regularly to improve user experience

## Troubleshooting

**Problem:** Build fails after adding Firebase
**Solution:** Make sure you've run `flutter pub get` and `flutter clean`

**Problem:** No analytics data showing
**Solution:** Check that you're running on a physical device or emulator with Google Play Services

**Problem:** Crashlytics not reporting crashes
**Solution:** Ensure you've enabled Crashlytics in both Firebase Console and your app configuration
