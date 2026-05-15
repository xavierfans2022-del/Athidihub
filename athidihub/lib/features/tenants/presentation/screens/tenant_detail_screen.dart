import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/tenants/providers/tenant_api_provider.dart';
import 'package:athidihub/features/tenants/data/tenant_api_repository.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';
import 'package:athidihub/features/invoices/presentation/widgets/generate_invoice_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/features/kyc/models/kyc_models.dart';
import 'package:athidihub/features/kyc/providers/kyc_provider.dart';
import 'package:athidihub/features/kyc/screens/admin_kyc_review_screen.dart';

class TenantDetailScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  ConsumerState<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends ConsumerState<TenantDetailScreen> {
  bool _isSendingWhatsAppTest = false;

  // ── Edit bottom sheet ────────────────────────────────────────────────────

  void _navigateToEdit(TenantModel tenant) {
    context.push('/tenants/${tenant.id}/edit', extra: tenant).then((_) {
      ref.invalidate(tenantDetailApiProvider(widget.tenantId));
    });
  }

  // ── Delete dialog ────────────────────────────────────────────────────────

  Future<void> _confirmDelete(TenantModel tenant) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.error.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.person_remove_rounded,
                  color: colorScheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Tenant',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete ${tenant.name}? This will remove all their assignments and data. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(tenantDeleteProvider.notifier)
        .deleteTenant(tenant.id);
    if (!mounted) return;

    if (success) {
      ref.invalidate(tenantsListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tenant.name} deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(tenantDeleteProvider).error ?? 'Delete failed',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _sendWhatsAppTest(TenantModel tenant) async {
    if (_isSendingWhatsAppTest) return;

    setState(() {
      _isSendingWhatsAppTest = true;
    });

    try {
      await ref.read(tenantApiRepositoryProvider).testTenantWhatsApp(tenant.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WhatsApp test queued for ${tenant.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send WhatsApp test: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingWhatsAppTest = false;
        });
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tenantAsync = ref.watch(tenantDetailApiProvider(widget.tenantId));
    final colorScheme = Theme.of(context).colorScheme;
    final isDeleting = ref.watch(tenantDeleteProvider).isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: const Text('Tenant Profile'),
        actions: [
          RefreshButton(
            label: 'Refresh',
            onRefresh: () async {
              ref.invalidate(tenantDetailApiProvider(widget.tenantId));
              await ref.read(tenantDetailApiProvider(widget.tenantId).future);
            },
          ),
          tenantAsync
                  .whenData(
                    (tenant) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          tooltip: 'Edit',
                          onPressed: () => _navigateToEdit(tenant),
                        ),
                        IconButton(
                          icon: isDeleting
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.error,
                                  ),
                                )
                              : Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: colorScheme.error,
                                ),
                          tooltip: 'Delete',
                          onPressed: isDeleting
                              ? null
                              : () => _confirmDelete(tenant),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  )
                  .value ??
              const SizedBox(),
        ],
      ),
      body: tenantAsync.when(
        data: (tenant) => _buildDetail(context, tenant),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, TenantModel tenant) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      tenant.initials,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tenant.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (tenant.isActive
                                ? AppColors.success
                                : colorScheme.onSurfaceVariant)
                            .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    tenant.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: tenant.isActive
                          ? AppColors.success
                          : colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Info card
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  context,
                  Icons.email_outlined,
                  'Email',
                  tenant.email,
                ),
                Divider(height: 1, indent: 56, color: colorScheme.outline),
                _buildInfoTile(
                  context,
                  Icons.phone_outlined,
                  'Phone',
                  tenant.phone,
                ),
                Divider(height: 1, indent: 56, color: colorScheme.outline),
                _buildInfoTile(
                  context,
                  Icons.emergency_outlined,
                  'Emergency Contact',
                  tenant.emergencyContact,
                ),
                Divider(height: 1, indent: 56, color: colorScheme.outline),
                _buildInfoTile(
                  context,
                  Icons.calendar_today_outlined,
                  'Joining Date',
                  tenant.joiningDate.split('T')[0],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSendingWhatsAppTest
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.chat_rounded, size: 18),
              label: Text(
                _isSendingWhatsAppTest
                    ? 'Sending Test...'
                    : 'Send WhatsApp Test',
              ),
              onPressed: _isSendingWhatsAppTest
                  ? null
                  : () => _sendWhatsAppTest(tenant),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sends a test WhatsApp message only to this tenant.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          // KYC Section
          () {
            final kycAsync = ref.watch(kycStatusProvider(widget.tenantId));
            return kycAsync.when(
              data: (status) => _buildKycSection(context, status),
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _buildKycSection(context, null),
            );
          }(),
          const SizedBox(height: 10),
          // Assignment section
          if (tenant.hasActiveAssignment)
            _buildAssignmentCard(context, tenant)
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bed_rounded, size: 18),
                label: const Text('Assign Bed'),
                onPressed: () => context.go('/tenants/${tenant.id}/assign'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, TenantModel tenant) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final a = tenant.activeAssignment!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: cs.outline)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bed_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Current Assignment',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Room & Bed info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _assignmentInfoCell(
                        context,
                        icon: Icons.meeting_room_outlined,
                        label: 'Room',
                        value: a.bed?.room?.roomNumber ?? '—',
                      ),
                    ),
                    Container(width: 1, height: 40, color: cs.outline),
                    Expanded(
                      child: _assignmentInfoCell(
                        context,
                        icon: Icons.bed_outlined,
                        label: 'Bed',
                        value: 'Bed ${a.bed?.bedNumber ?? '—'}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: cs.outline),
                const SizedBox(height: 12),
                // Rent & Deposit
                Row(
                  children: [
                    Expanded(
                      child: _assignmentInfoCell(
                        context,
                        icon: Icons.currency_rupee_rounded,
                        label: 'Monthly Rent',
                        value: '₹${a.monthlyRent.toStringAsFixed(0)}',
                        valueColor: cs.primary,
                      ),
                    ),
                    Container(width: 1, height: 40, color: cs.outline),
                    Expanded(
                      child: _assignmentInfoCell(
                        context,
                        icon: Icons.savings_outlined,
                        label: 'Security Deposit',
                        value: '₹${a.securityDeposit.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        context,
                        Icons.swap_horiz_rounded,
                        'Change Bed',
                        cs.primary,
                        () => context.go('/tenants/${tenant.id}/assign'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        context,
                        Icons.receipt_long_rounded,
                        'Generate Invoice',
                        AppColors.warning,
                        () => _generateInvoice(tenant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentInfoCell(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycSection(BuildContext context, KYCStatus? status) {
    final cs = Theme.of(context).colorScheme;
    if (status == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KYC: Not started',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text('This tenant has not started KYC verification yet.'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Icon(
            status.status == KYCVerificationStatus.verified
                ? Icons.verified_rounded
                : Icons.hourglass_bottom_rounded,
            color: status.status == KYCVerificationStatus.verified
                ? Colors.green
                : cs.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KYC: ${status.status.name}',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('Completion: ${status.completionPercentage}%'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openKycDetails(context),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _openKycDetails(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (c) => AdminKYCDetailPanel(tenantId: widget.tenantId),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateInvoice(TenantModel tenant) async {
    // Get assigned monthly rent from active assignment
    final assignedRent = (tenant.activeAssignment?.monthlyRent ?? 0).toDouble();
    await GenerateInvoiceSheet.show(
      context,
      tenantId: tenant.id,
      tenantName: tenant.name,
      assignedRent: assignedRent,
    );
  }
}
