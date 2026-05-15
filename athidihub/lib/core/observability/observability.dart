import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class Observability {
  Observability._();

  static final Dio _dio = Dio();
  static bool _initialized = false;

  // GA4 Measurement Protocol settings (set via initialize)
  static String? measurementId;
  static String? apiSecret;

  static Future<void> initialize({String? gaMeasurementId, String? gaApiSecret}) async {
    if (_initialized) return;
    measurementId = gaMeasurementId;
    apiSecret = gaApiSecret;
    _initialized = true;

    // Nothing to initialize for now. Crash reporting can be forwarded to backend via `errorReportingUrl`.
  }

  static Future<void> setUserId(String? userId) async {
    try {
      // Optionally store user id for local context; backend forwarding may include it per-event.
    } catch (_) {}
  }

  static Future<void> logEvent(String name, Map<String, dynamic>? params, {String? userId}) async {
    if (measurementId == null || apiSecret == null) return;
    final url = 'https://www.google-analytics.com/mp/collect?measurement_id=$measurementId&api_secret=$apiSecret';
    final payload = {
      'client_id': userId ?? 'anonymous',
      'events': [
        {
          'name': name,
          'params': params ?? {},
        }
      ]
    };

    try {
      await _dio.post(url, data: jsonEncode(payload), options: Options(headers: {'Content-Type': 'application/json'}));
    } catch (_) {
      // best-effort
    }
  }

  static Future<void> logError(Object error, StackTrace? stack, {String? errorReportingUrl, String? userId}) async {
    // Best-effort: send non-fatal error to configured backend endpoint for aggregation.
    if (errorReportingUrl == null) {
      // fallback to printing
      // ignore: avoid_print
      print('Error: $error');
      return;
    }

    final payload = {
      'error': error.toString(),
      'stack': stack?.toString(),
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await _dio.post(errorReportingUrl, data: jsonEncode(payload), options: Options(headers: {'Content-Type': 'application/json'}));
    } catch (_) {
      // swallow
    }
  }
}
