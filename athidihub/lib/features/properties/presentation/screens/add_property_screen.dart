import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/onboarding/providers/onboarding_provider.dart';
import 'package:athidihub/features/properties/providers/property_provider.dart';
import 'package:athidihub/features/properties/data/models/property_model.dart';
import 'package:go_router/go_router.dart';

class AddEditPropertyScreen extends ConsumerStatefulWidget {
  final PropertyModel? propertyToEdit;
  final String? organizationId;

  const AddEditPropertyScreen({super.key, this.organizationId, this.propertyToEdit});

  @override
  ConsumerState<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends ConsumerState<AddEditPropertyScreen> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _floorsController;
  late TextEditingController _amenityController;
  List<String> _amenities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.propertyToEdit?.name ?? '');
    _addressController = TextEditingController(text: widget.propertyToEdit?.address ?? '');
    _cityController = TextEditingController(text: widget.propertyToEdit?.city ?? '');
    _stateController = TextEditingController(text: widget.propertyToEdit?.state ?? '');
    _floorsController = TextEditingController(text: widget.propertyToEdit?.totalFloors.toString() ?? '');
    _amenityController = TextEditingController();
    _amenities = List.from(widget.propertyToEdit?.amenities ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _floorsController.dispose();
    _amenityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.propertyToEdit != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        title: Text(isEditing ? 'Edit Property' : 'Add Property')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSection(context, 'Property Name',
              TextField(controller: _nameController, style: TextStyle(color: colorScheme.onSurface), decoration: _inputDecoration(context, 'Enter property name'))),
            const SizedBox(height: 20),
            _buildFormSection(context, 'Address',
              TextField(controller: _addressController, style: TextStyle(color: colorScheme.onSurface), decoration: _inputDecoration(context, 'Enter full address'), maxLines: 2)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildFormSection(context, 'City',
                  TextField(controller: _cityController, style: TextStyle(color: colorScheme.onSurface), decoration: _inputDecoration(context, 'City')))),
                const SizedBox(width: 16),
                Expanded(child: _buildFormSection(context, 'State',
                  TextField(controller: _stateController, style: TextStyle(color: colorScheme.onSurface), decoration: _inputDecoration(context, 'State')))),
              ],
            ),
            const SizedBox(height: 20),
            _buildFormSection(context, 'Total Floors',
              TextField(controller: _floorsController, style: TextStyle(color: colorScheme.onSurface), decoration: _inputDecoration(context, 'Number of floors'), keyboardType: TextInputType.number)),
            const SizedBox(height: 20),
            _buildFormSection(context, 'Amenities',
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _amenityController, style: TextStyle(color: colorScheme.onSurface), decoration: _inputDecoration(context, 'Add amenity (WiFi, Parking, etc.)'))),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                        child: IconButton(icon: const Icon(Icons.add, color: AppColors.white), onPressed: _addAmenity),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_amenities.isNotEmpty)
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _amenities.map((amenity) => Chip(
                        label: Text(amenity),
                        onDeleted: () => setState(() => _amenities.remove(amenity)),
                        backgroundColor: colorScheme.primary.withAlpha(26),
                      )).toList(),
                    )
                  else
                    Text('No amenities added yet', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProperty,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEditing ? 'Update Property' : 'Create Property'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildFormSection(BuildContext context, String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _addAmenity() {
    if (_amenityController.text.isNotEmpty) {
      setState(() { _amenities.add(_amenityController.text); _amenityController.clear(); });
    }
  }

  Future<void> _saveProperty() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty || _cityController.text.isEmpty || _stateController.text.isEmpty || _floorsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final organizationId = widget.organizationId ?? ref.read(onboardingNotifierProvider).orgId;
      if (widget.propertyToEdit == null && (organizationId == null || organizationId.isEmpty)) {
        throw Exception('No organization is selected. Complete organization setup first.');
      }
      final Map<String, dynamic> data = {
        'name': _nameController.text, 'address': _addressController.text,
        'city': _cityController.text, 'state': _stateController.text,
        'totalFloors': int.parse(_floorsController.text), 'amenities': _amenities, 'imageUrls': [],
      };
      if (widget.propertyToEdit == null) data['organizationId'] = organizationId;
      if (widget.propertyToEdit != null) {
        await ref.read(updatePropertyProvider((widget.propertyToEdit!.id, data)).future);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property updated successfully')));
      } else {
        await ref.read(createPropertyProvider(data).future);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property created successfully')));
      }
      if (mounted) { ref.refresh(propertiesProvider); context.pop(true); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
