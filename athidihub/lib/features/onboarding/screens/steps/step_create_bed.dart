import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/onboarding/providers/onboarding_provider.dart';
import 'package:athidihub/shared/widgets/app_button.dart';

class StepCreateBed extends ConsumerStatefulWidget {
  const StepCreateBed({super.key});

  @override
  ConsumerState<StepCreateBed> createState() => _StepCreateBedState();
}

class _StepCreateBedState extends ConsumerState<StepCreateBed> {
  final _beds = <Map<String, dynamic>>[];
  final _bedTypes = ['STANDARD', 'BUNK', 'PREMIUM'];

  void _addBed() {
    const letters = 'ABCDEFGHIJKLMNOP';
    final next = letters[_beds.length % letters.length];
    setState(() => _beds.add({'number': next, 'type': 'STANDARD'}));
  }

  void _removeBed(int index) {
    if (_beds.length > 1) setState(() => _beds.removeAt(index));
  }

  Future<void> _finish() async {
    if (_beds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one bed')),
      );
      return;
    }

    bool allSuccess = true;
    for (final bed in _beds) {
      final success = await ref.read(onboardingNotifierProvider.notifier).createBed({
        'bedNumber': bed['number'],
        'bedType': bed['type'],
      });
      if (!success) {
        allSuccess = false;
        break;
      }
    }

    if (allSuccess && mounted) {
      await ref.read(onboardingNotifierProvider.notifier).markOnboardingCompleted();
      context.go('/dashboard');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(onboardingNotifierProvider).error ?? 'Failed to save beds')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLoading = ref.watch(onboardingNotifierProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      child: Column(
        children: [
          ...List.generate(_beds.length, (i) => _buildBedRow(context, i, cs, tt)),

          // Add bed button
          GestureDetector(
            onTap: _addBed,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: cs.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Add another bed',
                    style: tt.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Summary card
          if (_beds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.06),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: cs.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${_beds.length} bed${_beds.length == 1 ? '' : 's'} configured',
                    style: tt.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
          AppButton(
            label: 'Finish Setup',
            onPressed: isLoading ? null : _finish,
            isLoading: isLoading,
            icon: Icons.rocket_launch_rounded,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBedRow(BuildContext context, int index, ColorScheme cs, TextTheme tt) {
    final bed = _beds[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.bed_rounded, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Text(
            'Bed ${bed['number']}',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: bed['type'],
              isDense: true,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              dropdownColor: cs.surfaceContainerHighest,
              items: _bedTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _beds[index]['type'] = v),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: cs.onSurfaceVariant),
            onPressed: () => _removeBed(index),
          ),
        ],
      ),
    );
  }
}
