import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/auth/providers/auth_provider.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/shared/widgets/app_logo.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isTenant = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authNotifierProvider.notifier).prepareForSetup();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneCtrl.text.trim();
    final notifier = ref.read(authNotifierProvider.notifier);
    notifier.prepareForSetup();
    await notifier.requestPhoneOtp(phone);

    if (!mounted || ref.read(authNotifierProvider).hasError) return;
    context.pushNamed(
      'otp',
      extra: {
        'phone': phone,
        'nextRoute': '/auth/mpin/setup',
        'extraData': {
          'phone': phone,
          'fullName': _nameCtrl.text.trim(),
          'role': _isTenant ? 'TENANT' : 'OWNER',
        },
      },
    );
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
          onPressed: () => context.go('/auth/login'),
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
                  'Create account',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Register with your phone number and MPIN.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Full name',
                  hint: 'Bhargav Sai',
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneCtrl,
                  label: 'Phone number',
                  hint: '+91 9876543210',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final compact = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
                    if (compact.startsWith('+')) {
                      if (!compact.startsWith('+91')) return 'Use +91 country code';
                      final digits = compact.replaceAll(RegExp(r'\D'), '');
                      if (digits.length != 12) return 'Invalid phone number';
                      return null;
                    }

                    final digits = compact.replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 10) return 'Enter a 10-digit Indian mobile number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                  child: Row(
                    children: [
                      _buildToggle(context, 'Owner', !_isTenant, () => setState(() => _isTenant = false)),
                      _buildToggle(context, 'Tenant', _isTenant, () => setState(() => _isTenant = true)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Send OTP',
                  onPressed: authState.isLoading ? null : _sendOtp,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.go('/auth/login'),
                      child: Text(
                        'Sign in',
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(BuildContext context, String label, bool isActive, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animNormal,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}