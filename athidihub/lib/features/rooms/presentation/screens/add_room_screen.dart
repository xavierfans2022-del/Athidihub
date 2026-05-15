import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/rooms/providers/room_provider.dart';
import 'package:athidihub/features/rooms/data/models/room_model.dart';
import 'package:go_router/go_router.dart';

class AddEditRoomScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final RoomModel? roomToEdit;

  const AddEditRoomScreen({super.key, required this.propertyId, this.roomToEdit});

  @override
  ConsumerState<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends ConsumerState<AddEditRoomScreen> {
  late TextEditingController _roomNumberController;
  late TextEditingController _floorNumberController;
  late TextEditingController _rentController;
  late TextEditingController _depositController;
  late TextEditingController _capacityController;
  String? _selectedRoomType;
  bool _isAC = false;
  bool _isLoading = false;

  final roomTypes = ['SINGLE', 'DOUBLE', 'TRIPLE', 'QUAD', 'DORMITORY'];

  @override
  void initState() {
    super.initState();
    _roomNumberController = TextEditingController(text: widget.roomToEdit?.roomNumber ?? '');
    _floorNumberController = TextEditingController(text: widget.roomToEdit?.floorNumber.toString() ?? '');
    _rentController = TextEditingController(text: widget.roomToEdit?.monthlyRent.toStringAsFixed(2) ?? '');
    _depositController = TextEditingController(text: widget.roomToEdit?.securityDeposit.toStringAsFixed(2) ?? '');
    _capacityController = TextEditingController(text: widget.roomToEdit?.capacity.toString() ?? '');
    _selectedRoomType = widget.roomToEdit?.roomType ?? 'SINGLE';
    _isAC = widget.roomToEdit?.isAC ?? false;
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorNumberController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.roomToEdit != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        title: Text(isEditing ? 'Edit Room' : 'Add Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSection(context, 'Room Number',
              TextField(controller: _roomNumberController, style: TextStyle(color: colorScheme.onSurface), decoration: _dec(context, 'e.g., 101, A1, etc.'), keyboardType: TextInputType.text)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildFormSection(context, 'Floor Number',
                  TextField(controller: _floorNumberController, style: TextStyle(color: colorScheme.onSurface), decoration: _dec(context, '1, 2, 3...'), keyboardType: TextInputType.number))),
                const SizedBox(width: 16),
                Expanded(child: _buildFormSection(context, 'Capacity',
                  TextField(controller: _capacityController, style: TextStyle(color: colorScheme.onSurface), decoration: _dec(context, '1, 2, 3...'), keyboardType: TextInputType.number))),
              ],
            ),
            const SizedBox(height: 20),
            _buildFormSection(context, 'Room Type',
              DropdownButtonFormField<String>(
                value: _selectedRoomType,
                dropdownColor: colorScheme.surface,
                style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Inter'),
                items: roomTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _selectedRoomType = value),
                decoration: _dec(context, ''),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildFormSection(context, 'Monthly Rent',
                  TextField(controller: _rentController, style: TextStyle(color: colorScheme.onSurface), decoration: _dec(context, '₹'), keyboardType: const TextInputType.numberWithOptions(decimal: true)))),
                const SizedBox(width: 16),
                Expanded(child: _buildFormSection(context, 'Security Deposit',
                  TextField(controller: _depositController, style: TextStyle(color: colorScheme.onSurface), decoration: _dec(context, '₹'), keyboardType: const TextInputType.numberWithOptions(decimal: true)))),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outline)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Air Conditioning (AC)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                  Switch(value: _isAC, onChanged: (value) => setState(() => _isAC = value), activeColor: colorScheme.primary),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveRoom,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEditing ? 'Update Room' : 'Create Room'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(BuildContext context, String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

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

  Future<void> _saveRoom() async {
    if (_roomNumberController.text.isEmpty || _floorNumberController.text.isEmpty || _rentController.text.isEmpty || _depositController.text.isEmpty || _capacityController.text.isEmpty || _selectedRoomType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = {
        'propertyId': widget.propertyId, 'roomNumber': _roomNumberController.text,
        'floorNumber': int.parse(_floorNumberController.text), 'roomType': _selectedRoomType,
        'isAC': _isAC, 'monthlyRent': double.parse(_rentController.text),
        'securityDeposit': double.parse(_depositController.text), 'capacity': int.parse(_capacityController.text),
      };
      if (widget.roomToEdit != null) {
        await ref.read(updateRoomProvider((widget.roomToEdit!.id, data)).future);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room updated successfully')));
      } else {
        await ref.read(createRoomProvider(data).future);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room created successfully')));
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
