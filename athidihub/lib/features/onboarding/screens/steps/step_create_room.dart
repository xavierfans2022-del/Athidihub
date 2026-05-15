import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/features/onboarding/screens/onboarding_shell.dart';
import 'package:athidihub/features/onboarding/providers/onboarding_provider.dart';

class StepCreateRoom extends ConsumerStatefulWidget {
  const StepCreateRoom({super.key});

  @override
  ConsumerState<StepCreateRoom> createState() => _StepCreateRoomState();
}

class _StepCreateRoomState extends ConsumerState<StepCreateRoom> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  String _roomType = 'DOUBLE';
  bool _isAC = false;
  int _floorNumber = 1;

  final _roomTypes = ['SINGLE', 'DOUBLE', 'TRIPLE', 'QUAD', 'DORMITORY'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ref.read(onboardingNotifierProvider).roomData;
      if (data == null) return;
      _roomNumberCtrl.text = data['roomNumber'] ?? '';
      _rentCtrl.text = data['monthlyRent']?.toString() ?? '';
      _depositCtrl.text = data['securityDeposit']?.toString() ?? '';
      _capacityCtrl.text = data['capacity']?.toString() ?? '';
      setState(() {
        _roomType = data['roomType'] ?? 'DOUBLE';
        _isAC = data['isAC'] ?? false;
        _floorNumber = data['floorNumber'] ?? 1;
      });
    });
  }

  @override
  void dispose() {
    _roomNumberCtrl.dispose();
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(onboardingNotifierProvider.notifier).createRoom({
      'floorNumber': _floorNumber,
      'roomNumber': _roomNumberCtrl.text.trim(),
      'roomType': _roomType,
      'isAC': _isAC,
      'monthlyRent': double.tryParse(_rentCtrl.text) ?? 0,
      'securityDeposit': double.tryParse(_depositCtrl.text) ?? 0,
      'capacity': int.tryParse(_capacityCtrl.text) ?? 2,
    });

    if (success && mounted) {
      ref.read(onboardingStepProvider.notifier).state = 3;
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(onboardingNotifierProvider).error ?? 'Error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLoading = ref.watch(onboardingNotifierProvider).isLoading;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Floor number',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          border: Border.all(color: cs.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              color: cs.onSurfaceVariant,
                              onPressed: () {
                                if (_floorNumber > 0) setState(() => _floorNumber--);
                              },
                            ),
                            Expanded(
                              child: Text(
                                '$_floorNumber',
                                textAlign: TextAlign.center,
                                style: tt.titleMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              color: cs.primary,
                              onPressed: () => setState(() => _floorNumber++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _roomNumberCtrl,
                    label: 'Room number',
                    hint: '101',
                    keyboardType: TextInputType.text,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Room type selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room type',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _roomTypes.map((type) {
                      final selected = _roomType == type;
                      return GestureDetector(
                        onTap: () => setState(() => _roomType = type),
                        child: AnimatedContainer(
                          duration: AppConstants.animFast,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? cs.primary.withOpacity(0.12)
                                : cs.surfaceContainerHighest,
                            border: Border.all(
                              color: selected ? cs.primary : cs.outline,
                              width: selected ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            type,
                            style: tt.labelSmall?.copyWith(
                              color: selected ? cs.primary : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _rentCtrl,
                    label: 'Monthly rent (₹)',
                    hint: '8000',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee_rounded,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _depositCtrl,
                    label: 'Security deposit (₹)',
                    hint: '16000',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.savings_outlined,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _capacityCtrl,
              label: 'Capacity (beds)',
              hint: '3',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.bed_rounded,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // AC Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.ac_unit_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Air Conditioned',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isAC,
                    onChanged: (v) => setState(() => _isAC = v),
                    activeColor: cs.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Continue',
              onPressed: isLoading ? null : _next,
              isLoading: isLoading,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
