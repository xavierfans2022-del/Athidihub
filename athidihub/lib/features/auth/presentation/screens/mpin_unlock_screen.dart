import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/auth/providers/auth_provider.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/shared/widgets/app_logo.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';

class MpinUnlockScreen extends ConsumerStatefulWidget {
  final String phone;

  const MpinUnlockScreen({super.key, required this.phone});

  @override
  ConsumerState<MpinUnlockScreen> createState() => _MpinUnlockScreenState();
}

class _MpinUnlockScreenState extends ConsumerState<MpinUnlockScreen> {
  final _pinCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePin = true;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.verifyMpin(_pinCtrl.text);
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
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const AppLogo(compact: true),
                const SizedBox(height: 32),
                Text(
                  'Unlock with MPIN',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter the MPIN linked to ${widget.phone}.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _pinCtrl,
                  label: 'MPIN',
                  hint: '4 to 6 digits',
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
                const SizedBox(height: 24),
                AppButton(
                  label: 'Unlock',
                  onPressed: authState.isLoading ? null : _unlock,
                  isLoading: authState.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}