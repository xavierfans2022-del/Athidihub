import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';
import 'package:athidihub/features/rooms/data/models/room_model.dart';
import 'package:athidihub/features/rooms/providers/room_provider.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const RoomsScreen({super.key, required this.propertyId});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  static const _roomTypes = ['All', 'SINGLE', 'DOUBLE', 'TRIPLE', 'QUAD', 'DORMITORY'];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent * 0.8) {
      ref.read(roomListProvider(widget.propertyId).notifier).fetchMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(roomListProvider(widget.propertyId).notifier).setSearch(value.trim());
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    ref.read(roomListProvider(widget.propertyId).notifier).setSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomListProvider(widget.propertyId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        title: const Text('Rooms'),
        actions: [
          RefreshButton(
            label: 'Refresh',
            onRefresh: () async {
              ref.invalidate(roomListProvider(widget.propertyId));
            },
          ),
          if (!state.isLoading && state.error == null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: colorScheme.primary.withAlpha(30), borderRadius: BorderRadius.circular(100)),
                  child: Text(
                    '${state.items.length}${state.hasMore ? '+' : ''}',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary),
                  ),
                ),
              ),
            ),
          IconButton(icon: const Icon(Icons.add_rounded), tooltip: 'Add Room', onPressed: () => context.push('/properties/${widget.propertyId}/rooms/add')),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filters ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchCtrl,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by room number or type...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: Icon(Icons.close_rounded, size: 16, color: colorScheme.onSurfaceVariant), onPressed: _clearSearch)
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 10),

                // Room type chips + AC toggle
                Row(
                  children: [
                    // Room type scroll
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _roomTypes.map((type) {
                            final value = type == 'All' ? 'all' : type;
                            final selected = state.roomType == value;
                            return GestureDetector(
                              onTap: () => ref.read(roomListProvider(widget.propertyId).notifier).setRoomType(value),
                              child: AnimatedContainer(
                                duration: AppConstants.animFast,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: selected ? colorScheme.primary : colorScheme.outline),
                                ),
                                child: Text(type, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // AC toggle
                    _ACToggle(
                      value: state.isAC,
                      onChanged: (v) => ref.read(roomListProvider(widget.propertyId).notifier).setAC(v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, RoomListState state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading && state.items.isEmpty) return _RoomListSkeleton();
    if (state.error != null && state.items.isEmpty) return _buildError(context, state.error!);
    if (!state.isLoading && state.items.isEmpty) return _buildEmpty(context);

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: () => ref.read(roomListProvider(widget.propertyId).notifier).refresh(),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: state.items.length + 1,
        itemBuilder: (context, index) {
          if (index == state.items.length) return _buildFooter(context, state);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRoomCard(context, state.items[index]),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context, RoomListState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (state.isFetchingMore) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2)));
    }
    if (!state.hasMore && state.items.isNotEmpty) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('All ${state.items.length} rooms loaded', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))));
    }
    return const SizedBox(height: 8);
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final beds = room.beds ?? [];
    final occupied = beds.where((b) => b.status.toUpperCase() == 'OCCUPIED').length;
    final available = beds.where((b) => b.status.toUpperCase() == 'AVAILABLE').length;
    final occupancyPct = beds.isEmpty ? 0.0 : occupied / beds.length;

    return Container(
      decoration: BoxDecoration(color: colorScheme.surface, border: Border.all(color: colorScheme.outline), borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/properties/${room.propertyId}/rooms/${room.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Room icon
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: colorScheme.primary.withAlpha(26), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.meeting_room_rounded, size: 20, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Room ${room.roomNumber}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${room.roomType} • Floor ${room.floorNumber}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  // AC badge
                  if (room.isAC)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.info.withAlpha(30), borderRadius: BorderRadius.circular(100)),
                      child: const Text('AC', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.info, letterSpacing: 0.3)),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(child: const Text('Edit'), onTap: () => context.push('/properties/${room.propertyId}/rooms/${room.id}/edit', extra: room)),
                      PopupMenuItem(child: const Text('Delete'), onTap: () => _showDeleteDialog(context, room.id)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: colorScheme.outline),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildMeta(context, '₹${room.monthlyRent.toStringAsFixed(0)}', 'Rent/mo'),
                  _buildMeta(context, '${room.capacity}', 'Capacity'),
                  _buildMeta(context, '$available avail.', 'Beds'),
                  // Occupancy bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${(occupancyPct * 100).toStringAsFixed(0)}%', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: occupancyPct,
                            minHeight: 4,
                            backgroundColor: colorScheme.outline,
                            valueColor: AlwaysStoppedAnimation(occupancyPct > 0.8 ? AppColors.error : occupancyPct > 0.5 ? AppColors.warning : AppColors.success),
                          ),
                        ),
                        Text('Occupancy', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeta(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Failed to load rooms', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(msg, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              onPressed: () => ref.read(roomListProvider(widget.propertyId).notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.read(roomListProvider(widget.propertyId));
    final isFiltering = _searchCtrl.text.isNotEmpty || state.roomType != 'all' || state.isAC != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isFiltering ? Icons.search_off_rounded : Icons.meeting_room_outlined, size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(isFiltering ? 'No results found' : 'No rooms yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              isFiltering ? 'Try a different search or filter' : 'Add a room to get started',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!isFiltering)
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Room'),
                onPressed: () => context.push('/properties/${widget.propertyId}/rooms/add'),
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('Clear filters'),
                onPressed: () {
                  _clearSearch();
                  ref.read(roomListProvider(widget.propertyId).notifier).setRoomType('all');
                  ref.read(roomListProvider(widget.propertyId).notifier).setAC(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, String roomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text('Are you sure? All beds in this room will also be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(deleteRoomProvider(roomId).future);
      if (mounted) {
        ref.read(roomListProvider(widget.propertyId).notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room deleted successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ── AC Toggle widget ──────────────────────────────────────────────────────────

class _ACToggle extends StatelessWidget {
  final bool? value; // null = all, true = AC, false = Non-AC
  final ValueChanged<bool?> onChanged;

  const _ACToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = value != null;

    return GestureDetector(
      onTap: () {
        if (value == null) onChanged(true);
        else if (value == true) onChanged(false);
        else onChanged(null);
      },
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? (value == true ? AppColors.info.withAlpha(38) : colorScheme.onSurfaceVariant.withAlpha(30)) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isActive ? (value == true ? AppColors.info : colorScheme.onSurfaceVariant) : colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ac_unit_rounded, size: 12, color: isActive ? (value == true ? AppColors.info : colorScheme.onSurfaceVariant) : colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              value == null ? 'AC' : value == true ? 'AC' : 'Non-AC',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? (value == true ? AppColors.info : colorScheme.onSurfaceVariant) : colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _RoomListSkeleton extends StatefulWidget {
  @override
  State<_RoomListSkeleton> createState() => _RoomListSkeletonState();
}

class _RoomListSkeletonState extends State<_RoomListSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = isDark ? Colors.white.withAlpha(20) : Colors.white.withAlpha(191);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final dx = bounds.width * (_ctrl.value * 3 - 1);
          return LinearGradient(colors: [base, highlight, base], stops: const [0.0, 0.5, 1.0]).createShader(bounds.shift(Offset(-dx, 0)));
        },
        child: child,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCardSkeleton(context),
        ),
      ),
    );
  }

  Widget _buildCardSkeleton(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(width: 90, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: color),
          const SizedBox(height: 14),
          Row(
            children: List.generate(4, (_) => Expanded(
              child: Container(height: 28, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
            )),
          ),
        ],
      ),
    );
  }
}
