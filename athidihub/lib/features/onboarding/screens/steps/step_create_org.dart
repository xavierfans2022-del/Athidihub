import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/core/services/backend_storage_service.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';
import 'package:athidihub/shared/widgets/app_button.dart';
import 'package:athidihub/features/onboarding/screens/onboarding_shell.dart';
import 'package:athidihub/features/onboarding/providers/onboarding_provider.dart';

final _orgFormKey = GlobalKey<FormState>();

class StepCreateOrg extends ConsumerStatefulWidget {
  const StepCreateOrg({super.key});

  @override
  ConsumerState<StepCreateOrg> createState() => _StepCreateOrgState();
}

class _StepCreateOrgState extends ConsumerState<StepCreateOrg> {
  final _nameCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  String _businessType = 'PG';
  final _types = ['PG', 'Hostel', 'Co-Living', 'Dormitory', 'Serviced Apartments'];
  String? _logoPath;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ref.read(onboardingNotifierProvider).orgData;
      if (data == null) return;
      _nameCtrl.text = data['name'] ?? '';
      _gstCtrl.text = data['gstNumber'] ?? '';
      if (data['businessType'] != null) {
        setState(() => _businessType = data['businessType']);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 800);
    if (file != null) setState(() => _logoPath = file.path);
  }

  Future<String?> _uploadLogoIfAny() async {
    if (_logoPath == null) return null;
    setState(() => _isUploadingLogo = true);
    try {
      final bytes = await File(_logoPath!).readAsBytes();
      final fileName = _logoPath!.split('/').last;
      return ref.read(backendStorageServiceProvider).uploadOrganizationLogo(
            bytes: bytes,
            fileName: fileName,
          );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logo upload failed: $e')));
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _next() async {
    if (!_orgFormKey.currentState!.validate()) return;

    final uploadedLogoUrl = await _uploadLogoIfAny();

    final success = await ref.read(onboardingNotifierProvider.notifier).createOrganization({
      'name': _nameCtrl.text.trim(),
      'businessType': _businessType,
      'gstNumber': _gstCtrl.text.trim(),
      if (uploadedLogoUrl != null) 'logoUrl': uploadedLogoUrl,
    });

    if (success && mounted) {
      ref.read(onboardingStepProvider.notifier).state = 1;
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
      key: _orgFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline),
                ),
                child: _logoPath == null
                    ? Icon(Icons.camera_alt_outlined, color: cs.onSurfaceVariant)
                    : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_logoPath!), fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Upload organization logo (optional)', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),

            AppTextField(
              controller: _nameCtrl,
              label: 'Organization name',
              hint: 'e.g. Bhargav PG Solutions',
              prefixIcon: Icons.business_rounded,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // Business Type chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business type',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((type) {
                    final isSelected = _businessType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _businessType = type),
                      child: AnimatedContainer(
                        duration: AppConstants.animFast,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? cs.primary.withOpacity(0.12) : cs.surfaceContainerHighest,
                          border: Border.all(color: isSelected ? cs.primary : cs.outline, width: isSelected ? 1.5 : 1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(type, style: tt.labelMedium?.copyWith(color: isSelected ? cs.primary : cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(controller: _gstCtrl, label: 'GST number (optional)', hint: '27AAPFU0939F1ZV', prefixIcon: Icons.receipt_long_outlined),
            const SizedBox(height: 32),
            AppButton(label: 'Continue', onPressed: isLoading || _isUploadingLogo ? null : _next, isLoading: isLoading || _isUploadingLogo, icon: Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}
