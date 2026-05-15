import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/features/maintenance/providers/maintenance_provider.dart';

class AddMaintenanceScreen extends ConsumerStatefulWidget {
  const AddMaintenanceScreen({super.key});

  @override
  ConsumerState<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends ConsumerState<AddMaintenanceScreen> {
  final _descCtrl = TextEditingController();
  String _category = 'ELECTRICAL';
  final _cats = ['ELECTRICAL', 'PLUMBING', 'CLEANING', 'CARPENTRY', 'OTHER'];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceNotifierProvider);
    final isLoading = state.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        title: const Text('Raise Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _cats.map((c) {
                final sel = _category == c;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? colorScheme.primary.withOpacity(0.15) : colorScheme.surfaceContainerHighest,
                      border: Border.all(color: sel ? colorScheme.primary : colorScheme.outline, width: sel ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(c, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: sel ? colorScheme.primary : colorScheme.onSurfaceVariant)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            AppTextField(controller: _descCtrl, label: 'Description', hint: 'Describe the issue...', maxLines: 4, validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
            const SizedBox(height: 32),
            AppButton(
              label: 'Submit Request',
              onPressed: isLoading ? null : () async {
                final success = await ref.read(maintenanceNotifierProvider.notifier).createRequest({
                  'tenantId': '00000000-0000-0000-0000-000000000000',
                  'propertyId': '00000000-0000-0000-0000-000000000000',
                  'category': _category,
                  'description': _descCtrl.text.trim(),
                });
                if (success && mounted) {
                  Navigator.pop(context);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.read(maintenanceNotifierProvider).error ?? 'Error')));
                }
              },
              isLoading: isLoading,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
