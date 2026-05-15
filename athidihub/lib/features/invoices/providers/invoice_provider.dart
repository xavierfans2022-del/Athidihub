import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:athidihub/core/network/dio_provider.dart';
import 'package:athidihub/features/dashboard/providers/dashboard_provider.dart';
import 'package:athidihub/features/invoices/data/models/invoice_model.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(ref.watch(dioProvider));
});

// ── Paginated invoice list state ──────────────────────────────────────────────

class InvoiceListState {
  final List<InvoiceModel> items;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final int currentPage;
  final String search;
  final String status; // 'ALL' | 'PENDING' | 'PAID' | 'OVERDUE'
  final int? filterMonth;
  final int? filterYear;
  final String? error;

  const InvoiceListState({
    this.items = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.search = '',
    this.status = 'ALL',
    this.filterMonth,
    this.filterYear,
    this.error,
  });

  InvoiceListState copyWith({
    List<InvoiceModel>? items,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    int? currentPage,
    String? search,
    String? status,
    Object? filterMonth = _sentinel,
    Object? filterYear = _sentinel,
    String? error,
    bool clearError = false,
  }) {
    return InvoiceListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      search: search ?? this.search,
      status: status ?? this.status,
      filterMonth: filterMonth == _sentinel ? this.filterMonth : filterMonth as int?,
      filterYear: filterYear == _sentinel ? this.filterYear : filterYear as int?,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

const _sentinel = Object();

class InvoiceListNotifier extends StateNotifier<InvoiceListState> {
  final InvoiceRepository _repo;
  final String? organizationId;
  static const _limit = 20;

  InvoiceListNotifier(this._repo, this.organizationId) : super(const InvoiceListState()) {
    fetch();
  }

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: refresh ? [] : state.items,
      currentPage: 0,
      hasMore: true,
    );
    try {
      final page = await _repo.getInvoices(
        organizationId: organizationId,
        status: state.status == 'ALL' ? null : state.status,
        search: state.search.isEmpty ? null : state.search,
        month: state.filterMonth,
        year: state.filterYear,
        page: 1,
        limit: _limit,
      );
      state = state.copyWith(
        items: page.data,
        isLoading: false,
        hasMore: page.hasMore,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMore() async {
    if (state.isFetchingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isFetchingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final page = await _repo.getInvoices(
        organizationId: organizationId,
        status: state.status == 'ALL' ? null : state.status,
        search: state.search.isEmpty ? null : state.search,
        month: state.filterMonth,
        year: state.filterYear,
        page: nextPage,
        limit: _limit,
      );
      state = state.copyWith(
        items: [...state.items, ...page.data],
        isFetchingMore: false,
        hasMore: page.hasMore,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isFetchingMore: false, error: e.toString());
    }
  }

  void setSearch(String q) {
    if (q == state.search) return;
    state = state.copyWith(search: q);
    fetch(refresh: true);
  }

  void setStatus(String s) {
    if (s == state.status) return;
    state = state.copyWith(status: s);
    fetch(refresh: true);
  }

  void setMonthYear(int? month, int? year) {
    state = state.copyWith(filterMonth: month, filterYear: year);
    fetch(refresh: true);
  }

  void clearFilters() {
    state = state.copyWith(
      search: '',
      status: 'ALL',
      filterMonth: null,
      filterYear: null,
    );
    fetch(refresh: true);
  }

  Future<void> refresh() => fetch(refresh: true);
}

final invoiceListProvider = StateNotifierProvider<InvoiceListNotifier, InvoiceListState>((ref) {
  final orgId = ref.watch(selectedOrganizationIdProvider).value;
  return InvoiceListNotifier(ref.read(invoiceRepositoryProvider), orgId);
});

// ── Simple status-filtered provider (kept for payment screen invalidation) ────
final invoicesProvider = FutureProvider.family<List<InvoiceModel>, String>((ref, status) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  final page = await repo.getInvoices(status: status == 'ALL' ? null : status, limit: 100);
  return page.data;
});

final tenantInvoicesProvider = FutureProvider.family<List<InvoiceModel>, String>((ref, tenantId) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  final page = await repo.getInvoices(tenantId: tenantId, limit: 100);
  return page.data;
});

// ── Repository ────────────────────────────────────────────────────────────────

class InvoicePage {
  final List<InvoiceModel> data;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  InvoicePage({required this.data, required this.total, required this.page, required this.limit, required this.hasMore});

  factory InvoicePage.fromJson(Map<String, dynamic> json) {
    final raw = json['data'] as List? ?? [];
    return InvoicePage(
      data: raw.map((j) => InvoiceModel.fromJson(j as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class InvoiceRepository {
  final Dio _dio;
  InvoiceRepository(this._dio);

  Future<InvoicePage> getInvoices({
    String? organizationId,
    String? tenantId,
    String? status,
    String? search,
    int? month,
    int? year,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('/invoices', queryParameters: {
      if (organizationId != null) 'organizationId': organizationId,
      if (tenantId != null) 'tenantId': tenantId,
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      'page': page,
      'limit': limit,
    });
    return InvoicePage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<InvoiceModel> generateInvoice({
    required String tenantId,
    required int month,
    required int year,
    double utilityCharges = 0,
    double foodCharges = 0,
    double lateFee = 0,
    double discount = 0,
  }) async {
    final response = await _dio.post('/invoices/generate', data: {
      'tenantId': tenantId,
      'month': month,
      'year': year,
      if (utilityCharges > 0) 'utilityCharges': utilityCharges,
      if (foodCharges > 0) 'foodCharges': foodCharges,
      if (lateFee > 0) 'lateFee': lateFee,
      if (discount > 0) 'discount': discount,
    });
    return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> generateBulk({
    required String organizationId,
    required int month,
    required int year,
  }) async {
    final response = await _dio.post('/invoices/generate-bulk', data: {
      'organizationId': organizationId,
      'month': month,
      'year': year,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<InvoiceModel> getInvoiceById(String id) async {
    final response = await _dio.get('/invoices/$id');
    return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final invoiceDetailProvider = FutureProvider.family<InvoiceModel, String>((ref, id) async {
  return ref.watch(invoiceRepositoryProvider).getInvoiceById(id);
});
