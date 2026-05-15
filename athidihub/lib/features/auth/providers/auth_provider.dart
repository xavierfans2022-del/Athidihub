import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:athidihub/core/logging/app_logger.dart';
import 'package:athidihub/core/providers/supabase_provider.dart';
import 'package:athidihub/core/cache/cache_provider.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/onboarding/providers/navigation_provider.dart';
import 'package:athidihub/features/dashboard/providers/dashboard_provider.dart';

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  SupabaseClient get _client => _ref.read(supabaseClientProvider);

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

  Future<void> loginWithEmail(String email, String password) async {
    await _runAuthAction(
      action: 'sign_in_email',
      context: {'email': AppLogger.maskEmail(email)},
      task: () async {
        await _client.auth.signInWithPassword(email: email, password: password);
        await _onSignInSuccess();
      },
    );
  }

  Future<void> loginWithEmailOtp(String email) async {
    await _runAuthAction(
      action: 'send_email_otp',
      context: {'email': AppLogger.maskEmail(email)},
      task: () async {
        await _client.auth.signInWithOtp(email: email);
      },
    );
  }

  Future<void> loginWithPhone(String phone) async {
    await _runAuthAction(
      action: 'send_phone_otp',
      context: {'phone': AppLogger.maskPhone(phone)},
      task: () async {
        await _client.auth.signInWithOtp(phone: phone);
      },
    );
  }

  Future<void> verifyOtp(String identifier, String otp) async {
    await _runAuthAction(
      action: 'verify_otp',
      context: {
        'identifier': identifier.contains('@')
            ? AppLogger.maskEmail(identifier)
            : AppLogger.maskPhone(identifier),
      },
      task: () async {
        final isEmail = identifier.contains('@');
        await _client.auth.verifyOTP(
          email: isEmail ? identifier : null,
          phone: !isEmail ? identifier : null,
          token: otp,
          type: isEmail ? OtpType.email : OtpType.sms,
        );
        await _onSignInSuccess();
      },
    );
  }

  Future<void> registerWithEmail(String email, String password, String name) async {
    await _runAuthAction(
      action: 'sign_up_email',
      context: {'email': AppLogger.maskEmail(email), 'name': name},
      task: () async {
        await _client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
        );
        await _onSignInSuccess();
      },
    );
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
