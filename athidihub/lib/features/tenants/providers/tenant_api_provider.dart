import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/features/tenants/data/tenant_api_repository.dart';

// ── Single tenant ─────────────────────────────────────────────────────────────

final tenantDetailApiProvider = FutureProvider.family<TenantModel, String>(
  (ref, id) async => ref.read(tenantApiRepositoryProvider).getTenant(id),
);

// ── Pagination state ──────────────────────────────────────────────────────────

class TenantListState {
  final List<TenantModel> items;
  final bool isLoading;       // initial / refresh load
  final bool isFetchingMore;  // loading next page
  final bool hasMore;
  final int currentPage;
  final String search;
  final String status;        // 'all' | 'active' | 'inactive'
  final String? error;

  const TenantListState({
    this.items = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.search = '',
    this.status = 'all',
    this.error,
  });

  TenantListState copyWith({
    List<TenantModel>? items,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    int? currentPage,
    String? search,
    String? status,
    String? error,
    bool clearError = false,
  }) {
    return TenantListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      search: search ?? this.search,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class TenantListNotifier extends StateNotifier<TenantListState> {
  final TenantApiRepository _repo;
  static const _limit = 20;

  TenantListNotifier(this._repo) : super(const TenantListState()) {
    fetch();
  }

  /// Initial load or full refresh — resets page to 1
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
      final page = await _repo.getTenants(
        search: state.search,
        status: state.status == 'all' ? null : state.status,
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

  /// Load next page — appends to existing list
  Future<void> fetchMore() async {
    if (state.isFetchingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isFetchingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final page = await _repo.getTenants(
        search: state.search,
        status: state.status == 'all' ? null : state.status,
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

  /// Update search query and re-fetch from page 1
  void setSearch(String query) {
    if (query == state.search) return;
    state = state.copyWith(search: query);
    fetch(refresh: true);
  }

  /// Update status filter and re-fetch from page 1
  void setStatus(String status) {
    if (status == state.status) return;
    state = state.copyWith(status: status);
    fetch(refresh: true);
  }

  /// Pull-to-refresh
  Future<void> refresh() => fetch(refresh: true);
}

final tenantListProvider =
    StateNotifierProvider<TenantListNotifier, TenantListState>((ref) {
  return TenantListNotifier(ref.read(tenantApiRepositoryProvider));
});

// ── Legacy list provider (kept for compatibility with other screens) ───────────

final tenantsListProvider = FutureProvider<List<TenantModel>>((ref) async {
  final page = await ref.read(tenantApiRepositoryProvider).getTenants(limit: 100);
  return page.data;
});

// ── Create ────────────────────────────────────────────────────────────────────

class TenantCreateState {
  final bool isLoading;
  final String? error;
  final TenantModel? created;

  TenantCreateState({this.isLoading = false, this.error, this.created});

  TenantCreateState copyWith({bool? isLoading, String? error, TenantModel? created}) {
    return TenantCreateState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      created: created ?? this.created,
    );
  }
}

class TenantCreateNotifier extends StateNotifier<TenantCreateState> {
  final TenantApiRepository _repo;
  TenantCreateNotifier(this._repo) : super(TenantCreateState());

  Future<bool> createTenant(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final tenant = await _repo.createTenant(data);
      state = state.copyWith(isLoading: false, created: tenant);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final tenantCreateProvider =
    StateNotifierProvider<TenantCreateNotifier, TenantCreateState>((ref) {
  return TenantCreateNotifier(ref.read(tenantApiRepositoryProvider));
});

// ── Update ────────────────────────────────────────────────────────────────────

class TenantEditState {
  final bool isLoading;
  final String? error;
  TenantEditState({this.isLoading = false, this.error});
  TenantEditState copyWith({bool? isLoading, String? error}) =>
      TenantEditState(isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class TenantEditNotifier extends StateNotifier<TenantEditState> {
  final TenantApiRepository _repo;
  TenantEditNotifier(this._repo) : super(TenantEditState());

  Future<bool> updateTenant(String id, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repo.updateTenant(id, data);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final tenantEditProvider =
    StateNotifierProvider<TenantEditNotifier, TenantEditState>((ref) {
  return TenantEditNotifier(ref.read(tenantApiRepositoryProvider));
});

// ── Delete ────────────────────────────────────────────────────────────────────

class TenantDeleteState {
  final bool isLoading;
  final String? error;
  TenantDeleteState({this.isLoading = false, this.error});
  TenantDeleteState copyWith({bool? isLoading, String? error}) =>
      TenantDeleteState(isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class TenantDeleteNotifier extends StateNotifier<TenantDeleteState> {
  final TenantApiRepository _repo;
  TenantDeleteNotifier(this._repo) : super(TenantDeleteState());

  Future<bool> deleteTenant(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repo.deleteTenant(id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final tenantDeleteProvider =
    StateNotifierProvider<TenantDeleteNotifier, TenantDeleteState>((ref) {
  return TenantDeleteNotifier(ref.read(tenantApiRepositoryProvider));
});
