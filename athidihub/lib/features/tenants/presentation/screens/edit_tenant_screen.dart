import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/tenants/providers/assignment_provider.dart';
import 'package:athidihub/features/tenants/providers/tenant_api_provider.dart';
import 'package:athidihub/features/tenants/data/tenant_api_repository.dart';
import 'package:go_router/go_router.dart';

class EditTenantScreen extends ConsumerStatefulWidget {
  final TenantModel tenant;

  const EditTenantScreen({super.key, required this.tenant});

  @override
  ConsumerState<EditTenantScreen> createState() => _EditTenantScreenState();
}

class _EditTenantScreenState extends ConsumerState<EditTenantScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _emergencyCtrl;
  late final TextEditingController _monthlyRentCtrl;
  late final TextEditingController _securityDepositCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.tenant.name);
    _phoneCtrl = TextEditingController(text: widget.tenant.phone);
    _emailCtrl = TextEditingController(text: widget.tenant.email);
    _emergencyCtrl = TextEditingController(text: widget.tenant.emergencyContact);
    final activeAssignment = widget.tenant.activeAssignment;
    _monthlyRentCtrl = TextEditingController(
      text: activeAssignment != null ? activeAssignment.monthlyRent.toStringAsFixed(0) : '',
    );
    _securityDepositCtrl = TextEditingController(
      text: activeAssignment != null ? activeAssignment.securityDeposit.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _emergencyCtrl.dispose();
    _monthlyRentCtrl.dispose();
    _securityDepositCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(tenantEditProvider.notifier).updateTenant(
      widget.tenant.id,
      {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'emergencyContact': _emergencyCtrl.text.trim(),
      },
    );

    if (success && widget.tenant.activeAssignment != null) {
      final assignment = widget.tenant.activeAssignment!;
      final assignmentSuccess = await ref.read(assignmentEditProvider.notifier).updateAssignment(
        assignment.id,
        {
          'monthlyRent': double.tryParse(_monthlyRentCtrl.text) ?? assignment.monthlyRent,
          'securityDeposit': double.tryParse(_securityDepositCtrl.text) ?? assignment.securityDeposit,
        },
      );

      if (!assignmentSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(assignmentEditProvider).error ?? 'Assignment update failed')),
        );
        return;
      }
    }

    if (!mounted) return;

    if (success) {
      ref.refresh(tenantDetailApiProvider(widget.tenant.id));
      ref.refresh(tenantsListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant updated successfully'), backgroundColor: AppColors.success),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(tenantEditProvider).error ?? 'Update failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = ref.watch(tenantEditProvider).isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        title: const Text('Edit Tenant'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: isLoading ? null : _save,
              child: isLoading
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
                  : Text('Save', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: colorScheme.primary, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          widget.tenant.initials,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Editing ${widget.tenant.name}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _sectionLabel(context, 'Personal Details'),
              _buildField(
                context,
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                type: TextInputType.name,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                context,
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                type: TextInputType.phone,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                context,
                controller: _emailCtrl,
                label: 'Email Address',
                icon: Icons.email_outlined,
                type: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                context,
                controller: _emergencyCtrl,
                label: 'Emergency Contact',
                icon: Icons.emergency_outlined,
                type: TextInputType.phone,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 28),

              if (widget.tenant.activeAssignment != null) ...[
                _sectionLabel(context, 'Assignment Rent & Deposit'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tenant.activeAssignment!.bed?.room?.roomNumber != null
                            ? 'Room ${widget.tenant.activeAssignment!.bed!.room!.roomNumber} · Bed ${widget.tenant.activeAssignment!.bed!.bedNumber}'
                            : 'Active Assignment',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              context,
                              controller: _monthlyRentCtrl,
                              label: 'Monthly Rent (₹)',
                              icon: Icons.currency_rupee_rounded,
                              type: TextInputType.number,
                              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              context,
                              controller: _securityDepositCtrl,
                              label: 'Security Deposit (₹)',
                              icon: Icons.account_balance_wallet_outlined,
                              type: TextInputType.number,
                              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType type,
    required String? Function(String?) validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Inter', fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
