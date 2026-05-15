import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:athidihub/core/network/dio_provider.dart';
import 'package:athidihub/features/tenant_portal/data/models/tenant_portal_models.dart';

// ─── Role Detection ───────────────────────────────────────────────────────────
// Returns the raw tenant record if the current user IS a tenant, else null.
final currentTenantProvider = FutureProvider<TenantInfo?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/tenant-portal/me');
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      return TenantInfo.fromJson(data);
    }
    return null;
  } on DioException catch (e) {
    // 404 / 403 → user is not a tenant
    if (e.response?.statusCode == 404 || e.response?.statusCode == 403) {
      return null;
    }
    return null;
  }
});

// ─── Dashboard ────────────────────────────────────────────────────────────────
final tenantDashboardProvider = FutureProvider<TenantDashboard?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/tenant-portal/me/dashboard');
    if (response.statusCode == 200) {
      return TenantDashboard.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  } on DioException {
    return null;
  }
});

// ─── Invoice Month Filter State ───────────────────────────────────────────────
class InvoiceFilter {
  final int? month;
  final int? year;
  const InvoiceFilter({this.month, this.year});
}

final invoiceFilterProvider = StateProvider<InvoiceFilter>((_) => const InvoiceFilter());

// ─── Invoices ─────────────────────────────────────────────────────────────────
final tenantInvoicesProvider = FutureProvider<PaginatedInvoices>((ref) async {
  final dio = ref.watch(dioProvider);
  final filter = ref.watch(invoiceFilterProvider);

  final queryParams = <String, dynamic>{};
  if (filter.month != null) queryParams['month'] = filter.month;
  if (filter.year != null) queryParams['year'] = filter.year;

  try {
    final response = await dio.get(
      '/tenant-portal/me/invoices',
      queryParameters: queryParams,
    );
    return PaginatedInvoices.fromJson(response.data as Map<String, dynamic>);
  } on DioException {
    return const PaginatedInvoices(data: [], total: 0, page: 1, hasMore: false);
  }
});

// ─── Payment History Month Filter State ───────────────────────────────────────
final paymentFilterProvider = StateProvider<InvoiceFilter>((_) => const InvoiceFilter());

// ─── Payment History ──────────────────────────────────────────────────────────
final tenantPaymentsProvider = FutureProvider<PaginatedPayments>((ref) async {
  final dio = ref.watch(dioProvider);
  final filter = ref.watch(paymentFilterProvider);

  final queryParams = <String, dynamic>{};
  if (filter.month != null) queryParams['month'] = filter.month;
  if (filter.year != null) queryParams['year'] = filter.year;

  try {
    final response = await dio.get(
      '/tenant-portal/me/payments',
      queryParameters: queryParams,
    );
    return PaginatedPayments.fromJson(response.data as Map<String, dynamic>);
  } on DioException {
    return const PaginatedPayments(data: [], total: 0, page: 1, hasMore: false);
  }
});

// ─── Aadhaar Upload Notifier ──────────────────────────────────────────────────
class AadhaarNotifier extends StateNotifier<AsyncValue<void>> {
  AadhaarNotifier(this._dio) : super(const AsyncValue.data(null));

  final Dio _dio;

  Future<void> submit(String aadhaarUrl) async {
    state = const AsyncValue.loading();
    try {
      await _dio.patch('/tenant-portal/me/aadhaar', data: {'aadhaarUrl': aadhaarUrl});
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDocument() async {
    state = const AsyncValue.loading();
    try {
      await _dio.delete('/tenant-portal/me/aadhaar');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> getDigiLockerUrl() async {
    state = const AsyncValue.loading();
    try {
      final res = await _dio.get('/tenant-portal/me/digilocker/initiate');
      state = const AsyncValue.data(null);
      return res.data['url'] as String?;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> verifyDigiLocker(String code, String authState) async {
    state = const AsyncValue.loading();
    try {
      await _dio.post('/tenant-portal/me/digilocker/verify', data: {
        'code': code,
        'state': authState,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final aadhaarNotifierProvider =
    StateNotifierProvider<AadhaarNotifier, AsyncValue<void>>((ref) {
  return AadhaarNotifier(ref.watch(dioProvider));
});

// ─── Check-in Notifier ────────────────────────────────────────────────────────
class CheckInNotifier extends StateNotifier<AsyncValue<void>> {
  CheckInNotifier(this._dio) : super(const AsyncValue.data(null));

  final Dio _dio;

  Future<void> completeCheckIn() async {
    state = const AsyncValue.loading();
    try {
      await _dio.post('/tenant-portal/me/checkin');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final checkInNotifierProvider =
    StateNotifierProvider<CheckInNotifier, AsyncValue<void>>((ref) {
  return CheckInNotifier(ref.watch(dioProvider));
});

// ─── Profile Update Notifier ──────────────────────────────────────────────────
class TenantProfileNotifier extends StateNotifier<AsyncValue<void>> {
  TenantProfileNotifier(this._dio) : super(const AsyncValue.data(null));

  final Dio _dio;

  Future<void> update(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _dio.patch('/tenant-portal/me/profile', data: data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final tenantProfileNotifierProvider =
    StateNotifierProvider<TenantProfileNotifier, AsyncValue<void>>((ref) {
  return TenantProfileNotifier(ref.watch(dioProvider));
});
