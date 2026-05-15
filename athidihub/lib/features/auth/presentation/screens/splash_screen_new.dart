import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:athidihub/core/providers/supabase_provider.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/features/onboarding/providers/navigation_provider.dart';

class SplashScreenNew extends ConsumerStatefulWidget {
  const SplashScreenNew({super.key});

  @override
  ConsumerState<SplashScreenNew> createState() => _SplashScreenNewState();
}

class _SplashScreenNewState extends ConsumerState<SplashScreenNew>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session == null) {
      context.go('/auth/login');
      return;
    }

    try {
      final navData = await ref.read(navigationDataProvider.future);
      if (!mounted) return;
      context.go(navData.route);
    } on DioException catch (e) {
      if (!mounted) return;
      // 401 means session expired — Dio interceptor already signed out
      if (e.response?.statusCode == 401) {
        context.go('/auth/login');
        return;
      }
      setState(() {
        _hasError = true;
        _errorMessage = 'Unable to connect to server. Please check your connection.';
      });
    } on AuthException catch (_) {
      if (!mounted) return;
      context.go('/auth/login');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Unable to connect to server. Please check your connection.';
      });
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    ref.invalidate(navigationDataProvider);
    _navigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: colorScheme.primary.withAlpha(20), blurRadius: 20, spreadRadius: 0)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/Athidihub_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Athidihub',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text('PG Management, Simplified',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 40),
                  if (_hasError)
                    Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage ?? 'Something went wrong',
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.primary.withAlpha(128),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
