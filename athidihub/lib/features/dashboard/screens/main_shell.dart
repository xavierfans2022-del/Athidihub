import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/l10n/app_localizations.dart';

final _navIndexProvider = StateProvider<int>((ref) => 0);
final _lastTabTapProvider = StateProvider<Map<int, DateTime>>((ref) => {});
final _lastBackPressProvider = StateProvider<DateTime?>((ref) => null);

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _exitTimeWindow = Duration(seconds: 2);
  static const _doubleTapWindow = Duration(milliseconds: 500);

  void _handleTabTap(int index) {
    if (!mounted) return;

    final currentIndex = widget.navigationShell.currentIndex;
    final lastTaps = ref.read(_lastTabTapProvider);
    final now = DateTime.now();

    if (currentIndex == index) {
      final lastTap = lastTaps[index];
      if (lastTap != null && now.difference(lastTap) < _doubleTapWindow) {
        _popToRoot();
        ref.read(_lastTabTapProvider.notifier).state = {
          ...lastTaps,
          index: DateTime(2000),
        };
        return;
      }
    }

    ref.read(_lastTabTapProvider.notifier).state = {...lastTaps, index: now};

    if (currentIndex != index) {
      HapticFeedback.lightImpact();
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == currentIndex,
      );
      ref.read(_navIndexProvider.notifier).state = index;
    }
  }

  void _popToRoot() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final router = GoRouter.of(context);
    while (router.canPop()) {
      router.pop();
    }
  }

  Future<bool> _handleBackPress() async {
    if (!mounted) return false;

    final currentIndex = widget.navigationShell.currentIndex;
    final router = GoRouter.of(context);

    print(
      '[BackPress] currentIndex: $currentIndex, canPop: ${router.canPop()}',
    );

    if (router.canPop()) {
      print('[BackPress] Router can pop, popping...');
      router.pop();
      return false;
    }

    if (currentIndex != 0) {
      print('[BackPress] Not on dashboard, navigating to dashboard...');
      widget.navigationShell.goBranch(0, initialLocation: true);
      ref.read(_navIndexProvider.notifier).state = 0;
      return false;
    }

    final lastBackPress = ref.read(_lastBackPressProvider);
    final now = DateTime.now();
    final timeSinceLastPress = lastBackPress != null
        ? now.difference(lastBackPress)
        : null;

    print(
      '[BackPress] On dashboard. lastBackPress: $lastBackPress, now: $now, timeSince: $timeSinceLastPress',
    );

    if (lastBackPress == null ||
        now.difference(lastBackPress) > _exitTimeWindow) {
      print('[BackPress] First press or timeout elapsed, showing snackbar...');
      ref.read(_lastBackPressProvider.notifier).state = now;
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.pressBackAgainToExitApp),
            duration: _exitTimeWindow,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return false;
    }

    print('[BackPress] Second press detected within timeout, exiting...');
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
        label: localizations.dashboard,
      ),
      _NavItem(
        icon: Icons.home_work_outlined,
        selectedIcon: Icons.home_work_rounded,
        label: localizations.properties,
      ),
      _NavItem(
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
        label: localizations.tenants,
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: localizations.invoices,
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: localizations.profile,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(_navIndexProvider) != selectedIndex) {
        ref.read(_navIndexProvider.notifier).state = selectedIndex;
      }
    });

    return BackButtonListener(
      onBackButtonPressed: () async {
        print('[BackButtonListener] Back button pressed');
        final shouldExit = await _handleBackPress();
        print('[BackButtonListener] shouldExit: $shouldExit');
        if (shouldExit && mounted) {
          print('[BackButtonListener] Calling SystemNavigator.pop()');
          SystemNavigator.pop();
        }
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(navItems.length, (i) {
                    return _NavButton(
                      item: navItems[i],
                      isSelected: selectedIndex == i,
                      onTap: () => _handleTabTap(i),
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

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: colorScheme.primary.withOpacity(0.1),
          highlightColor: colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                          AppColors.transparent,
                          colorScheme.primary,
                          value,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 22,
                        color: Color.lerp(
                          colorScheme.onSurfaceVariant,
                          colorScheme.onPrimary,
                          value,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    letterSpacing: -0.2,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
