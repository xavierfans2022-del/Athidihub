import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/features/maintenance/data/maintenance_repository.dart';

class MaintenanceState {
  final bool isLoading;
  final String? error;

  MaintenanceState({
    this.isLoading = false,
    this.error,
  });

  MaintenanceState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return MaintenanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MaintenanceNotifier extends StateNotifier<MaintenanceState> {
  final MaintenanceRepository _repo;

  MaintenanceNotifier(this._repo) : super(MaintenanceState());

  Future<bool> createRequest(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repo.createRequest(data);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final maintenanceNotifierProvider =
    StateNotifierProvider<MaintenanceNotifier, MaintenanceState>((ref) {
  return MaintenanceNotifier(ref.read(maintenanceRepositoryProvider));
});
