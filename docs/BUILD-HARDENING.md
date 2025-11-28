# Build Hardening Guide

This document describes how to build the YouTracker Flutter app with security hardening measures to protect against reverse engineering and unauthorized access.

## Table of Contents

1. [Release Build with Obfuscation](#release-build-with-obfuscation)
2. [Android Build Hardening](#android-build-hardening)
3. [iOS Build Hardening](#ios-build-hardening)
4. [Environment Configuration](#environment-configuration)
5. [ProGuard/R8 Configuration](#proguardr8-configuration)
6. [Certificate Pinning](#certificate-pinning)
7. [Debug Symbol Management](#debug-symbol-management)
8. [CI/CD Integration](#cicd-integration)

---

## Release Build with Obfuscation

### Android APK

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-symbols/ \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://api.youtracker.example.com
```

### Android App Bundle (Recommended for Play Store)

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-symbols/ \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://api.youtracker.example.com
```

### iOS

```bash
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/debug-symbols/ \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://api.youtracker.example.com
```

### Build Flags Explained

| Flag | Description |
|------|-------------|
| `--obfuscate` | Obfuscates Dart code by renaming classes, functions, and variables to meaningless names |
| `--split-debug-info=<path>` | Separates debug symbols into a directory (required for crash report symbolication) |
| `--dart-define` | Passes compile-time environment variables |

---

## Android Build Hardening

### 1. Enable ProGuard/R8 Shrinking

Edit `android/app/build.gradle`:

```groovy
android {
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 2. Configure ProGuard Rules

Create/update `android/app/proguard-rules.pro`:

```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Hive adapters
-keep class you_tracker.models.** { *; }
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite { *; }

# Firebase (if using Crashlytics)
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Prevent reflection-based attacks
-keepattributes Signature
-keepattributes InnerClasses
```

### 3. Disable Debugging in Release

Ensure `android/app/src/main/AndroidManifest.xml` doesn't have:
- `android:debuggable="true"`
- `android:allowBackup="true"` (consider security implications)

```xml
<application
    android:allowBackup="false"
    android:fullBackupContent="false"
    ...>
```

### 4. Network Security Configuration

Create `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">api.youtracker.example.com</domain>
        <domain includeSubdomains="true">googleapis.com</domain>
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </domain-config>
    
    <!-- Development only - REMOVE FOR PRODUCTION -->
    <!-- <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
    </domain-config> -->
</network-security-config>
```

Reference it in `AndroidManifest.xml`:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

---

## iOS Build Hardening

### 1. Enable Bitcode (if applicable)

In Xcode, enable Bitcode for release builds:
- Select your target > Build Settings > Enable Bitcode: Yes

### 2. App Transport Security

In `ios/Runner/Info.plist`, ensure ATS is enabled:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.youtracker.example.com</key>
        <dict>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 3. Disable Debugging Capabilities

For release builds, ensure:
- `DEBUG_INFORMATION_FORMAT` is set to `dwarf` (not `dwarf-with-dsym` in the app itself)
- Debug symbols are exported separately

---

## Environment Configuration

### Using --dart-define

Pass environment variables at build time:

```bash
flutter build apk --release \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://api.youtracker.example.com \
  --dart-define=CRASH_REPORTING_ENABLED=true \
  --dart-define=ANALYTICS_ENABLED=true
```

### Available Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENV` | Environment type (development/staging/production) | development |
| `API_BASE_URL` | Backend API base URL | - |
| `DEBUG_MODE` | Enable debug features | false in prod |
| `CRASH_REPORTING_ENABLED` | Enable crash reporting | true in prod |
| `ANALYTICS_ENABLED` | Enable analytics | true in prod |
| `VERBOSE_LOGGING` | Enable verbose logging | false in prod |
| `CERTIFICATE_PINNING_ENABLED` | Enable cert pinning | true in prod |

### CI/CD Environment

Store secrets in your CI/CD platform's secret management:
- GitHub Actions: Repository secrets
- GitLab CI: CI/CD variables
- Azure DevOps: Variable groups

Example GitHub Actions workflow:

```yaml
- name: Build Release APK
  run: |
    flutter build apk --release \
      --obfuscate \
      --split-debug-info=build/debug-symbols/ \
      --dart-define=ENV=production \
      --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }}
```

---

## Certificate Pinning

For additional security, implement certificate pinning. This is recommended for production builds.

### Implementation

1. Add your server's certificate SHA-256 fingerprint to your configuration
2. Use an HTTP client that supports pinning (like `http_certificate_pinning` package)
3. Implement pinning in your API client

Example conceptual implementation:

```dart
// lib/src/security/certificate_pinning.dart

class CertificatePinning {
  // SHA-256 fingerprints of your server's certificate chain
  static const List<String> pinnedCertificates = [
    // Replace with your actual certificate fingerprints
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ];
  
  // Implement verification in your HTTP client
}
```

---

## Debug Symbol Management

### Storing Debug Symbols

After a release build, store the debug symbols for crash symbolication:

```bash
# After build
zip -r debug-symbols-v1.0.0.zip build/debug-symbols/

# Upload to your crash reporting service
# For Firebase Crashlytics:
firebase crashlytics:symbols:upload --app=YOUR_APP_ID build/debug-symbols/
```

### Symbol Storage Best Practices

1. **Version-tag symbols**: Name symbol archives with the app version
2. **Secure storage**: Store in a secure location (not public Git)
3. **Retention policy**: Keep symbols for all production releases
4. **Automated upload**: Integrate symbol upload into CI/CD

---

## CI/CD Integration

### Example GitHub Actions Workflow

```yaml
name: Build Production Release

on:
  release:
    types: [published]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build Release APK
        run: |
          flutter build apk --release \
            --obfuscate \
            --split-debug-info=build/debug-symbols/ \
            --dart-define=ENV=production \
            --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }}
      
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
      
      - name: Archive Debug Symbols
        run: zip -r debug-symbols.zip build/debug-symbols/
      
      - name: Upload Debug Symbols
        uses: actions/upload-artifact@v4
        with:
          name: debug-symbols
          path: debug-symbols.zip
```

---

## Security Checklist

Before each production release, verify:

- [ ] Obfuscation is enabled (`--obfuscate`)
- [ ] Debug symbols are split and archived
- [ ] No hardcoded API keys or secrets in code
- [ ] Environment variables are loaded from secure sources
- [ ] ProGuard/R8 shrinking is enabled for Android
- [ ] Network security config restricts cleartext traffic
- [ ] `android:debuggable` is false for release
- [ ] App Transport Security is enabled for iOS
- [ ] Certificate pinning is implemented (if applicable)
- [ ] Crash reporting is configured for production
- [ ] All `.env` files are in `.gitignore`

---

## Troubleshooting

### Obfuscation Breaking Reflection

If obfuscation breaks certain features (e.g., JSON serialization):
1. Add keep rules to ProGuard
2. Use code generation (json_serializable) instead of reflection

### Debug Symbols Not Matching

Ensure you're using the exact debug symbols from the build that produced the release binary.

### App Crashing in Release Only

1. Check ProGuard rules aren't removing necessary code
2. Verify all native dependencies have keep rules
3. Test in profile mode first (`flutter run --profile`)

---

## Additional Resources

- [Flutter Obfuscation Documentation](https://docs.flutter.dev/deployment/obfuscate)
- [Android ProGuard Guide](https://developer.android.com/studio/build/shrink-code)
- [iOS App Security Best Practices](https://developer.apple.com/documentation/security)
- [OWASP Mobile Security Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
