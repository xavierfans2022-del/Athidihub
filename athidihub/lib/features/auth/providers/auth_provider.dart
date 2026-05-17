import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:athidihub/core/logging/app_logger.dart';
import 'package:athidihub/core/providers/supabase_provider.dart';
import 'package:athidihub/core/cache/cache_provider.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/onboarding/providers/navigation_provider.dart';
import 'package:athidihub/features/dashboard/providers/dashboard_provider.dart';

enum MpinFlow {
  none,
  setup,
  unlock,
}

final mpinFlowProvider = StateProvider<MpinFlow>((ref) => MpinFlow.none);
final mpinUnlockedProvider = StateProvider<bool>((ref) => false);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  Dio get _dio => Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
        ),
      );

  String _normalizePhoneForOtp(String value) {
    final compact = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (compact.isEmpty) {
      throw const FormatException('Missing phone number');
    }

    if (compact.startsWith('+')) {
      if (!RegExp(r'^\+\d{8,15}$').hasMatch(compact)) {
        throw const FormatException('Invalid phone number format');
      }

      if (!compact.startsWith(AppConstants.defaultPhoneCountryCode)) {
        throw const FormatException('Use an Indian phone number with +91 country code');
      }

      return compact;
    }

    final digits = compact.replaceAll(RegExp(r'\D+'), '');
    if (digits.length != 10) {
      throw const FormatException('Enter a 10-digit Indian mobile number');
    }

    return '${AppConstants.defaultPhoneCountryCode}$digits';
  }

  Future<void> _runAuthAction({
    required String action,
    required Map<String, Object?> context,
    required Future<void> Function() task,
  }) async {
    state = const AsyncValue.loading();
    final stopwatch = Stopwatch()..start();
    AppLogger.authEvent('${action}_started', data: context);
    try {
      await task();
      stopwatch.stop();
      state = const AsyncValue.data(null);
      AppLogger.authEvent('${action}_succeeded', data: {
        ...context,
        'durationMs': stopwatch.elapsedMilliseconds,
      });
    } catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.error('Supabase auth action failed', error: error, stackTrace: stackTrace, data: {
        'action': action,
        ...context,
        'durationMs': stopwatch.elapsedMilliseconds,
      });
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Called after successful login/OTP verify — clears stale cache and refreshes navigation
  Future<void> _onSignInSuccess() async {
    try {
      // Clear all in-memory + persistent cache so fresh data is fetched
      final cacheService = _ref.read(cacheServiceProvider);
      await cacheService.clearAll();

      // Clear stale org ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keySelectedOrg);

      // Invalidate all navigation/org providers so they re-fetch
      _ref.invalidate(navigationDataProvider);
      _ref.invalidate(onboardingProgressProvider);
      _ref.invalidate(userOrganizationsProvider);
      _ref.invalidate(selectedOrganizationIdProvider);
    } catch (e) {
      AppLogger.warning('Failed to clear cache on signin', error: e);
    }
  }

  Future<void> _onSignOutSuccess() async {
    try {
      final cacheService = _ref.read(cacheServiceProvider);
      await cacheService.clearAll();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keySelectedOrg);

      // Invalidate all providers
      _ref.invalidate(navigationDataProvider);
      _ref.invalidate(onboardingProgressProvider);
      _ref.invalidate(userOrganizationsProvider);
      _ref.invalidate(selectedOrganizationIdProvider);
    } catch (e) {
      AppLogger.warning('Failed to clear cache on signout', error: e);
    }
  }

  Future<void> requestPhoneOtp(String phone) async {
    await _runAuthAction(
      action: 'send_phone_otp',
      context: {'phone': AppLogger.maskPhone(phone)},
      task: () async {
        final normalizedPhone = _normalizePhoneForOtp(phone);
        await _client.auth.signInWithOtp(phone: normalizedPhone);
      },
    );
  }

  Future<void> verifyPhoneOtp(String phone, String otp) async {
    await _runAuthAction(
      action: 'verify_phone_otp',
      context: {'phone': AppLogger.maskPhone(phone)},
      task: () async {
        final normalizedPhone = _normalizePhoneForOtp(phone);
        await _client.auth.verifyOTP(
          phone: normalizedPhone,
          token: otp,
          type: OtpType.sms,
        );
      },
    );
  }

  Future<void> setupMpin({
    required String pin,
    required String fullName,
    required String role,
  }) async {
    await _runAuthAction(
      action: 'setup_mpin',
      context: {
        'name': fullName,
        'role': role,
      },
      task: () async {
        final session = _client.auth.currentSession;
        if (session == null) {
          throw Exception('Session not available');
        }

        await _client.auth.updateUser(
          UserAttributes(data: {
            'full_name': fullName,
            'name': fullName,
            'role': role,
          }),
        );

        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/mpin/setup',
          data: {
            'pin': pin,
            'fullName': fullName,
            'role': role,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
            },
          ),
        );

        if (response.statusCode != null && response.statusCode! >= 400) {
          throw Exception('Unable to set MPIN');
        }
      },
    );
  }

  Future<void> verifyMpin(String pin) async {
    await _runAuthAction(
      action: 'verify_mpin',
      context: const {},
      task: () async {
        final session = _client.auth.currentSession;
        if (session == null) {
          throw Exception('Session not available');
        }

        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/mpin/verify',
          data: {'pin': pin},
          options: Options(
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
            },
          ),
        );

        if (response.statusCode != null && response.statusCode! >= 400) {
          throw Exception('Invalid MPIN');
        }
      },
    );
  }

  Future<void> finalizeSignedInSession() async {
    _ref.read(mpinUnlockedProvider.notifier).state = true;
    _ref.read(mpinFlowProvider.notifier).state = MpinFlow.none;
    await _onSignInSuccess();
  }

  void prepareForSetup() {
    _ref.read(mpinFlowProvider.notifier).state = MpinFlow.setup;
    _ref.read(mpinUnlockedProvider.notifier).state = false;
  }

  void prepareForUnlock() {
    _ref.read(mpinFlowProvider.notifier).state = MpinFlow.unlock;
    _ref.read(mpinUnlockedProvider.notifier).state = false;
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    await _runAuthAction(
      action: 'update_user',
      context: {'data': AppLogger.sanitize(data)},
      task: () async {
        await _client.auth.updateUser(UserAttributes(data: data));
      },
    );
  }

  Future<void> signOut() async {
    await _runAuthAction(
      action: 'sign_out',
      context: const {},
      task: () async {
        await _onSignOutSuccess();
        _ref.read(mpinFlowProvider.notifier).state = MpinFlow.none;
        _ref.read(mpinUnlockedProvider.notifier).state = false;
        await _client.auth.signOut();
      },
    );
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref);
});
