import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/onboarding/providers/onboarding_provider.dart';
import 'package:athidihub/features/onboarding/providers/navigation_provider.dart';
import 'steps/step_create_org.dart';
import 'steps/step_create_property.dart';
import 'steps/step_create_room.dart';
import 'steps/step_create_bed.dart';

final onboardingStepProvider = StateProvider<int>((ref) => 0);

class OnboardingShell extends ConsumerStatefulWidget {
  const OnboardingShell({super.key});

  @override
  ConsumerState<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends ConsumerState<OnboardingShell> {
  static const List<String> _titles = [
    'Create Organization',
    'Add Your Property',
    'Setup Rooms',
    'Configure Beds',
  ];

  static const List<String> _subtitles = [
    'Tell us about your business',
    'Add your first PG property',
    'Define room layout and pricing',
    'Set up beds for tenant allocation',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final progress = await ref.read(onboardingProgressProvider.future);
        if (!mounted || progress == null) return;
        ref.read(onboardingStepProvider.notifier).state =
            progress.currentStep.clamp(0, 3);
      } catch (_) {
        // Ignore error
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(onboardingStepProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final steps = [
      const StepCreateOrg(),
      const StepCreateProperty(),
      const StepCreateRoom(),
      const StepCreateBed(),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (step > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          color: cs.onSurface,
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              ref.read(onboardingStepProvider.notifier).state = step - 1,
                        ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(AppConstants.onboardingTotalSteps, (i) {
                      return Expanded(
                        child: AnimatedContainer(
                          duration: AppConstants.animNormal,
                          margin: const EdgeInsets.only(right: 6),
                          height: 3,
                          decoration: BoxDecoration(
                            color: i <= step ? cs.primary : cs.outline,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Step ${step + 1} of ${AppConstants.onboardingTotalSteps}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _titles[step],
                    style: tt.headlineSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitles[step],
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppConstants.animNormal,
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: steps[step],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
