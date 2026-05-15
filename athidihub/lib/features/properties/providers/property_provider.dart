import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:athidihub/core/network/dio_provider.dart';
import 'package:athidihub/features/properties/data/models/property_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(ref.watch(dioProvider));
});

class PropertyPage {
  final List<PropertyModel> data;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const PropertyPage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory PropertyPage.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List? ?? [];
    return PropertyPage(
      data: rawData.map((j) => PropertyModel.fromJson(j as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class PropertyRepository {
  final Dio _dio;
  PropertyRepository(this._dio);

  Future<PropertyPage> getProperties({
    String? organizationId,
    String? search,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('/properties', queryParameters: {
      if (organizationId != null) 'organizationId': organizationId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status != 'all') 'status': status,
      'page': page,
      'limit': limit,
    });
    return PropertyPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PropertyModel> getProperty(String id) async {
    final response = await _dio.get('/properties/$id');
    return _parse(response.data);
  }

  Future<PropertyModel> createProperty(Map<String, dynamic> data) async {
    final response = await _dio.post('/properties', data: data);
    return _parse(response.data);
  }

  Future<PropertyModel> updateProperty(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/properties/$id', data: data);
    return _parse(response.data);
  }

  Future<void> deleteProperty(String id) async {
    await _dio.delete('/properties/$id');
  }

  PropertyModel _parse(dynamic raw) {
    final data = raw is String ? jsonDecode(raw) : raw;
    if (data is Map<String, dynamic>) return PropertyModel.fromJson(data);
    if (data is Map) return PropertyModel.fromJson(data.cast<String, dynamic>());
    throw Exception('Unexpected property response format');
  }
}

// ── Pagination state ──────────────────────────────────────────────────────────

class PropertyListState {
  final List<PropertyModel> items;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final int currentPage;
  final String search;
  final String status; // 'all' | 'active' | 'inactive'
  final String? error;

  const PropertyListState({
    this.items = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.search = '',
    this.status = 'all',
    this.error,
  });

  PropertyListState copyWith({
    List<PropertyModel>? items,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    int? currentPage,
    String? search,
    String? status,
    String? error,
    bool clearError = false,
  }) {
    return PropertyListState(
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

class PropertyListNotifier extends StateNotifier<PropertyListState> {
  final PropertyRepository _repo;
  static const _limit = 20;

  PropertyListNotifier(this._repo) : super(const PropertyListState()) {
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
      final page = await _repo.getProperties(
        search: state.search,
        status: state.status == 'all' ? null : state.status,
        page: 1,
        limit: _limit,
      );
      state = state.copyWith(items: page.data, isLoading: false, hasMore: page.hasMore, currentPage: 1);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMore() async {
    if (state.isFetchingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isFetchingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final page = await _repo.getProperties(
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

  void setSearch(String query) {
    if (query == state.search) return;
    state = state.copyWith(search: query);
    fetch(refresh: true);
  }

  void setStatus(String status) {
    if (status == state.status) return;
    state = state.copyWith(status: status);
    fetch(refresh: true);
  }

  Future<void> refresh() => fetch(refresh: true);
}

final propertyListProvider =
    StateNotifierProvider<PropertyListNotifier, PropertyListState>((ref) {
  return PropertyListNotifier(ref.read(propertyRepositoryProvider));
});

// ── Legacy provider (kept for detail/add/edit screens) ───────────────────────

final propertiesProvider = FutureProvider<List<PropertyModel>>((ref) async {
  final page = await ref.read(propertyRepositoryProvider).getProperties(limit: 100);
  return page.data;
});

final propertyDetailProvider = FutureProvider.family<PropertyModel, String>((ref, id) async {
  return ref.watch(propertyRepositoryProvider).getProperty(id);
});

final createPropertyProvider = FutureProvider.family<PropertyModel, Map<String, dynamic>>((ref, data) async {
  return ref.watch(propertyRepositoryProvider).createProperty(data);
});

final updatePropertyProvider = FutureProvider.family<PropertyModel, (String, Map<String, dynamic>)>((ref, params) async {
  return ref.watch(propertyRepositoryProvider).updateProperty(params.$1, params.$2);
});

final deletePropertyProvider = FutureProvider.family<void, String>((ref, id) async {
  await ref.watch(propertyRepositoryProvider).deleteProperty(id);
});
