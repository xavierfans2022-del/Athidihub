import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/auth/providers/auth_provider.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/shared/widgets/app_logo.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';

class MpinSetupScreen extends ConsumerStatefulWidget {
  final String phone;
  final String fullName;
  final String role;

  const MpinSetupScreen({
    super.key,
    required this.phone,
    required this.fullName,
    required this.role,
  });

  @override
  ConsumerState<MpinSetupScreen> createState() => _MpinSetupScreenState();
}

class _MpinSetupScreenState extends ConsumerState<MpinSetupScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMpin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pinCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MPINs do not match')),
      );
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.setupMpin(
      pin: _pinCtrl.text,
      fullName: widget.fullName,
      role: widget.role,
    );

    if (!mounted || ref.read(authNotifierProvider).hasError) return;

    await notifier.finalizeSignedInSession();
    if (mounted) {
      context.go('/splash');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen(authNotifierProvider, (prev, next) {
      if (!mounted || !next.hasError) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.error.toString().replaceAll('Exception: ', '')),
          backgroundColor: colorScheme.error,
        ),
      );
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(compact: true),
                const SizedBox(height: 32),
                Text(
                  'Set your MPIN',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a 4 to 6 digit MPIN for ${widget.role.toLowerCase()} login.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                _summaryCard(theme, colorScheme),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _pinCtrl,
                  label: 'MPIN',
                  hint: 'Enter 4 to 6 digits',
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^\d{4,6}$').hasMatch(value.trim())) return 'Use 4 to 6 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmCtrl,
                  label: 'Confirm MPIN',
                  hint: 'Repeat MPIN',
                  obscureText: _obscureConfirm,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Activate MPIN',
                  onPressed: authState.isLoading ? null : _saveMpin,
                  isLoading: authState.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.fullName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(widget.phone, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Role: ${widget.role}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}