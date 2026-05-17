import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/features/tenants/providers/tenant_api_provider.dart';
import 'package:athidihub/features/dashboard/providers/dashboard_provider.dart';

class AddTenantScreen extends ConsumerStatefulWidget {
  const AddTenantScreen({super.key});

  @override
  ConsumerState<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends ConsumerState<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  // deposit removed from tenant model; security deposits are per-assignment
  DateTime _joiningDate = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) setState(() => _joiningDate = date);
  }

  // Document upload removed — handled in KYC flow

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final orgId = await ref.read(selectedOrganizationIdProvider.future);
    if (orgId == null || orgId.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No organization selected. Please complete onboarding.'), backgroundColor: AppColors.error));
      return;
    }
    final success = await ref.read(tenantCreateProvider.notifier).createTenant({
      'organizationId': orgId,
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      // email removed from UI; send placeholder derived from phone so backend validation continues to pass
      'email': '${_phoneCtrl.text.trim()}@no-reply.athidihub',
      'emergencyContact': _emergencyCtrl.text.trim(),
      'joiningDate': _joiningDate.toIso8601String(),
    });
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tenant added successfully!'), backgroundColor: AppColors.success));
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.read(tenantCreateProvider).error ?? 'Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantCreateProvider);
    final isLoading = state.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        title: const Text('Add Tenant'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(context, 'Personal Details'),
              AppTextField(controller: _nameCtrl, label: 'Full name', hint: 'e.g. Rahul Kumar', prefixIcon: Icons.person_outline_rounded, textCapitalization: TextCapitalization.words, validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              const SizedBox(height: 16),
              AppTextField(controller: _phoneCtrl, label: 'Phone number', hint: '+91 98765 43210', keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined, validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              const SizedBox(height: 16),
              AppTextField(controller: _emergencyCtrl, label: 'Emergency contact', hint: '+91 98765 00000', keyboardType: TextInputType.phone, prefixIcon: Icons.emergency_outlined, validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              const SizedBox(height: 24),

              _buildSection(context, 'Stay Details'),
              GestureDetector(
                onTap: _pickDate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Joining date', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Text('${_joiningDate.day}/${_joiningDate.month}/${_joiningDate.year}', style: theme.textTheme.bodyMedium),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppButton(label: 'Save Tenant', onPressed: isLoading ? null : _save, isLoading: isLoading, icon: Icons.check_rounded),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.3)),
    );
  }
}
