import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/properties/providers/property_provider.dart';
import 'package:athidihub/features/properties/data/models/property_model.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';
import 'package:go_router/go_router.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        title: const Text('Property Detail'),
        actions: [
          RefreshButton(
            label: 'Refresh',
            onRefresh: () async {
              ref.invalidate(propertyDetailProvider(widget.propertyId));
              await ref.read(propertyDetailProvider(widget.propertyId).future);
            },
          ),
          ref.watch(propertyDetailProvider(widget.propertyId)).whenData((property) {
            return PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(child: const Text('Edit'), onTap: () => _editProperty(property)),
                PopupMenuItem(child: const Text('Delete'), onTap: () => _showDeleteDialog(context, property.id)),
              ],
            );
          }).value ?? const SizedBox(),
        ],
      ),
      body: ref.watch(propertyDetailProvider(widget.propertyId)).when(
        data: (property) => _buildDetail(context, property),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: colorScheme.error))),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, PropertyModel property) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              image: property.imageUrls.isNotEmpty
                  ? DecorationImage(image: NetworkImage(property.imageUrls.first), fit: BoxFit.cover)
                  : null,
            ),
            child: property.imageUrls.isEmpty
                ? Center(child: Icon(Icons.business_rounded, size: 64, color: colorScheme.onSurfaceVariant))
                : null,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(property.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (property.isActive ? AppColors.bedAvailable : colorScheme.error).withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (property.isActive ? AppColors.bedAvailable : colorScheme.error).withAlpha(77)),
                ),
                child: Text(
                  property.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: property.isActive ? AppColors.bedAvailable : colorScheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text('${property.address}, ${property.city}, ${property.state}', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildStat(context, 'Floors', property.totalFloors.toString())),
              const SizedBox(width: 16),
              Expanded(child: _buildStat(context, 'Status', property.isActive ? 'Active' : 'Inactive')),
            ],
          ),
          const SizedBox(height: 24),
          Text('Amenities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (property.amenities.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: property.amenities.map((amenity) {
                return Chip(
                  label: Text(amenity, style: TextStyle(color: colorScheme.primary)),
                  backgroundColor: colorScheme.primary.withAlpha(26),
                  side: BorderSide.none,
                );
              }).toList(),
            )
          else
            Text('No amenities listed', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.meeting_room_rounded),
              label: const Text('View Rooms'),
              onPressed: () => context.go('/properties/${property.id}/rooms'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surface, border: Border.all(color: colorScheme.outline), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _editProperty(PropertyModel property) async {
    context.push('/properties/${property.id}/edit', extra: property);
  }

  Future<void> _showDeleteDialog(BuildContext context, String propertyId) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text('Are you sure you want to delete this property? All associated rooms and beds will also be deleted. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () { _deleteProperty(propertyId); Navigator.pop(context); },
            child: const Text('Delete', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty(String propertyId) async {
    try {
      await ref.read(deletePropertyProvider(propertyId).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property deleted successfully')));
        ref.refresh(propertiesProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
