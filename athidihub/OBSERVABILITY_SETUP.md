Observability and Crashlytics setup

- What I changed:
 - No Firebase SDKs are required for observability in this branch to avoid package version conflicts with existing dependencies.
 - Analytics is implemented via GA4 Measurement Protocol (HTTP).
 - Crash reporting is forwarded to a configurable backend endpoint for aggregation (see `errorReportingUrl`).
- Added `lib/core/observability/observability.dart` helper for Analytics/Crashlytics usage.
- App-level error handlers and guarded zone are installed so uncaught errors go to Crashlytics.
- AppLogger forwards error-level logs to Crashlytics via `Observability.logError`.

Manual platform checks you should verify before production:
- Android: ensure `android/app/google-services.json` exists and matches the Firebase project. Add `com.google.firebase:firebase-crashlytics` plugin if required in Gradle (FlutterFire CLI normally sets this).
- iOS: ensure `ios/Runner/GoogleService-Info.plist` is present and added to Xcode target.
- In Firebase Console: enable Crashlytics, Analytics, and link apps.

How to test locally:
1. Run the app on a device/emulator after `flutter pub get`.
2. Force a test crash to validate Crashlytics (only in release builds). Example snippet:

```dart
// Place this somewhere where it will run after init
FirebaseCrashlytics.instance.crash();
```

3. Use `Observability.logEvent('test_event', {'foo': 'bar'})` to send a test analytics event.

GA4 Measurement Protocol setup:
- Create a Web Data Stream in GA4 and obtain the `measurement_id` and an `api_secret` (Admin > Data Streams > Measurement Protocol API secrets).
- Pass these values into `Observability.initialize(gaMeasurementId: 'G-XXXX', gaApiSecret: 'SECRET')` at app startup (or wire via runtime config).

Crash reporting setup:
- Provide an `errorReportingUrl` to `Observability.logError(...)` calls (or configure a wrapper in `AppLogger`) that points to your backend endpoint which will store/forward errors to your chosen error sink.

Notes:
- I removed `firebase_performance` due to dependency conflicts with existing Firebase packages in this project; we can add it after upgrading core Firebase dependencies if desired.
