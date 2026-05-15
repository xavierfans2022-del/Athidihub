import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/network/dio_provider.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(ref.watch(dioProvider));
});

class ReminderRepository {
  final Dio _dio;
  ReminderRepository(this._dio);

  Future<Map<String, dynamic>> sendBulkPaymentReminders({
    required String organizationId,
    int daysAhead = 3,
    bool includeOverdue = true,
    String? message,
  }) async {
    final response = await _dio.post(
      '/notifications/reminders/bulk',
      data: {
        'organizationId': organizationId,
        'daysAhead': daysAhead,
        'includeOverdue': includeOverdue,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return Map<String, dynamic>.from(data as Map);
  }
}

class ReminderSendState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? result;

  const ReminderSendState({this.isLoading = false, this.error, this.result});

  ReminderSendState copyWith({bool? isLoading, String? error, Map<String, dynamic>? result}) {
    return ReminderSendState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }
}

class ReminderSendNotifier extends StateNotifier<ReminderSendState> {
  final ReminderRepository _repo;

  ReminderSendNotifier(this._repo) : super(const ReminderSendState());

  Future<Map<String, dynamic>?> sendPaymentReminders({
    required String organizationId,
    int daysAhead = 3,
    bool includeOverdue = true,
    String? message,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _repo.sendBulkPaymentReminders(
        organizationId: organizationId,
        daysAhead: daysAhead,
        includeOverdue: includeOverdue,
        message: message,
      );
      state = state.copyWith(isLoading: false, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final reminderSendProvider = StateNotifierProvider<ReminderSendNotifier, ReminderSendState>((ref) {
  return ReminderSendNotifier(ref.read(reminderRepositoryProvider));
});
