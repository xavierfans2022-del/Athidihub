import 'package:dio/dio.dart';

class ReminderRepository {
  final Dio _dio;

  ReminderRepository(this._dio);

  Future<Map<String, dynamic>> sendBulkReminders({
    required String organizationId,
    int daysAhead = 3,
    bool includeOverdue = true,
    String? customMessage,
    bool force = false,
    bool voiceCall = false,
  }) async {
    final response = await _dio.post(
      '/notifications/reminders/bulk',
      data: {
        'organizationId': organizationId,
        'daysAhead': daysAhead,
        'includeOverdue': includeOverdue,
        'message': customMessage,
        'force': force,
        'voiceCall': voiceCall,
      },
    );
    return response.data;
  }
}
