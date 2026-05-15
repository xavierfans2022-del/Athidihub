import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/features/onboarding/screens/onboarding_shell.dart';
import 'package:athidihub/features/onboarding/providers/onboarding_provider.dart';

final _propFormKey = GlobalKey<FormState>();

class StepCreateProperty extends ConsumerStatefulWidget {
  const StepCreateProperty({super.key});

  @override
  ConsumerState<StepCreateProperty> createState() => _StepCreatePropertyState();
}

class _StepCreatePropertyState extends ConsumerState<StepCreateProperty> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _floorsCtrl = TextEditingController();
  final _amenities = <String>[];

  final _allAmenities = [
    'WiFi', 'AC', 'Parking', 'Laundry', 'Mess/Food',
    'CCTV', 'Gym', 'Study Room', '24/7 Security', 'Hot Water',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ref.read(onboardingNotifierProvider).propertyData;
      if (data == null) return;
      _nameCtrl.text = data['name'] ?? '';
      _addressCtrl.text = data['address'] ?? '';
      _cityCtrl.text = data['city'] ?? '';
      _stateCtrl.text = data['state'] ?? '';
      _floorsCtrl.text = data['totalFloors']?.toString() ?? '';
      if (data['amenities'] is List) {
        setState(() {
          _amenities
            ..clear()
            ..addAll(List<String>.from(data['amenities']));
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _floorsCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_propFormKey.currentState!.validate()) return;

    final success = await ref.read(onboardingNotifierProvider.notifier).createProperty({
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'totalFloors': int.tryParse(_floorsCtrl.text) ?? 1,
      'amenities': _amenities,
    });

    if (success && mounted) {
      ref.read(onboardingStepProvider.notifier).state = 2;
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
      key: _propFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          children: [
            AppTextField(
              controller: _nameCtrl,
              label: 'Property name',
              hint: 'e.g. Gachibowli Boys Hostel',
              prefixIcon: Icons.home_outlined,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _addressCtrl,
              label: 'Address',
              hint: 'Full address',
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _cityCtrl,
                    label: 'City',
                    hint: 'Hyderabad',
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _stateCtrl,
                    label: 'State',
                    hint: 'Telangana',
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _floorsCtrl,
              label: 'Total floors',
              hint: '4',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.layers_outlined,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // Amenities
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amenities',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allAmenities.map((a) {
                    final selected = _amenities.contains(a);
                    return GestureDetector(
                      onTap: () => setState(() {
                        selected ? _amenities.remove(a) : _amenities.add(a);
                      }),
                      child: AnimatedContainer(
                        duration: AppConstants.animFast,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.secondary.withOpacity(0.12)
                              : cs.surfaceContainerHighest,
                          border: Border.all(
                            color: selected ? cs.secondary : cs.outline,
                            width: selected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected)
                              Icon(Icons.check, size: 12, color: cs.secondary),
                            if (selected) const SizedBox(width: 4),
                            Text(
                              a,
                              style: tt.labelSmall?.copyWith(
                                color: selected ? cs.secondary : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
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
