import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/services/backend_storage_service.dart';
import 'package:athidihub/features/organizations/providers/organization_provider.dart';

class EditOrganizationScreen extends StatefulWidget {
  final String organizationId;
  const EditOrganizationScreen({super.key, required this.organizationId});

  @override
  State<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends State<EditOrganizationScreen> {
  late TextEditingController _nameController;
  late TextEditingController _businessTypeController;
  late TextEditingController _gstController;
  late TextEditingController _logoUrlController;

  bool _isSaving = false;
  bool _isUploadingLogo = false;
  String? _logoPath;
  String? _logoUploadError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _businessTypeController = TextEditingController();
    _gstController = TextEditingController();
    _logoUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessTypeController.dispose();
    _gstController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo(WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (file == null) return;

      setState(() {
        _logoPath = file.path;
        _logoUploadError = null;
        _isUploadingLogo = true;
      });

      try {
        final bytes = await File(file.path).readAsBytes();
        final fileName = file.path.split('/').last;

        final uploadedUrl =
            await ref.read(backendStorageServiceProvider).uploadOrganizationLogo(
                  bytes: bytes,
                  fileName: fileName,
                  organizationId: widget.organizationId,
                );

        if (mounted) {
          setState(() {
            _logoUrlController.text = uploadedUrl;
            _logoUploadError = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo uploaded successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _logoUploadError = 'Logo upload failed: $e';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logo upload failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final orgAsync = ref.watch(organizationDetailProvider(widget.organizationId));

        return orgAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Edit Organization')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('Edit Organization')),
            body: Center(
              child: Text('Error: $error'),
            ),
          ),
          data: (org) => org == null
              ? Scaffold(
                  appBar: AppBar(title: const Text('Edit Organization')),
                  body: const Center(child: Text('Organization not found')),
                )
              : _buildForm(context, ref, org),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, WidgetRef ref, dynamic org) {
    // Initialize controllers with current values if not already done
    if (_nameController.text.isEmpty) {
      _nameController.text = org.name;
      _businessTypeController.text = org.businessType;
      _gstController.text = org.gstNumber ?? '';
      _logoUrlController.text = org.logoUrl ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Organization'),
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Organization Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Organization Name',
                  hint: 'Enter organization name',
                  icon: Icons.business,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Organization name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Business Type
                _buildTextField(
                  controller: _businessTypeController,
                  label: 'Business Type',
                  hint: 'e.g., PG, Hostel, Apartment Complex',
                  icon: Icons.category,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Business type is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // GST Number
                _buildTextField(
                  controller: _gstController,
                  label: 'GST Number (Optional)',
                  hint: 'Enter GST number',
                  icon: Icons.receipt,
                ),
                const SizedBox(height: 16),

                // Branding Section
                Text(
                  'Branding',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // Logo Upload Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organization Logo',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Logo Preview
                        if (_logoPath != null || _logoUrlController.text.isNotEmpty)
                          Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _logoPath != null
                                  ? Image.file(
                                      File(_logoPath!),
                                      fit: BoxFit.contain,
                                    )
                                  : Image.network(
                                      _logoUrlController.text,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        if (_logoPath != null || _logoUrlController.text.isNotEmpty)
                          const SizedBox(height: 12),

                        // Error Message
                        if (_logoUploadError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _logoUploadError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        // Upload Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isSaving || _isUploadingLogo ? null : () => _pickAndUploadLogo(ref),
                            icon: _isUploadingLogo
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _logoPath != null || _logoUrlController.text.isNotEmpty
                                        ? Icons.edit
                                        : Icons.photo_camera,
                                  ),
                            label: Text(
                              _logoPath != null || _logoUrlController.text.isNotEmpty
                                  ? 'Change Logo'
                                  : 'Upload Logo',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click to upload or change logo (PNG, JPG, WebP)',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: (_isSaving || _isUploadingLogo) ? null : () => _saveOrganization(ref),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: (_isSaving || _isUploadingLogo) ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _saveOrganization(WidgetRef ref) async {
    // Validate inputs
    if (_nameController.text.isEmpty || _businessTypeController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updates = {
        'name': _nameController.text,
        'businessType': _businessTypeController.text,
        'gstNumber': _gstController.text.isEmpty ? null : _gstController.text,
        'logoUrl': _logoUrlController.text.isEmpty ? null : _logoUrlController.text,
      };

      await ref
          .read(organizationUpdateProvider(widget.organizationId).notifier)
          .updateOrganization(updates);

      if (mounted) {
        // Refresh the detail provider to show updated data
        ref.refresh(organizationDetailProvider(widget.organizationId));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
