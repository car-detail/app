# Build Instructions for Cahrz Apps (iOS & Android)

This document contains all the required versions and configurations needed to build both iOS and Android versions of the Cahrz apps (app and app-user). Please ensure all versions match exactly to avoid build conflicts.

**Note**: This guide covers both iOS (Mac required) and Android build requirements. For iOS builds, you need a Mac. For Android builds, you can use Mac, Windows, or Linux.

## Prerequisites

### 1. macOS Requirements
- **macOS Version**: macOS 12.0 (Monterey) or later
- **Minimum macOS**: macOS 11.0 (Big Sur) for Xcode 13.0

### 2. Xcode Requirements
- **Xcode Version**: 14.0 or later (recommended: latest stable version)
- **iOS Deployment Target for `app`**: **iOS 15.0**
- **iOS Deployment Target for `app-user`**: **iOS 14.0**
- **Command Line Tools**: Must be installed
  ```bash
  xcode-select --install
  ```

### 3. Flutter SDK
- **Flutter Version**: **3.29.3** (stable channel)
- **Dart Version**: **3.7.2**
- **DevTools Version**: **2.42.3**

To verify your Flutter version:
```bash
flutter --version
```

If you need to install or switch to this version:
```bash
flutter version 3.29.3
```

### 4. Ruby Version
- **Ruby Version**: 2.7.0 or later (Ruby comes pre-installed on macOS)
- Verify with: `ruby --version`

### 5. CocoaPods
- **CocoaPods Version**: **1.16.2**
- Install/Update CocoaPods:
  ```bash
  sudo gem install cocoapods -v 1.16.2
  ```
- Verify installation:
  ```bash
  pod --version
  ```
  Should output: `1.16.2`

### 6. Java Development Kit (JDK)
- **Java Version**: **OpenJDK 17.0.14** (Java 17)
- **Java Runtime**: OpenJDK Runtime Environment Temurin-17.0.14+7
- **JVM Target**: 17 (required for Android builds and some build tools)
- Verify Java version:
  ```bash
  java -version
  ```
  Should show: `openjdk version "17.0.14"` or similar
  
- Install Java 17 (if not installed):
  - **macOS**: Use Homebrew: `brew install openjdk@17`
  - Or download from: https://adoptium.net/temurin/releases/?version=17
  - Set JAVA_HOME:
    ```bash
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
    ```

### 7. Android Build Tools (for Android builds or shared tools)
- **Gradle Version for `app`**: **8.9**
- **Gradle Version for `app-user`**: **8.7**
- **Android NDK Version**: **27.0.12077973** (for both apps)
- **Java Compatibility**: 
  - Source Compatibility: JavaVersion.VERSION_17
  - Target Compatibility: JavaVersion.VERSION_17
  - JVM Target: 17
- **Core Library Desugaring**: Enabled (desugar_jdk_libs:2.0.4)

Note: Gradle versions are managed by Flutter and specified in `gradle-wrapper.properties` files. They will be downloaded automatically when building.

---

## Project Configuration

### App 1: `app` (Cahrz Vendor)

#### iOS Platform Settings
- **Minimum iOS Version**: iOS 15.0
- **Podfile Location**: `app/ios/Podfile`
- **Bundle Display Name**: "Cahrz Vendor"
- **Bundle Version**: 1.2

#### Key Dependencies from pubspec.yaml
```yaml
environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  intl: ^0.18.1
  flutter_local_notifications: ^17.2.1+2
  permission_handler: ^11.3.1
  shared_preferences: ^2.2.1
  url_launcher: ^6.1.14
  http: ^1.1.0
  http_parser: ^4.0.0
  device_info_plus: ^10.1.2
  crypt: ^4.3.1
  syncfusion_flutter_pdfviewer: ^27.1.58
  fl_chart: ^0.68.0
  package_info_plus: ^4.2.0
  flutter_html: ^3.0.0-beta.2
  html_unescape: ^2.0.0
  file_picker: ^8.0.6
  image_picker: ^1.0.2
  photo_view: ^0.15.0
  share_plus: ^10.1.2
  calendar_view: 1.1.0
  text_marquee: ^0.0.2
  html_editor_enhanced: ^2.6.0
  bot_toast: ^4.1.3
  path_provider: ^2.1.4
  geolocator: ^13.0.2
  convex_bottom_bar: ^3.2.0
  geocoding: ^3.0.0
  flutter_timezone: ^4.0.0
  pinput: ^5.0.0
  carousel_slider: ^5.0.0
  firebase_core: ^3.13.0
  firebase_messaging: ^15.2.5
  firebase_crashlytics: ^4.3.5
  google_maps_places_autocomplete_widgets: ^1.3.3
  shimmer: ^3.0.0
```

#### iOS Podfile Configuration
```ruby
platform :ios, '15.0'
```

#### Android Build Configuration
- **Namespace**: `com.car.carAdmin`
- **Application ID**: `com.car.carAdmin`
- **Gradle Version**: **8.9**
- **Android NDK Version**: **27.0.12077973**
- **Java Version**: JavaVersion.VERSION_17
- **Kotlin JVM Target**: 17
- **Core Library Desugaring**: Enabled (desugar_jdk_libs:2.0.4)

#### Key CocoaPods Dependencies (from Podfile.lock)
- Firebase SDK: **11.10.0**
  - FirebaseCore: 11.10.0
  - FirebaseCrashlytics: 11.10.0
  - FirebaseMessaging: 11.10.0
- DKImagePickerController: **4.3.9**
- DKPhotoGallery: **0.0.19**

---

### App 2: `app-user` (Cahrz)

#### iOS Platform Settings
- **Minimum iOS Version**: iOS 14.0
- **Podfile Location**: `app-user/ios/Podfile`
- **Bundle Display Name**: "Cahrz"
- **Bundle Version**: 1.1

#### Key Dependencies from pubspec.yaml
```yaml
environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  intl: ^0.18.1
  flutter_local_notifications: ^17.2.1+2
  permission_handler: ^11.3.1
  shared_preferences: ^2.2.1
  url_launcher: ^6.1.14
  http: ^1.1.0
  http_parser: ^4.0.0
  device_info_plus: ^10.1.2
  crypt: ^4.3.1
  syncfusion_flutter_pdfviewer: ^27.1.58
  fl_chart: ^0.68.0
  package_info_plus: ^4.2.0
  flutter_html: ^3.0.0-beta.2
  html_unescape: ^2.0.0
  file_picker: ^8.0.6
  image_picker: ^1.0.2
  photo_view: ^0.15.0
  share_plus: ^10.1.2
  calendar_view: 1.1.0
  text_marquee: ^0.0.2
  html_editor_enhanced: ^2.6.0
  bot_toast: ^4.1.3
  path_provider: ^2.1.4
  geolocator: ^13.0.2
  convex_bottom_bar: ^3.2.0
  geocoding: ^3.0.0
  pinput: ^5.0.0
  flutter_timezone: ^4.0.0
  flutter_rating_stars: ^1.1.0
  google_maps_flutter: ^2.10.1
  carousel_slider: ^5.0.0
  firebase_core: ^3.13.0
  firebase_messaging: ^15.2.5
  firebase_crashlytics: ^4.3.5
  google_maps_places_autocomplete_widgets: ^1.3.3
  shimmer: ^3.0.0
```

#### iOS Podfile Configuration
```ruby
platform :ios, '14.0'
```

#### Android Build Configuration
- **Namespace**: `com.car.car_app`
- **Application ID**: `com.car.car`
- **Gradle Version**: **8.7**
- **Android NDK Version**: **27.0.12077973**
- **Java Version**: JavaVersion.VERSION_17
- **Kotlin JVM Target**: 17
- **Core Library Desugaring**: Enabled (desugar_jdk_libs:2.0.4)

#### Key CocoaPods Dependencies (from Podfile.lock)
- Firebase SDK: **11.10.0**
  - FirebaseCore: 11.10.0
  - FirebaseCrashlytics: 11.10.0
  - FirebaseMessaging: 11.10.0
- DKImagePickerController: **4.3.9**
- DKPhotoGallery: **0.0.19**
- google_maps_flutter: **2.10.1**

---

## Build Steps

### Prerequisites Installation Summary

1. **Install Flutter 3.29.3** (includes Dart 3.7.2)
2. **Install Xcode 14.0+** (for iOS builds on Mac)
3. **Install Java JDK 17** (OpenJDK 17.0.14)
4. **Install CocoaPods 1.16.2** (for iOS builds)
5. **Install Ruby 2.7.0+** (usually pre-installed on macOS)

### Step 1: Verify Prerequisites
```bash
# Check Flutter version
flutter --version

# Check CocoaPods version
pod --version

# Check Xcode version
xcodebuild -version

# Check Java version
java -version

# Check Gradle version (if Android Studio is installed)
gradle --version
```

### Step 2: Clone/Setup Project
```bash
# Navigate to project directory
cd /path/to/cahrz

# For app
cd app
flutter clean
flutter pub get

# For app-user
cd ../app-user
flutter clean
flutter pub get
```

### Step 3: Install iOS Dependencies
```bash
# For app
cd app/ios
pod deintegrate
pod install
cd ../..

# For app-user
cd app-user/ios
pod deintegrate
pod install
cd ../..
```

### Step 4: Build Apps

#### iOS Builds (Mac only)

#### Debug Build
```bash
# For app
cd app
flutter build ios --debug

# For app-user
cd app-user
flutter build ios --debug
```

#### Release Build
```bash
# For app
cd app
flutter build ios --release

# For app-user
cd app-user
flutter build ios --release
```

#### Android Builds

```bash
# For app
cd app
flutter build apk --debug
# or for release
flutter build apk --release

# For app-user
cd app-user
flutter build apk --debug
# or for release
flutter build apk --release
```

### Step 5: Open in Xcode (Optional - iOS only)
```bash
# For app
open app/ios/Runner.xcworkspace

# For app-user
open app-user/ios/Runner.xcworkspace
```

---

## Troubleshooting

### Issue: CocoaPods version mismatch
**Solution**: Install the exact version:
```bash
sudo gem install cocoapods -v 1.16.2
```

### Issue: Pod install fails
**Solution**: Clean and reinstall:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
```

### Issue: Flutter version mismatch
**Solution**: Switch to the correct version:
```bash
flutter version 3.29.3
flutter doctor
```

### Issue: Xcode Command Line Tools not found
**Solution**: Install command line tools:
```bash
xcode-select --install
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Issue: Firebase dependencies conflict
**Solution**: Ensure Firebase SDK version is 11.10.0 in Podfile.lock. If different, delete Podfile.lock and run `pod install` again.

### Issue: Java version mismatch
**Solution**: Install Java 17 and set JAVA_HOME:
```bash
# macOS with Homebrew
brew install openjdk@17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Verify
java -version
```

### Issue: Gradle version mismatch
**Solution**: Gradle versions are managed by Flutter. They should automatically match the versions specified in `gradle-wrapper.properties`. If issues persist, check:
- `app/android/gradle/wrapper/gradle-wrapper.properties` should specify Gradle 8.9
- `app-user/android/gradle/wrapper/gradle-wrapper.properties` should specify Gradle 8.7

---

## Version Summary Checklist

Before building, verify these versions match:

### Core Tools
- [ ] Flutter: 3.29.3
- [ ] Dart: 3.7.2
- [ ] CocoaPods: 1.16.2
- [ ] Java (JDK): 17.0.14 (OpenJDK 17)
- [ ] Ruby: 2.7.0 or later

### iOS Specific
- [ ] Xcode: 14.0 or later
- [ ] iOS Deployment Target (app): 15.0
- [ ] iOS Deployment Target (app-user): 14.0
- [ ] Firebase SDK: 11.10.0

### Android Specific (if building Android)
- [ ] Gradle (app): 8.9
- [ ] Gradle (app-user): 8.7
- [ ] Android NDK: 27.0.12077973
- [ ] Java Source/Target: 17
- [ ] Kotlin JVM Target: 17

---

## Additional Notes

1. **Firebase Configuration**: Ensure `GoogleService-Info.plist` files are present in both `app/ios/Runner/` and `app-user/ios/Runner/` directories.

2. **Signing**: You'll need to configure signing certificates in Xcode for both apps:
   - App 1: Bundle ID for "Cahrz Vendor"
   - App 2: Bundle ID for "Cahrz"

3. **Architecture**: Both apps support arm64 (Apple Silicon and Intel Macs).

4. **Build Settings**: The Podfiles use `use_frameworks!` and `use_modular_headers!` which are required for some dependencies.

5. **Minimum Requirements**:
   - App 1 requires iOS 15.0+
   - App 2 requires iOS 14.0+

---

## Contact

If you encounter any build issues that aren't covered in this guide, please share:
- Flutter version (`flutter --version`)
- CocoaPods version (`pod --version`)
- Xcode version (`xcodebuild -version`)
- Java version (`java -version`)
- Gradle version (`gradle --version` or check `gradle-wrapper.properties`)
- Error messages from the build process

---

**Last Updated**: Based on current project configuration
**Flutter Version**: 3.29.3
**CocoaPods Version**: 1.16.2
**Java Version**: OpenJDK 17.0.14
**Gradle Versions**: 8.9 (app), 8.7 (app-user)
**Android NDK Version**: 27.0.12077973

