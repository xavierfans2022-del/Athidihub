import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/features/auth/providers/auth_provider.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/shared/widgets/app_logo.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String nextRoute;
  final Map<String, dynamic>? extraData;

  const OtpScreen({super.key, required this.phone, required this.nextRoute, this.extraData});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _shakeController;
  Timer? _timer;
  int _secondsLeft = 60;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      _shakeController.forward(from: 0);
      HapticFeedback.vibrate();
      return;
    }
    await ref.read(authNotifierProvider.notifier).verifyPhoneOtp(widget.phone, _otp);
    if (!mounted || ref.read(authNotifierProvider).hasError) return;
    context.go(widget.nextRoute, extra: widget.extraData);
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _isResending) return;
    setState(() => _isResending = true);
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    await ref.read(authNotifierProvider.notifier).requestPhoneOtp(widget.phone);
    if (mounted) {
      setState(() => _isResending = false);
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully')),
      );
    }
  }

  void _onPaste(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes[5].requestFocus();
      setState(() {});
      Future.delayed(const Duration(milliseconds: 150), _verify);
    }
  }

  String get _maskedIdentifier {
    final id = widget.phone;
    if (id.contains('@')) {
      final parts = id.split('@');
      final name = parts[0];
      final masked = name.length > 3
          ? '${name.substring(0, 3)}***@${parts[1]}'
          : '***@${parts[1]}';
      return masked;
    }
    if (id.length >= 10) {
      final clean = id.replaceAll(RegExp(r'\D'), '');
      if (clean.length >= 10) {
        return '+••• ••• ••${clean.substring(clean.length - 3)}';
      }
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen(authNotifierProvider, (prev, next) {
      if (!mounted) return;
      if (next.hasError) {
        _shakeController.forward(from: 0);
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const AppLogo(),
              const SizedBox(height: 40),

              // ── Verification Illustration ─────────────────────
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Verification Code',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                    children: [
                      const TextSpan(text: 'Enter the 6-digit code we sent to\n'),
                      TextSpan(
                        text: _maskedIdentifier,
                        style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // ── OTP Inputs ────────────────────────────────────
              AnimatedBuilder(
                animation: _shakeController,
                builder: (_, child) {
                  final v = _shakeController.value;
                  final direction = ((v * 10).round().isEven ? 1 : -1);
                  final offsetX = v * 6 * direction;
                  return Transform.translate(
                    offset: Offset(offsetX, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    isLoading: isLoading,
                    onChanged: (val) {
                      if (val.length > 1) {
                        _onPaste(val);
                        return;
                      }
                      if (val.isNotEmpty) {
                        if (i < 5) _focusNodes[i + 1].requestFocus();
                        HapticFeedback.lightImpact();
                      }
                      setState(() {});
                      if (_otp.length == 6 && !isLoading) {
                        Future.delayed(const Duration(milliseconds: 100), _verify);
                      }
                    },
                    onBackspace: () {
                      if (_controllers[i].text.isEmpty && i > 0) {
                        _controllers[i - 1].clear();
                        _focusNodes[i - 1].requestFocus();
                        HapticFeedback.selectionClick();
                        setState(() {});
                      }
                    },
                  )),
                ),
              ),
              const SizedBox(height: 48),

              // ── Actions ───────────────────────────────────────
              AppButton(
                label: 'Verify & Proceed',
                onPressed: isLoading || _otp.length < 6 ? null : _verify,
                isLoading: isLoading,
              ),
              const SizedBox(height: 32),

              // ── Resend Timer ──────────────────────────────────
              _secondsLeft > 0
                  ? Column(
                      children: [
                        Text(
                          'Resend code in',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        _CountdownText(seconds: _secondsLeft, color: cs.primary),
                      ],
                    )
                  : TextButton.icon(
                      onPressed: _isResending ? null : _resend,
                      icon: _isResending 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(_isResending ? 'Sending...' : 'Resend Code'),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filled = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 62,
      decoration: BoxDecoration(
        color: _isFocused ? cs.surface : cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused 
            ? cs.primary 
            : filled ? cs.primary.withOpacity(0.5) : cs.outline.withOpacity(0.5),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused ? [
          BoxShadow(
            color: cs.primary.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: Center(
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: !widget.isLoading,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            fontFamily: 'Inter',
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

class _CountdownText extends StatelessWidget {
  final int seconds;
  final Color color;
  const _CountdownText({required this.seconds, required this.color});

  @override
  Widget build(BuildContext context) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    final label = mins > 0
        ? '${mins}m ${secs.toString().padLeft(2, '0')}s'
        : '${secs}s';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        label,
        key: ValueKey(seconds),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
