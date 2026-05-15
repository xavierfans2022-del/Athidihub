import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/features/tenant_portal/data/models/tenant_portal_models.dart';
import 'package:athidihub/features/tenant_portal/providers/tenant_portal_provider.dart';
import 'package:athidihub/features/tenant_portal/screens/tenant_invoice_details_screen.dart';

final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

const _months = ['All','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
final _years  = List.generate(5, (i) => DateTime.now().year - i);

class TenantPaymentHistoryScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const TenantPaymentHistoryScreen({super.key, this.initialIndex = 0});
  @override
  ConsumerState<TenantPaymentHistoryScreen> createState() => _State();
}

class _State extends ConsumerState<TenantPaymentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Payments & Invoices',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(tenantPaymentsProvider);
              ref.invalidate(tenantInvoicesProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          indicatorColor: cs.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [Tab(text: 'Payment History'), Tab(text: 'Invoices')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _PaymentsTab(),
          _InvoicesTab(),
        ],
      ),
    );
  }
}

// ─── Payments Tab ─────────────────────────────────────────────────────────────
class _PaymentsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends ConsumerState<_PaymentsTab> {
  int _selectedMonth = 0;  // 0 = All
  int _selectedYear  = DateTime.now().year;

  void _applyFilter() {
    ref.read(paymentFilterProvider.notifier).state = InvoiceFilter(
      month: _selectedMonth == 0 ? null : _selectedMonth,
      year: _selectedYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final paymentsAsync = ref.watch(tenantPaymentsProvider);

    return Column(
      children: [
        // ── Filter Bar ───────────────────────────────────────────────────
        _FilterBar(
          selectedMonth: _selectedMonth,
          selectedYear: _selectedYear,
          onMonthChanged: (m) { setState(() => _selectedMonth = m); _applyFilter(); },
          onYearChanged:  (y) { setState(() => _selectedYear  = y); _applyFilter(); },
          cs: cs,
        ),
        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: paymentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Empty(icon: Icons.error_outline_rounded, message: e.toString()),
            data: (result) {
              if (result.data.isEmpty) {
                return _Empty(
                  icon: Icons.receipt_long_outlined,
                  message: 'No payments found',
                  sub: _selectedMonth != 0 ? 'Try a different filter' : 'Payments will appear here once you pay',
                );
              }
              // Summary card
              final totalPaid = result.data.fold<double>(0, (s, p) => s + p.amount);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryCard(total: totalPaid, count: result.total, cs: cs),
                  const SizedBox(height: 12),
                  ...result.data.map((p) => _PaymentCard(payment: p, cs: cs, theme: theme)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Invoices Tab ─────────────────────────────────────────────────────────────
class _InvoicesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends ConsumerState<_InvoicesTab> {
  int _selectedMonth = 0;
  int _selectedYear  = DateTime.now().year;

  void _applyFilter() {
    ref.read(invoiceFilterProvider.notifier).state = InvoiceFilter(
      month: _selectedMonth == 0 ? null : _selectedMonth,
      year: _selectedYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final invoicesAsync = ref.watch(tenantInvoicesProvider);

    return Column(
      children: [
        _FilterBar(
          selectedMonth: _selectedMonth,
          selectedYear: _selectedYear,
          onMonthChanged: (m) { setState(() => _selectedMonth = m); _applyFilter(); },
          onYearChanged:  (y) { setState(() => _selectedYear  = y); _applyFilter(); },
          cs: cs,
        ),
        Expanded(
          child: invoicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Empty(icon: Icons.error_outline_rounded, message: e.toString()),
            data: (result) {
              if (result.data.isEmpty) {
                return _Empty(
                  icon: Icons.receipt_outlined,
                  message: 'No invoices found',
                  sub: 'Your monthly invoices will appear here',
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: result.data.map((inv) => _InvoiceCard(invoice: inv, cs: cs, theme: theme)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final ColorScheme cs;

  const _FilterBar({
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outline)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, size: 16),
          const SizedBox(width: 8),
          // Month picker
          Expanded(
            child: _Chip(
              label: _months[selectedMonth],
              onTap: () async {
                final result = await showModalBottomSheet<int>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => _MonthPicker(selected: selectedMonth),
                );
                if (result != null) onMonthChanged(result);
              },
              cs: cs,
              isActive: selectedMonth != 0,
            ),
          ),
          const SizedBox(width: 8),
          // Year picker
          _Chip(
            label: '$selectedYear',
            onTap: () async {
              final result = await showModalBottomSheet<int>(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _YearPicker(selected: selectedYear),
              );
              if (result != null) onYearChanged(result);
            },
            cs: cs,
            isActive: false,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool isActive;
  const _Chip({required this.label, required this.onTap, required this.cs, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? cs.primary.withOpacity(0.12) : cs.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? cs.primary : cs.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? cs.primary : cs.onSurfaceVariant)),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 14, color: isActive ? cs.primary : cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  final int selected;
  const _MonthPicker({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Month', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16, color: cs.onSurface)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_months.length, (i) {
              final isSelected = i == selected;
              return GestureDetector(
                onTap: () => Navigator.pop(context, i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? cs.primary : cs.outline),
                  ),
                  child: Text(_months[i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? cs.onPrimary : cs.onSurface,
                      )),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _YearPicker extends StatelessWidget {
  final int selected;
  const _YearPicker({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Year', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16, color: cs.onSurface)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _years.map((y) {
              final isSelected = y == selected;
              return GestureDetector(
                onTap: () => Navigator.pop(context, y),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? cs.primary : cs.outline),
                  ),
                  child: Text('$y',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? cs.onPrimary : cs.onSurface)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final double total;
  final int count;
  final ColorScheme cs;
  const _SummaryCard({required this.total, required this.count, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.success.withOpacity(0.15), AppColors.success.withOpacity(0.05)]),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Paid', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(_fmt.format(total), style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.success)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Payments', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text('$count', style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Payment Card ─────────────────────────────────────────────────────────────
class _PaymentCard extends StatelessWidget {
  final TenantPayment payment;
  final ColorScheme cs;
  final ThemeData theme;
  const _PaymentCard({required this.payment, required this.cs, required this.theme});

  String _methodLabel(String method) => switch (method) {
    'UPI'         => 'UPI',
    'CARD'        => 'Card',
    'NET_BANKING' => 'Net Banking',
    'WALLET'      => 'Wallet',
    'CASH'        => 'Cash',
    _             => method,
  };

  IconData _methodIcon(String method) => switch (method) {
    'UPI'         => Icons.qr_code_rounded,
    'CARD'        => Icons.credit_card_rounded,
    'NET_BANKING' => Icons.account_balance_rounded,
    'WALLET'      => Icons.account_balance_wallet_rounded,
    'CASH'        => Icons.money_rounded,
    _             => Icons.payment_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (payment.invoice != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TenantInvoiceDetailsScreen(invoice: payment.invoice!),
            ),
          );
        } else if (payment.receiptUrl != null) {
          final uri = Uri.tryParse(payment.receiptUrl!);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.invoice != null ? payment.invoice!.monthLabel : 'Payment',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(_methodIcon(payment.method), size: 11, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(_methodLabel(payment.method), style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant)),
                          if (payment.paidAt != null) ...[
                            Text(' · ', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                            Text(DateFormat('d MMM yyyy, hh:mm a').format(payment.paidAt!), style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(_fmt.format(payment.amount), style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.success)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16, color: cs.onSurfaceVariant.withOpacity(0.5)),
              ],
            ),
          if (payment.invoice != null || payment.receiptUrl != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Column(
              children: [
                if (payment.invoice != null && payment.invoice!.pdfUrl != null) ...[
                  Row(
                    children: [
                      _DownloadBtn(url: payment.invoice!.pdfUrl!, label: 'Download Invoice', cs: cs),
                      const Spacer(),
                      if (payment.gatewayTxnId != null)
                        Text('Txn: ${payment.gatewayTxnId!.length > 12 ? payment.gatewayTxnId!.substring(0, 12) + '…' : payment.gatewayTxnId}',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
                if (payment.receiptUrl != null) ...[
                  if (payment.invoice != null && payment.invoice!.pdfUrl != null)
                    const SizedBox(height: 8),
                  Row(
                    children: [
                      _DownloadBtn(url: payment.receiptUrl!, label: 'Download Receipt', cs: cs),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
}

// ─── Invoice Card ─────────────────────────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final TenantInvoice invoice;
  final ColorScheme cs;
  final ThemeData theme;
  const _InvoiceCard({required this.invoice, required this.cs, required this.theme});

  Color _statusColor() => switch (invoice.status) {
    'PAID'      => AppColors.success,
    'OVERDUE'   => AppColors.error,
    'CANCELLED' => cs.onSurfaceVariant,
    _           => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TenantInvoiceDetailsScreen(invoice: invoice),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
                    child: Center(child: Text(invoice.month.toString().padLeft(2, '0'), style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w800, color: statusColor))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(invoice.monthLabel, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text('Created: ${DateFormat('d MMM').format(invoice.createdAt)}', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: cs.onSurfaceVariant)),
                            Text(' · ', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
                            Text('Due: ${DateFormat('d MMM yyyy').format(invoice.dueDate)}', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: invoice.isOverdue && !invoice.isPaid ? AppColors.error : cs.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmt.format(invoice.totalAmount), style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(invoice.status, style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.3)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Breakdown
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _BreakdownRow(label: 'Base Rent', amount: invoice.baseRent, cs: cs),
                  if (invoice.utilityCharges > 0) _BreakdownRow(label: 'Utilities', amount: invoice.utilityCharges, cs: cs),
                  if (invoice.foodCharges > 0) _BreakdownRow(label: 'Food', amount: invoice.foodCharges, cs: cs),
                  if (invoice.lateFee > 0) _BreakdownRow(label: 'Late Fee', amount: invoice.lateFee, cs: cs, isNegative: false, color: AppColors.error),
                  if (invoice.discount > 0) _BreakdownRow(label: 'Discount', amount: invoice.discount, cs: cs, isNegative: true),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                      Text(_fmt.format(invoice.totalAmount), style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface)),
                    ],
                  ),
                  if (invoice.pdfUrl != null) ...[
                    const SizedBox(height: 10),
                    _DownloadBtn(url: invoice.pdfUrl!, label: 'Download Invoice PDF', cs: cs),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final ColorScheme cs;
  final bool isNegative;
  final Color? color;
  const _BreakdownRow({required this.label, required this.amount, required this.cs, this.isNegative = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isNegative ? AppColors.success : cs.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.onSurfaceVariant)),
          Text('${isNegative ? '- ' : ''}${_fmt.format(amount)}', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}

// ─── Download Button ──────────────────────────────────────────────────────────
class _DownloadBtn extends StatelessWidget {
  final String url;
  final String label;
  final ColorScheme cs;
  const _DownloadBtn({required this.url, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? sub;
  const _Empty({required this.icon, required this.message, this.sub});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: cs.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
