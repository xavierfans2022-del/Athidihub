import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/beds/providers/bed_provider.dart';
import 'package:athidihub/features/beds/data/models/bed_model.dart';
import 'package:go_router/go_router.dart';

class AddEditBedScreen extends ConsumerStatefulWidget {
  final String roomId;
  final BedModel? bedToEdit;

  const AddEditBedScreen({super.key, required this.roomId, this.bedToEdit});

  @override
  ConsumerState<AddEditBedScreen> createState() => _AddEditBedScreenState();
}

class _AddEditBedScreenState extends ConsumerState<AddEditBedScreen> {
  late TextEditingController _bedNumberController;
  String? _selectedBedType;
  String? _selectedStatus;
  bool _isLoading = false;

  final bedTypes = ['STANDARD', 'BUNK', 'PREMIUM'];
  final bedStatuses = ['AVAILABLE', 'OCCUPIED', 'RESERVED', 'MAINTENANCE'];

  @override
  void initState() {
    super.initState();
    _bedNumberController = TextEditingController(text: widget.bedToEdit?.bedNumber ?? '');
    _selectedBedType = widget.bedToEdit?.bedType ?? 'STANDARD';
    _selectedStatus = widget.bedToEdit?.status ?? 'AVAILABLE';
  }

  @override
  void dispose() {
    _bedNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bedToEdit != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(isEditing ? 'Edit Bed' : 'Add Bed')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSection(context, 'Bed Number',
              TextField(
                controller: _bedNumberController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(hintText: 'e.g., 101, A1, etc.', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(height: 20),
            _buildFormSection(context, 'Bed Type',
              DropdownButtonFormField<String>(
                value: _selectedBedType,
                dropdownColor: colorScheme.surface,
                style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Inter'),
                items: bedTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _selectedBedType = value),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            ),
            const SizedBox(height: 20),
            _buildFormSection(context, 'Bed Status',
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                dropdownColor: colorScheme.surface,
                style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Inter'),
                items: bedStatuses.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                onChanged: (value) => setState(() => _selectedStatus = value),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBed,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEditing ? 'Update Bed' : 'Create Bed'),
              ),
            ),
          ],
        ),
      ),
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

  Future<void> _saveBed() async {
    if (_bedNumberController.text.isEmpty || _selectedBedType == null || _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = {'roomId': widget.roomId, 'bedNumber': _bedNumberController.text, 'bedType': _selectedBedType, 'status': _selectedStatus};
      if (widget.bedToEdit != null) {
        await ref.read(updateBedProvider((widget.bedToEdit!.id, data)).future);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bed updated successfully')));
      } else {
        await ref.read(createBedProvider(data).future);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bed created successfully')));
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
