import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/l10n/app_localizations.dart';

// ─── Nav State ────────────────────────────────────────────────────────────────
final _tenantNavIndexProvider = StateProvider<int>((ref) => 0);
final _tenantLastBackPressProvider = StateProvider<DateTime?>((ref) => null);

// ─── Nav Items ────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}

// ─── Tenant Shell ─────────────────────────────────────────────────────────────
class TenantShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const TenantShell({super.key, required this.navigationShell});

  @override
  ConsumerState<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends ConsumerState<TenantShell> {
  static const _exitTimeWindow = Duration(seconds: 2);

  Future<bool> _handleBackPress() async {
    if (!mounted) return false;
    final currentIndex = widget.navigationShell.currentIndex;
    final router = GoRouter.of(context);

    if (router.canPop()) {
      router.pop();
      return false;
    }

    if (currentIndex != 0) {
      widget.navigationShell.goBranch(0, initialLocation: true);
      ref.read(_tenantNavIndexProvider.notifier).state = 0;
      return false;
    }

    final lastBackPress = ref.read(_tenantLastBackPressProvider);
    final now = DateTime.now();
    if (lastBackPress == null || now.difference(lastBackPress) > _exitTimeWindow) {
      ref.read(_tenantLastBackPressProvider.notifier).state = now;
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.pressBackAgainToExitPortal),
            duration: _exitTimeWindow,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navigationShell.currentIndex;
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final navItems = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: localizations.home,
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: localizations.payments,
      ),
      _NavItem(
        icon: Icons.verified_user_outlined,
        selectedIcon: Icons.verified_user_rounded,
        label: localizations.documents,
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: localizations.profile,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(_tenantNavIndexProvider) != selectedIndex) {
        ref.read(_tenantNavIndexProvider.notifier).state = selectedIndex;
      }
    });

    return BackButtonListener(
      onBackButtonPressed: () async {
        final shouldExit = await _handleBackPress();
        if (shouldExit && mounted) SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black08,
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SafeArea(
              child: Container(
                height: 76,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(navItems.length, (i) {
                    final item = navItems[i];
                    final isSelected = selectedIndex == i;
                    return Expanded(
                      child: Material(
                        color: AppColors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (selectedIndex != i) {
                              widget.navigationShell.goBranch(i);
                              ref.read(_tenantNavIndexProvider.notifier).state = i;
                            }
                          },
                          splashColor: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 250),
                                tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                                curve: Curves.easeInOutCubic,
                                builder: (context, value, _) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: EdgeInsets.all(8 + (2 * value)),
                                    decoration: BoxDecoration(
                                      color: Color.lerp(
                                          AppColors.transparent, colorScheme.primary, value),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSelected ? item.selectedIcon : item.icon,
                                      size: 20,
                                      color: Color.lerp(
                                          colorScheme.onSurfaceVariant, colorScheme.onPrimary, value),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 2),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                child: Text(item.label, maxLines: 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
