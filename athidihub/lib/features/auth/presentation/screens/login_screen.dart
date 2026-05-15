import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/core/providers/supabase_provider.dart';
import 'package:athidihub/features/auth/providers/auth_provider.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/shared/widgets/app_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isOwnerMode = true; // True: Owner (Password), False: Tenant (OTP)
  bool _obscurePass = true;
  bool _didAttemptLogin = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _didAttemptLogin = true;
    final notifier = ref.read(authNotifierProvider.notifier);
    
    if (_isOwnerMode) {
      // Owner login with Email & Password
      await notifier.loginWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
    } else {
      // Tenant login with OTP (Email or Phone)
      final input = _emailCtrl.text.trim();
      if (input.contains('@')) {
        await notifier.loginWithEmailOtp(input);
      } else {
        await notifier.loginWithPhone(input);
      }
      
      if (mounted && !ref.read(authNotifierProvider).hasError) {
        _didAttemptLogin = false;
        context.pushNamed('otp', extra: input);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen(authNotifierProvider, (prev, next) {
      if (!mounted) return;
      if (next.hasError) {
        _didAttemptLogin = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: colorScheme.error,
          ),
        );
        return;
      }
      if (_didAttemptLogin && prev?.isLoading == true && !next.isLoading && !next.hasError) {
        _didAttemptLogin = false;
        final session = ref.read(supabaseClientProvider).auth.currentSession;
        if (session != null && mounted) context.go('/splash');
      }
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
                Text('Welcome back', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Sign in to manage your PG properties', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                  child: Row(
                    children: [
                      _buildToggle(context, 'Owner / Manager', _isOwnerMode, () => setState(() => _isOwnerMode = true)),
                      _buildToggle(context, 'Tenant', !_isOwnerMode, () => setState(() => _isOwnerMode = false)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                AppTextField(
                  controller: _emailCtrl,
                  label: _isOwnerMode ? 'Email address' : 'Email or Phone number',
                  hint: _isOwnerMode ? 'owner@example.com' : 'tenant@example.com or +91 9876543210',
                  keyboardType: _isOwnerMode ? TextInputType.emailAddress : TextInputType.text,
                  prefixIcon: _isOwnerMode ? Icons.email_outlined : Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (_isOwnerMode && !v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                if (_isOwnerMode) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passCtrl,
                    label: 'Password',
                    hint: '••••••••',
                    obscureText: _obscurePass,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text('Forgot password?', style: TextStyle(fontSize: 13, color: colorScheme.primary, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                AppButton(label: _isOwnerMode ? 'Sign In' : 'Send OTP', onPressed: isLoading ? null : _login, isLoading: isLoading),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    TextButton(
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: () => context.push('/auth/register'),
                      child: Text('Create one', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
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
