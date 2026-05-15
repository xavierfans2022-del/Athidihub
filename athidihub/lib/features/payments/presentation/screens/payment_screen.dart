import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/features/payments/providers/payment_provider.dart';
import 'package:athidihub/features/invoices/providers/invoice_provider.dart';
import 'package:athidihub/features/invoices/data/models/invoice_model.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String? invoiceId;
  const PaymentScreen({super.key, this.invoiceId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = 'UPI';

  static const _methods = ['UPI', 'CARD', 'NET_BANKING', 'CASH'];
  static const _methodLabels = {
    'UPI': 'UPI',
    'CARD': 'Debit / Credit Card',
    'NET_BANKING': 'Net Banking',
    'CASH': 'Cash',
  };
  static const _methodIcons = {
    'UPI': Icons.qr_code_rounded,
    'CARD': Icons.credit_card_rounded,
    'NET_BANKING': Icons.account_balance_rounded,
    'CASH': Icons.payments_rounded,
  };

  Future<void> _confirm(InvoiceModel invoice) async {
    final success = await ref.read(paymentNotifierProvider.notifier).recordPayment(
          invoiceId: invoice.id,
          tenantId: invoice.tenantId,
          amount: invoice.totalAmount,
          method: _selectedMethod,
        );
    if (!mounted) return;
    if (success) {
      ref.invalidate(invoicesProvider('PENDING'));
      ref.invalidate(invoicesProvider('OVERDUE'));
      ref.invalidate(invoiceDetailProvider(invoice.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
      context.go('/invoices');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(paymentNotifierProvider).error ?? 'Payment failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          if (widget.invoiceId != null)
            RefreshButton(
              label: 'Refresh',
              onRefresh: () async {
                ref.invalidate(invoiceDetailProvider(widget.invoiceId!));
                await ref.read(invoiceDetailProvider(widget.invoiceId!).future);
              },
            ),
        ],
      ),
      body: widget.invoiceId == null
          ? Center(child: Text('No invoice selected', style: TextStyle(color: cs.onSurfaceVariant)))
          : ref.watch(invoiceDetailProvider(widget.invoiceId!)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _buildError(context, err.toString()),
              data: (invoice) => _buildBody(context, invoice),
            ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text('Failed to load invoice', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(msg, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(invoiceDetailProvider(widget.invoiceId!)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, InvoiceModel invoice) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final state = ref.watch(paymentNotifierProvider);

    final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthLabel = invoice.month > 0 && invoice.month <= 12
        ? monthNames[invoice.month]
        : '?';
    final tenantName = (invoice.tenant?['name'] ?? invoice.tenant?['fullName']) as String? ?? 'Tenant';

    // Block if already paid
    if (invoice.status == 'PAID') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success),
              ),
              const SizedBox(height: 16),
              Text('Already Paid', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('This invoice has been paid.', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/invoices'),
                child: const Text('Back to Invoices'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Invoice summary card ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white20,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$monthLabel ${invoice.year}',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white),
                        ),
                        Text(
                          tenantName,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.white70),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white20,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        invoice.status,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Total Amount', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.white70)),
                const SizedBox(height: 4),
                Text(
                  '₹${invoice.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.white),
                ),
                const SizedBox(height: 16),
                // Breakdown
                _buildBreakdownRow('Base Rent', invoice.baseRent),
                if (invoice.utilityCharges > 0) _buildBreakdownRow('Utility', invoice.utilityCharges),
                if (invoice.foodCharges > 0) _buildBreakdownRow('Food', invoice.foodCharges),
                if (invoice.lateFee > 0) _buildBreakdownRow('Late Fee', invoice.lateFee),
                if (invoice.discount > 0) _buildBreakdownRow('Discount', -invoice.discount),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Payment method ────────────────────────────────────
          Text('Payment Method', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          ..._methods.map((method) {
            final isSelected = _selectedMethod == method;
            return GestureDetector(
              onTap: () => setState(() => _selectedMethod = method),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary.withOpacity(0.06) : cs.surface,
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outline,
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primary.withOpacity(0.1) : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_methodIcons[method]!, size: 18, color: isSelected ? cs.primary : cs.onSurfaceVariant),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _methodLabels[method]!,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? cs.primary : cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: cs.primary, size: 20)
                    else
                      Icon(Icons.radio_button_unchecked_rounded, color: cs.outline, size: 20),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 32),

          // ── Confirm button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : () => _confirm(invoice),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: state.isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Confirm Payment · ₹${invoice.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Payment will be marked as SUCCESS immediately',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount) {
    final isNegative = amount < 0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.white70)),
          const Spacer(),
          Text(
            '${isNegative ? '-' : '+'}₹${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isNegative ? const Color(0xFF86EFAC) : AppColors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
