import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/beds/data/models/bed_model.dart';
import 'package:athidihub/features/beds/providers/bed_provider.dart';
import 'package:athidihub/features/rooms/providers/room_provider.dart';
import 'package:athidihub/features/rooms/data/models/room_model.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';
import 'package:go_router/go_router.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final bedsAsync = ref.watch(bedsByRoomProvider(widget.roomId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        title: const Text('Room Detail'),
        actions: [
          RefreshButton(
            label: 'Refresh',
            onRefresh: () async {
              ref.invalidate(roomDetailProvider(widget.roomId));
              ref.invalidate(bedsByRoomProvider(widget.roomId));
              await Future.wait([
                ref.read(roomDetailProvider(widget.roomId).future),
                ref.read(bedsByRoomProvider(widget.roomId).future),
              ]);
            },
          ),
          roomAsync.whenData((room) {
            return PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(child: const Text('Edit'), onTap: () => _editRoom(room)),
                PopupMenuItem(child: const Text('Delete'), onTap: () => _showDeleteDialog(context, room.id)),
              ],
            );
          }).value ?? const SizedBox(),
        ],
      ),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: colorScheme.error))),
        data: (room) => bedsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: colorScheme.error))),
          data: (beds) {
            final counts = _bedCounts(beds);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoomHeader(context, room),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildStat(context, 'Vacant', '${counts.vacant}', AppColors.bedAvailable)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStat(context, 'Occupied', '${counts.occupied}', AppColors.bedOccupied)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStat(context, 'Maint.', '${counts.maintenance}', AppColors.bedMaintenance)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12, runSpacing: 8,
                    children: [
                      Text('Beds', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Bed'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        onPressed: () => _addBed(room.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (beds.isEmpty)
                    Text('No beds found for this room', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))
                  else
                    Column(children: beds.map((bed) => _buildBedCard(context, bed)).toList()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  ({int vacant, int occupied, int maintenance}) _bedCounts(List<BedModel> beds) {
    var vacant = 0; var occupied = 0; var maintenance = 0;
    for (final bed in beds) {
      switch (bed.status.toUpperCase()) {
        case 'AVAILABLE': vacant++; break;
        case 'OCCUPIED': occupied++; break;
        case 'MAINTENANCE': maintenance++; break;
      }
    }
    return (vacant: vacant, occupied: occupied, maintenance: maintenance);
  }

  Widget _buildRoomHeader(BuildContext context, RoomModel room) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Room ${room.roomNumber}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('${room.roomType} • Floor ${room.floorNumber}', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text('₹${room.monthlyRent.toStringAsFixed(0)} • ${room.isAC ? 'AC' : 'Non-AC'}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colorScheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildBedCard(BuildContext context, BedModel bed) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = bed.status.toUpperCase();
    final statusColor = switch (status) {
      'AVAILABLE' => AppColors.bedAvailable,
      'OCCUPIED' => AppColors.bedOccupied,
      'MAINTENANCE' => AppColors.bedMaintenance,
      _ => colorScheme.onSurfaceVariant,
    };

    return GestureDetector(
      onTap: () => context.push('/beds/${bed.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.outline)),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(status == 'OCCUPIED' ? Icons.person_rounded : status == 'MAINTENANCE' ? Icons.build_rounded : Icons.bed_rounded, color: statusColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bed ${bed.bedNumber}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(bed.occupantLabel, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(100)),
              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBed(String roomId) async {
    final room = ref.read(roomDetailProvider(roomId)).value;
    if (room == null) return;
    context.push('/properties/${room.propertyId}/rooms/$roomId/add-bed');
  }

  Future<void> _editRoom(RoomModel room) async => context.push('/properties/${room.propertyId}/rooms/${room.id}/edit', extra: room);

  Future<void> _showDeleteDialog(BuildContext context, String roomId) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text('Are you sure you want to delete this room? All associated beds will also be deleted. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () { _deleteRoom(roomId); Navigator.pop(context); },
            child: const Text('Delete', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom(String roomId) async {
    try {
      await ref.read(deleteRoomProvider(roomId).future);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room deleted successfully'))); context.pop(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
