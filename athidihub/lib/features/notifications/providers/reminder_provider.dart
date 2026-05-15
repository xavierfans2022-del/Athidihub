import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/network/dio_provider.dart';
import '../data/reminder_repository.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ReminderRepository(dio);
});

final reminderStateProvider = StateNotifierProvider<ReminderNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return ReminderNotifier(repo);
});

class ReminderNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final ReminderRepository _repo;

  ReminderNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> sendBulkReminders({
    required String organizationId,
    int daysAhead = 3,
    bool includeOverdue = true,
    String? customMessage,
    bool force = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.sendBulkReminders(
        organizationId: organizationId,
        daysAhead: daysAhead,
        includeOverdue: includeOverdue,
        customMessage: customMessage,
        force: force,
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
