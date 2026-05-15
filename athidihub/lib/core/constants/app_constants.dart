import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.107.2.110:8080';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8080';
      case TargetPlatform.fuchsia:         
          return 'http://10.107.2.110:8080';
      }
  }
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Supabase ───────────────────────────────────────────────
  static const String supabaseUrl = 'https://bnaidwubkwzqzkgwxtux.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuYWlkd3Via3d6cXprZ3d4dHV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0NjI0NzQsImV4cCI6MjA5MzAzODQ3NH0.f8cGWbB3gn0aKQhp3I-zOsecpJGz6ZJjfe7UXxpJLtI';
  static const String firebaseWebVapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  // ── Razorpay ───────────────────────────────────────────────
  static const String razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID';

  // ── Storage Keys ───────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser = 'user';
  static const String keySelectedOrg = 'selected_org';
  static const String keyOnboardingCompleted = 'onboarding_completed';

  // ── Pagination ─────────────────────────────────────────────
  static const int pageSize = 20;

  // ── Animation Durations ────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);

  // ── Spacing ────────────────────────────────────────────────
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 16;
  static const double spacingLG = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // ── Border Radius ──────────────────────────────────────────
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 24;
  static const double radiusFull = 100;

  // ── Onboarding Steps ──────────────────────────────────────
  static const int onboardingTotalSteps = 4;
}
