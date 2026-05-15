import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/network/dio_provider.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(ref.watch(dioProvider));
});

class BedRentInfo {
  final double monthlyRent;
  final double securityDeposit;
  final String roomNumber;
  final String roomType;

  BedRentInfo({
    required this.monthlyRent,
    required this.securityDeposit,
    required this.roomNumber,
    required this.roomType,
  });

  factory BedRentInfo.fromJson(Map<String, dynamic> json) => BedRentInfo(
        monthlyRent: (json['monthlyRent'] as num).toDouble(),
        securityDeposit: (json['securityDeposit'] as num).toDouble(),
        roomNumber: json['roomNumber'] as String,
        roomType: json['roomType'] as String,
      );
}

class AssignmentRepository {
  final Dio _dio;
  AssignmentRepository(this._dio);

  Future<BedRentInfo> getBedRentInfo(String bedId) async {
    final response = await _dio.get('/assignments/bed-rent/$bedId');
    return BedRentInfo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> assignBed({
    required String tenantId,
    required String bedId,
    double? monthlyRent,
    double? securityDeposit,
  }) async {
    await _dio.post('/assignments', data: {
      'tenantId': tenantId,
      'bedId': bedId,
      'startDate': DateTime.now().toIso8601String(),
      if (monthlyRent != null) 'monthlyRent': monthlyRent,
      if (securityDeposit != null) 'securityDeposit': securityDeposit,
    });
  }

  Future<void> updateAssignment(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _dio.patch('/assignments/$id', data: data);
  }
}

// Fetches room rent info when a bed is selected
final bedRentInfoProvider = FutureProvider.family<BedRentInfo, String>((ref, bedId) async {
  return ref.read(assignmentRepositoryProvider).getBedRentInfo(bedId);
});

class TenantBedAssignmentState {
  final bool isLoading;
  final String? error;

  TenantBedAssignmentState({this.isLoading = false, this.error});

  TenantBedAssignmentState copyWith({bool? isLoading, String? error}) =>
      TenantBedAssignmentState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class TenantBedAssignmentNotifier extends StateNotifier<TenantBedAssignmentState> {
  final AssignmentRepository _repo;

  TenantBedAssignmentNotifier(this._repo) : super(TenantBedAssignmentState());

  Future<bool> assignBed({
    required String tenantId,
    required String bedId,
    double? monthlyRent,
    double? securityDeposit,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repo.assignBed(
        tenantId: tenantId,
        bedId: bedId,
        monthlyRent: monthlyRent,
        securityDeposit: securityDeposit,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final tenantBedAssignmentProvider =
    StateNotifierProvider<TenantBedAssignmentNotifier, TenantBedAssignmentState>((ref) {
  return TenantBedAssignmentNotifier(ref.read(assignmentRepositoryProvider));
});

class AssignmentEditState {
  final bool isLoading;
  final String? error;

  const AssignmentEditState({this.isLoading = false, this.error});

  AssignmentEditState copyWith({bool? isLoading, String? error}) {
    return AssignmentEditState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AssignmentEditNotifier extends StateNotifier<AssignmentEditState> {
  final AssignmentRepository _repo;

  AssignmentEditNotifier(this._repo) : super(const AssignmentEditState());

  Future<bool> updateAssignment(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repo.updateAssignment(id, data);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final assignmentEditProvider =
    StateNotifierProvider<AssignmentEditNotifier, AssignmentEditState>((ref) {
  return AssignmentEditNotifier(ref.read(assignmentRepositoryProvider));
});
