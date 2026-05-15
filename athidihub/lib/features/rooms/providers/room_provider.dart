import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:athidihub/core/network/dio_provider.dart';
import 'package:athidihub/features/rooms/data/models/room_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(ref.watch(dioProvider));
});

class RoomPage {
  final List<RoomModel> data;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const RoomPage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory RoomPage.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List? ?? [];
    return RoomPage(
      data: rawData.map((j) => RoomModel.fromJson(j as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class RoomRepository {
  final Dio _dio;
  RoomRepository(this._dio);

  Future<RoomPage> getRooms({
    required String propertyId,
    String? search,
    String? roomType,
    bool? isAC,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('/rooms', queryParameters: {
      'propertyId': propertyId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (roomType != null && roomType != 'all') 'roomType': roomType,
      if (isAC != null) 'isAC': isAC.toString(),
      'page': page,
      'limit': limit,
    });
    return RoomPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoomModel> getRoom(String roomId) async {
    final response = await _dio.get('/rooms/$roomId');
    return RoomModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoomModel> createRoom(Map<String, dynamic> data) async {
    final response = await _dio.post('/rooms', data: data);
    return RoomModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoomModel> updateRoom(String roomId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/rooms/$roomId', data: data);
    return RoomModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRoom(String roomId) async {
    await _dio.delete('/rooms/$roomId');
  }
}

// ── Pagination state ──────────────────────────────────────────────────────────

class RoomListState {
  final List<RoomModel> items;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final int currentPage;
  final String search;
  final String roomType; // 'all' | 'SINGLE' | 'DOUBLE' etc.
  final bool? isAC;      // null = all, true = AC, false = Non-AC
  final String? error;

  const RoomListState({
    this.items = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.search = '',
    this.roomType = 'all',
    this.isAC,
    this.error,
  });

  RoomListState copyWith({
    List<RoomModel>? items,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    int? currentPage,
    String? search,
    String? roomType,
    Object? isAC = _sentinel,
    String? error,
    bool clearError = false,
  }) {
    return RoomListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      search: search ?? this.search,
      roomType: roomType ?? this.roomType,
      isAC: isAC == _sentinel ? this.isAC : isAC as bool?,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Sentinel for nullable isAC copyWith
const _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────────────────────────

class RoomListNotifier extends StateNotifier<RoomListState> {
  final RoomRepository _repo;
  final String propertyId;
  static const _limit = 20;

  RoomListNotifier(this._repo, this.propertyId) : super(const RoomListState()) {
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
      final page = await _repo.getRooms(
        propertyId: propertyId,
        search: state.search,
        roomType: state.roomType == 'all' ? null : state.roomType,
        isAC: state.isAC,
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
      final page = await _repo.getRooms(
        propertyId: propertyId,
        search: state.search,
        roomType: state.roomType == 'all' ? null : state.roomType,
        isAC: state.isAC,
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

  void setRoomType(String type) {
    if (type == state.roomType) return;
    state = state.copyWith(roomType: type);
    fetch(refresh: true);
  }

  void setAC(bool? ac) {
    if (ac == state.isAC) return;
    state = state.copyWith(isAC: ac);
    fetch(refresh: true);
  }

  Future<void> refresh() => fetch(refresh: true);
}

// Family provider — one notifier per propertyId
final roomListProvider = StateNotifierProvider.family<RoomListNotifier, RoomListState, String>(
  (ref, propertyId) => RoomListNotifier(ref.read(roomRepositoryProvider), propertyId),
);

// ── Legacy providers (kept for detail/add/edit/bed screens) ──────────────────

final propertyRoomsProvider = FutureProvider.family<List<RoomModel>, String>((ref, propertyId) async {
  final page = await ref.read(roomRepositoryProvider).getRooms(propertyId: propertyId, limit: 100);
  return page.data;
});

final roomDetailProvider = FutureProvider.family<RoomModel, String>((ref, roomId) async {
  return ref.watch(roomRepositoryProvider).getRoom(roomId);
});

final createRoomProvider = FutureProvider.family<RoomModel, Map<String, dynamic>>((ref, data) async {
  return ref.watch(roomRepositoryProvider).createRoom(data);
});

final updateRoomProvider = FutureProvider.family<RoomModel, (String, Map<String, dynamic>)>((ref, params) async {
  return ref.watch(roomRepositoryProvider).updateRoom(params.$1, params.$2);
});

final deleteRoomProvider = FutureProvider.family<void, String>((ref, roomId) async {
  await ref.watch(roomRepositoryProvider).deleteRoom(roomId);
});
