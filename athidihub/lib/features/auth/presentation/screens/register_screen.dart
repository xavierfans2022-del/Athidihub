import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/core/providers/supabase_provider.dart';
import 'package:athidihub/features/auth/providers/auth_provider.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/shared/widgets/app_logo.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _didAttemptRegister = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    _didAttemptRegister = true;
    await ref.read(authNotifierProvider.notifier).registerWithEmail(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
  }

  void _showVerificationDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.mark_email_read_rounded, color: AppColors.success, size: 32),
            ),
            const SizedBox(height: 12),
            Text('Check your email', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: colorScheme.onSurface), textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          'We sent a confirmation link to ${_emailCtrl.text.trim()}. Click the link to activate your account, then sign in.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(c);
                ref.read(authNotifierProvider.notifier).reset();
                context.go('/auth/login');
              },
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Go to Login', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: colorScheme.onPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen(authNotifierProvider, (prev, next) {
      if (!mounted) return;
      if (next.hasError) {
        _didAttemptRegister = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString().replaceAll('Exception: ', '')), backgroundColor: colorScheme.error),
        );
        return;
      }
      if (_didAttemptRegister && prev?.isLoading == true && !next.isLoading && !next.hasError) {
        _didAttemptRegister = false;
        final session = ref.read(supabaseClientProvider).auth.currentSession;
        if (session != null) {
          if (mounted) context.go('/onboarding');
        } else {
          if (mounted) _showVerificationDialog(context);
        }
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            ref.read(authNotifierProvider.notifier).reset();
            context.go('/auth/login');
          },
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
                Text('Create account', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Start managing your PG with Athidihub', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                AppTextField(controller: _nameCtrl, label: 'Full name', hint: 'Bhargav Sai', prefixIcon: Icons.person_outline_rounded, textCapitalization: TextCapitalization.words, validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email address',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  hint: 'Min 8 characters',
                  obscureText: _obscurePass,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) return 'Min 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmPassCtrl,
                  label: 'Confirm password',
                  hint: '••••••••',
                  obscureText: _obscureConfirm,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                AppButton(label: 'Create Account', onPressed: authState.isLoading ? null : _register, isLoading: authState.isLoading),
                const SizedBox(height: 20),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'By signing up, you agree to our ',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colorScheme.onSurfaceVariant),
                      children: [
                        WidgetSpan(child: GestureDetector(onTap: () {}, child: Text('Terms of Service', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w500)))),
                        const TextSpan(text: ' and '),
                        WidgetSpan(child: GestureDetector(onTap: () {}, child: Text('Privacy Policy', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w500)))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    TextButton(
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).reset();
                        context.go('/auth/login');
                      },
                      child: Text('Sign in', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
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
