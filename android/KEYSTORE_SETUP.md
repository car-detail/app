# Android Release Keystore Setup Guide

## Step 1: Generate Keystore

Run this command in the `app/android/` directory:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- Keystore password (remember this!)
- Key password (can be same as keystore password)
- Your name and organization details

## Step 2: Create key.properties

1. Copy `key.properties.template` to `key.properties`
2. Fill in your passwords
3. **IMPORTANT:** Add `key.properties` to `.gitignore` (never commit this file!)

## Step 3: Verify Build

Run:
```bash
flutter build apk --release
```

The build should now use your release keystore.

## Security Notes

- **NEVER** commit `key.properties` or `upload-keystore.jks` to git
- Store keystore backup in secure location
- If you lose the keystore, you cannot update your app on Play Store


