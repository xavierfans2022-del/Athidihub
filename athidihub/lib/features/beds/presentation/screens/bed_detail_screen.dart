import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/beds/data/models/bed_model.dart';
import 'package:athidihub/features/beds/providers/bed_provider.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BedDetailScreen extends ConsumerStatefulWidget {
  final String bedId;
  const BedDetailScreen({super.key, required this.bedId});

  @override
  ConsumerState<BedDetailScreen> createState() => _BedDetailScreenState();
}

class _BedDetailScreenState extends ConsumerState<BedDetailScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final bedAsync = ref.watch(bedDetailProvider(widget.bedId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: const Text('Bed Details'),
        actions: [
          RefreshButton(
            label: 'Refresh',
            onRefresh: () async {
              ref.invalidate(bedDetailProvider(widget.bedId));
              await ref.read(bedDetailProvider(widget.bedId).future);
            },
          ),
          bedAsync.whenData((bed) {
            return PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(child: const Text('Edit Status'), onTap: () => _showStatusDialog(context, bed)),
                PopupMenuItem(child: const Text('Delete'), onTap: () => _showDeleteDialog(context, bed.id)),
              ],
            );
          }).value ?? const SizedBox(),
        ],
      ),
      body: bedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: colorScheme.error), textAlign: TextAlign.center)),
        data: (bed) => _buildDetail(context, bed),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, BedModel bed) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final assignment = bed.activeAssignment;
    final tenant = assignment?.tenantDetails;
    final hasAssignment = assignment != null && assignment.isActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBedHeader(context, bed),
          const SizedBox(height: 24),
          if (hasAssignment && tenant != null) ...[
            Text('Tenant Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildTenantCard(context, tenant),
            const SizedBox(height: 24),
            Text('Payment History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (tenant.invoices.isEmpty)
              Text('No payment history available', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))
            else
              Column(children: tenant.invoices.map((inv) => _buildPaymentCard(context, inv)).toList()),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bedAvailable.withAlpha(26),                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.bedAvailable.withAlpha(77)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outlined, color: AppColors.bedAvailable, size: 24),
                  const SizedBox(height: 8),
                  const Text('No Tenant Assigned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.bedAvailable)),
                  const SizedBox(height: 4),
                  Text('This bed is currently available. Assign a tenant to view their information and payment history.', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBedHeader(BuildContext context, BedModel bed) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = switch (bed.status.toUpperCase()) {
      'AVAILABLE' => AppColors.bedAvailable,
      'OCCUPIED' => AppColors.bedOccupied,
      'MAINTENANCE' => AppColors.bedMaintenance,
      _ => colorScheme.onSurfaceVariant,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: colorScheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bed ${bed.bedNumber}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withAlpha(77))),
                child: Text(bed.status.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [Icon(Icons.bed_outlined, size: 16, color: colorScheme.onSurfaceVariant), const SizedBox(width: 8), Text('Type: ${bed.bedType}', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))]),
          const SizedBox(height: 8),
          Row(children: [Icon(Icons.person_outlined, size: 16, color: colorScheme.onSurfaceVariant), const SizedBox(width: 8), Text('Occupant: ${bed.occupantLabel}', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))]),
          const SizedBox(height: 8),
          Row(children: [Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.onSurfaceVariant), const SizedBox(width: 8), Text('Created: ${DateFormat('MMM dd, yyyy').format(bed.createdAt)}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))]),
        ],
      ),
    );
  }

  Widget _buildTenantCard(BuildContext context, TenantModel tenant) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tenant.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildInfoRow(context, 'Phone', tenant.phone),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Email', tenant.email),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Joining Date', DateFormat('MMM dd, yyyy').format(tenant.joiningDate)),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Deposit Paid', '₹${tenant.depositPaid.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, InvoiceModel invoice) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOverdue = invoice.dueDate.isBefore(DateTime.now()) && invoice.status == 'PENDING';
    final statusColor = switch (invoice.status.toUpperCase()) {
      'PAID' => AppColors.bedAvailable,
      'OVERDUE' => colorScheme.error,
      _ => isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colorScheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_getMonthName(invoice.month)} ${invoice.year}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(16)),
                child: Text(invoice.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount Due', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text('₹${invoice.totalAmount.toStringAsFixed(2)}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          if (invoice.payment != null && invoice.status == 'PAID') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Paid On', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                Text(invoice.payment!.paidAt != null ? DateFormat('MMM dd, yyyy').format(invoice.payment!.paidAt!) : 'N/A', style: const TextStyle(fontSize: 13, color: AppColors.bedAvailable)),
              ],
            ),
          ],
          if (invoice.dueDate.isBefore(DateTime.now()) && invoice.status != 'PAID') ...[
            const SizedBox(height: 8),
            Text('Due Date: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}', style: TextStyle(fontSize: 12, color: colorScheme.error)),
          ],
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return months[month - 1];
  }

  Future<void> _showStatusDialog(BuildContext context, BedModel bed) async {
    final statuses = ['AVAILABLE', 'OCCUPIED', 'RESERVED', 'MAINTENANCE'];
    _selectedStatus = bed.status.toUpperCase();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Bed Status'),
        content: StatefulBuilder(
          builder: (context, setState) => RadioGroup<String>(
            groupValue: _selectedStatus,
            onChanged: (value) => setState(() => _selectedStatus = value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: statuses
                  .map(
                    (status) => RadioListTile<String>(
                      title: Text(status),
                      value: status,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_selectedStatus != null && _selectedStatus != bed.status.toUpperCase()) {
                _updateBedStatus(bed.id, _selectedStatus!);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBedStatus(String bedId, String newStatus) async {
    try {
      await ref.read(updateBedProvider((bedId, {'status': newStatus})).future);
      ref.refresh(bedDetailProvider(bedId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bed status updated successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, String bedId) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bed'),
        content: const Text('Are you sure you want to delete this bed? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () { _deleteBed(bedId); Navigator.pop(context); },
            child: const Text('Delete', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBed(String bedId) async {
    try {
      await ref.read(deleteBedProvider(bedId).future);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bed deleted successfully'))); context.pop(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
