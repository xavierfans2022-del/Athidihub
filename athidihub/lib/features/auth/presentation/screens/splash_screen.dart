import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/providers/supabase_provider.dart';
import 'package:athidihub/features/auth/providers/auth_provider.dart';
import 'package:athidihub/features/dashboard/providers/dashboard_provider.dart';
import 'package:athidihub/features/tenant_portal/providers/tenant_portal_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

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
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session == null) {
      context.go('/auth/login');
      return;
    }

    if (!ref.read(mpinUnlockedProvider)) {
      final route = ref.read(mpinFlowProvider) == MpinFlow.setup ? '/auth/mpin/setup' : '/auth/mpin/unlock';
      context.go(route);
      return;
    }

    // ── Role detection: check if the user is a Tenant ─────────────
    try {
      final tenantInfo = await ref.read(currentTenantProvider.future);
      if (!mounted) return;
      if (tenantInfo != null) {
        // This user is a tenant — go to tenant portal
        context.go('/tenant/home');
        return;
      }
    } catch (_) {
      // Not a tenant (404/network error) — continue as owner/manager
    }

    // ── Owner / Manager path ──────────────────────────────────────
    final selectedOrgId = await ref.read(selectedOrganizationIdProvider.future);
    if (!mounted) return;
    if (selectedOrgId == null || selectedOrgId.isEmpty) {
      context.go('/onboarding');
    } else {
      context.go('/dashboard');
    }
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
