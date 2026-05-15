import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/features/invoices/providers/invoice_provider.dart';
import 'package:athidihub/shared/widgets/app_text_field.dart';

class GenerateInvoiceSheet extends ConsumerStatefulWidget {
  final String tenantId;
  final String tenantName;
  final double assignedRent;

  const GenerateInvoiceSheet({
    super.key,
    required this.tenantId,
    required this.tenantName,
    required this.assignedRent,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String tenantId,
    required String tenantName,
    required double assignedRent,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GenerateInvoiceSheet(
        tenantId: tenantId,
        tenantName: tenantName,
        assignedRent: assignedRent,
      ),
    );
  }

  @override
  ConsumerState<GenerateInvoiceSheet> createState() => _GenerateInvoiceSheetState();
}

class _GenerateInvoiceSheetState extends ConsumerState<GenerateInvoiceSheet> {
  final _utilityCtrl = TextEditingController();
  final _foodCtrl = TextEditingController();
  final _lateFeeCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  final _now = DateTime.now();
  late int _selectedMonth;
  late int _selectedYear;
  bool _isLoading = false;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = _now.month;
    _selectedYear = _now.year;
  }

  @override
  void dispose() {
    _utilityCtrl.dispose();
    _foodCtrl.dispose();
    _lateFeeCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  double get _utility => double.tryParse(_utilityCtrl.text) ?? 0;
  double get _food => double.tryParse(_foodCtrl.text) ?? 0;
  double get _lateFee => double.tryParse(_lateFeeCtrl.text) ?? 0;
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => widget.assignedRent + _utility + _food + _lateFee - _discount;

  Future<void> _generate() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(invoiceRepositoryProvider).generateInvoice(
            tenantId: widget.tenantId,
            month: _selectedMonth,
            year: _selectedYear,
            utilityCharges: _utility,
            foodCharges: _food,
            lateFee: _lateFee,
            discount: _discount,
          );
      if (!mounted) return;
      ref.invalidate(invoicesProvider('PENDING'));
      ref.invalidate(tenantInvoicesProvider(widget.tenantId));
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice generated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('already exists')
          ? 'Invoice for this month already exists'
          : 'Failed to generate invoice';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Generate Invoice', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(widget.tenantName, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),

            // Month / Year
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    dropdownColor: cs.surface,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: List.generate(12, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(_months[i]),
                    )),
                    onChanged: (v) => setState(() => _selectedMonth = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    dropdownColor: cs.surface,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: List.generate(3, (i) => DropdownMenuItem(
                      value: _now.year - 1 + i,
                      child: Text('${_now.year - 1 + i}'),
                    )),
                    onChanged: (v) => setState(() => _selectedYear = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Base rent (read-only)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.home_outlined, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text('Base Rent', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const Spacer(),
                  Text(
                    '₹${widget.assignedRent.toStringAsFixed(0)}',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _utilityCtrl,
                    label: 'Utility (₹)',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.bolt_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _foodCtrl,
                    label: 'Food (₹)',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.restaurant_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _lateFeeCtrl,
                    label: 'Late Fee (₹)',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.timer_off_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _discountCtrl,
                    label: 'Discount (₹)',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.discount_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text('Total', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                  const Spacer(),
                  Text(
                    '₹${_total.toStringAsFixed(0)}',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generate,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Generate Invoice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
