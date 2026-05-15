import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/beds/providers/bed_provider.dart';
import 'package:athidihub/features/properties/providers/property_provider.dart';
import 'package:athidihub/features/rooms/providers/room_provider.dart';
import 'package:athidihub/features/tenants/providers/assignment_provider.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';

class AssignBedScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const AssignBedScreen({super.key, required this.tenantId});

  @override
  ConsumerState<AssignBedScreen> createState() => _AssignBedScreenState();
}

class _AssignBedScreenState extends ConsumerState<AssignBedScreen> {
  String? _selectedPropertyId;
  String? _selectedRoomId;
  String? _selectedBedId;

  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  bool _rentEdited = false;
  bool _depositEdited = false;

  @override
  void dispose() {
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  void _onBedSelected(String? bedId) {
    setState(() {
      _selectedBedId = bedId;
      // Reset edits so new bed's defaults load fresh
      _rentEdited = false;
      _depositEdited = false;
      _rentCtrl.clear();
      _depositCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (_selectedBedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bed')),
      );
      return;
    }

    final monthlyRent = _rentEdited ? double.tryParse(_rentCtrl.text) : null;
    final securityDeposit = _depositEdited ? double.tryParse(_depositCtrl.text) : null;

    final success = await ref.read(tenantBedAssignmentProvider.notifier).assignBed(
          tenantId: widget.tenantId,
          bedId: _selectedBedId!,
          monthlyRent: monthlyRent,
          securityDeposit: securityDeposit,
        );

    if (!mounted) return;
    if (success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bed assigned successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(tenantBedAssignmentProvider).error ?? 'Error assigning bed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final assignmentState = ref.watch(tenantBedAssignmentProvider);
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        title: const Text('Assign Bed'),
      ),
      body: propertiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: cs.error))),
        data: (properties) {
          if (properties.isEmpty) {
            return Center(child: Text('No properties available', style: tt.bodyMedium));
          }
          return ListView(
            padding: const EdgeInsets.all(AppConstants.spacingMD),
            children: [
              // ── Step 1: Property ──────────────────────────────
              Text('Property', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPropertyId,
                dropdownColor: cs.surface,
                decoration: const InputDecoration(labelText: 'Select Property'),
                items: properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) => setState(() {
                  _selectedPropertyId = v;
                  _selectedRoomId = null;
                  _onBedSelected(null);
                }),
              ),

              // ── Step 2: Room ──────────────────────────────────
              if (_selectedPropertyId != null) ...[
                const SizedBox(height: 24),
                Text('Room', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ref.watch(propertyRoomsProvider(_selectedPropertyId!)).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error: $err', style: TextStyle(color: cs.error)),
                  data: (rooms) {
                    if (rooms.isEmpty) return Text('No rooms in this property', style: tt.bodyMedium);
                    return DropdownButtonFormField<String>(
                      value: _selectedRoomId,
                      dropdownColor: cs.surface,
                      decoration: const InputDecoration(labelText: 'Select Room'),
                      items: rooms.map((r) => DropdownMenuItem(
                        value: r.id,
                        child: Text('Room ${r.roomNumber} · ${r.roomType} · ₹${r.monthlyRent.toStringAsFixed(0)}/mo'),
                      )).toList(),
                      onChanged: (v) => setState(() {
                        _selectedRoomId = v;
                        _onBedSelected(null);
                      }),
                    );
                  },
                ),
              ],

              // ── Step 3: Bed ───────────────────────────────────
              if (_selectedRoomId != null) ...[
                const SizedBox(height: 24),
                Text('Bed', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ref.watch(bedsByRoomProvider(_selectedRoomId!)).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error: $err', style: TextStyle(color: cs.error)),
                  data: (beds) {
                    final available = beds.where((b) => b.status.toUpperCase() == 'AVAILABLE').toList();
                    if (available.isEmpty) return Text('No available beds in this room', style: tt.bodyMedium);
                    return DropdownButtonFormField<String>(
                      value: _selectedBedId,
                      dropdownColor: cs.surface,
                      decoration: const InputDecoration(labelText: 'Select Bed'),
                      items: available.map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text('Bed ${b.bedNumber} · ${b.bedType}'),
                      )).toList(),
                      onChanged: _onBedSelected,
                    );
                  },
                ),
              ],

              // ── Step 4: Rent summary & override ──────────────
              if (_selectedBedId != null) ...[
                const SizedBox(height: 24),
                ref.watch(bedRentInfoProvider(_selectedBedId!)).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (info) {
                    if (!_rentEdited && _rentCtrl.text.isEmpty) {
                      _rentCtrl.text = info.monthlyRent.toStringAsFixed(0);
                    }
                    if (!_depositEdited && _depositCtrl.text.isEmpty) {
                      _depositCtrl.text = info.securityDeposit.toStringAsFixed(0);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary card
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(0.06),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                  border: Border(bottom: BorderSide(color: cs.outline)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 15, color: cs.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Room ${info.roomNumber} · ${info.roomType} defaults',
                                      style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              // Rent & Deposit row
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.currency_rupee_rounded, size: 13, color: cs.onSurfaceVariant),
                                                const SizedBox(width: 4),
                                                Text('Room Rent', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${info.monthlyRent.toStringAsFixed(0)}/mo',
                                              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    VerticalDivider(width: 1, color: cs.outline),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.savings_outlined, size: 13, color: cs.onSurfaceVariant),
                                                const SizedBox(width: 4),
                                                Text('Deposit', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${info.securityDeposit.toStringAsFixed(0)}',
                                              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Override for this tenant (optional)',
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _rentCtrl,
                                label: 'Monthly Rent (₹)',
                                hint: info.monthlyRent.toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.currency_rupee_rounded,
                                onChanged: (_) => setState(() => _rentEdited = true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _depositCtrl,
                                label: 'Security Deposit (₹)',
                                hint: info.securityDeposit.toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.savings_outlined,
                                onChanged: (_) => setState(() => _depositEdited = true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: assignmentState.isLoading ? null : _submit,
                child: assignmentState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirm Assignment'),
              ),
            ],
          );
        },
      ),
    );
  }
}
