import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/auth/providers/auth_provider.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/shared/widgets/app_logo.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authNotifierProvider.notifier).prepareForUnlock();
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneCtrl.text.trim();
    final notifier = ref.read(authNotifierProvider.notifier);
    notifier.prepareForUnlock();
    await notifier.requestPhoneOtp(phone);

    if (!mounted || ref.read(authNotifierProvider).hasError) return;
    context.pushNamed(
      'otp',
      extra: {
        'phone': phone,
        'nextRoute': '/auth/mpin/unlock',
        'extraData': {'phone': phone},
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const AppLogo(),
                const SizedBox(height: 48),
                Text(
                  'Welcome back',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in with your phone number and MPIN.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
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
                const SizedBox(height: 24),
                AppButton(
                  label: 'Send OTP',
                  onPressed: authState.isLoading ? null : _sendOtp,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.push('/auth/register'),
                      child: Text(
                        'Create one',
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
}