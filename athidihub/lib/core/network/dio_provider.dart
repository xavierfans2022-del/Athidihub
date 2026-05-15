import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Rate Limiter ────────────────────────────────────────────────────────

class RateLimiter {
  final Map<String, int> _lastRequestTime = {};
  static const int _defaultLimitMs = 500; // 500ms between requests by default
  
  bool isAllowed(String key, {int limitMs = _defaultLimitMs}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastRequestTime[key] ?? 0;
    
    if (now - lastTime >= limitMs) {
      _lastRequestTime[key] = now;
      return true;
    }
    
    AppLogger.info('Request rate limited', data: {
      'key': key,
      'limitMs': limitMs,
      'timeSinceLastMs': now - lastTime,
    });
    return false;
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  final rateLimiter = RateLimiter();

  // Auth interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final stopwatch = Stopwatch()..start();
        options.extra['loggerStopwatch'] = stopwatch;

        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        AppLogger.apiRequest(
          method: options.method,
          path: options.path,
          data: options.data,
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        final stopwatch = response.requestOptions.extra['loggerStopwatch'] as Stopwatch?;
        stopwatch?.stop();

        AppLogger.apiResponse(
          method: response.requestOptions.method,
          path: response.requestOptions.path,
          statusCode: response.statusCode ?? 0,
          durationMs: stopwatch?.elapsedMilliseconds ?? 0,
          data: response.data,
        );

        handler.next(response);
      },
      onError: (error, handler) async {
        final stopwatch = error.requestOptions.extra['loggerStopwatch'] as Stopwatch?;
        stopwatch?.stop();

        final isConnectionIssue =
            error.response == null &&
            (error.type == DioExceptionType.connectionError ||
                error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.sendTimeout ||
                error.type == DioExceptionType.unknown);

        if (isConnectionIssue) {
          AppLogger.warning(
            'API connection unavailable',
            data: {
              'method': error.requestOptions.method,
              'path': error.requestOptions.path,
              'durationMs': stopwatch?.elapsedMilliseconds ?? 0,
            },
            error: error,
            stackTrace: error.stackTrace,
          );
        } else if (error.response?.statusCode == 401) {
          AppLogger.warning(
            'API unauthorized',
            data: {
              'method': error.requestOptions.method,
              'path': error.requestOptions.path,
              'statusCode': error.response?.statusCode,
              'durationMs': stopwatch?.elapsedMilliseconds ?? 0,
            },
            error: error,
            stackTrace: error.stackTrace,
          );
        } else if (error.response?.statusCode == 429) {
          AppLogger.warning(
            'API rate limited',
            data: {
              'method': error.requestOptions.method,
              'path': error.requestOptions.path,
              'statusCode': error.response?.statusCode,
              'durationMs': stopwatch?.elapsedMilliseconds ?? 0,
            },
          );
        } else {
          AppLogger.apiError(
            method: error.requestOptions.method,
            path: error.requestOptions.path,
            statusCode: error.response?.statusCode,
            durationMs: stopwatch?.elapsedMilliseconds ?? 0,
            error: error,
            stackTrace: error.stackTrace,
            data: error.response?.data,
          );
        }

        if (error.response?.statusCode == 401) {
          // If already retried or no session exists, sign out and let splash handle redirect
          if (error.requestOptions.extra['authRetry'] == true) {
            await Supabase.instance.client.auth.signOut();
            handler.next(error);
            return;
          }

          final currentSession = Supabase.instance.client.auth.currentSession;
          if (currentSession == null) {
            // No session at all — sign out cleanly and propagate
            await Supabase.instance.client.auth.signOut();
            handler.next(error);
            return;
          }

          // Attempt token refresh
          try {
            final refreshed = await Supabase.instance.client.auth.refreshSession();
            final refreshedToken = refreshed.session?.accessToken;
            if (refreshedToken != null) {
              error.requestOptions.extra['authRetry'] = true;
              error.requestOptions.headers['Authorization'] = 'Bearer $refreshedToken';
              AppLogger.authEvent('token_refreshed', data: {
                'method': error.requestOptions.method,
                'path': error.requestOptions.path,
              });
              final response = await dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (refreshError, stackTrace) {
            AppLogger.error(
              'Supabase session refresh failed',
              error: refreshError,
              stackTrace: stackTrace,
              data: {
                'method': error.requestOptions.method,
                'path': error.requestOptions.path,
              },
            );
            // Refresh failed — sign out so router redirects to login
            await Supabase.instance.client.auth.signOut();
          }

          handler.next(error);
          return;
        }

        handler.next(error);
      },
    ),
  );

  return dio;
});
