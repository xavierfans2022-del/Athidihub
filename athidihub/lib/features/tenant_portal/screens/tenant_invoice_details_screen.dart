import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/features/tenant_portal/data/models/tenant_portal_models.dart';
import 'package:athidihub/features/tenant_portal/providers/tenant_portal_provider.dart';

final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class TenantInvoiceDetailsScreen extends ConsumerWidget {
  final TenantInvoice invoice;
  const TenantInvoiceDetailsScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dashboardAsync = ref.watch(tenantDashboardProvider);
    final organization = dashboardAsync.value?.organization;

    Color statusColor = switch (invoice.status) {
      'PAID' => AppColors.success,
      'OVERDUE' => AppColors.error,
      'CANCELLED' => cs.onSurfaceVariant,
      _ => AppColors.warning,
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(invoice.isPaid ? 'Payment Receipt' : 'Invoice Details',
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: false,
        actions: [
          if (invoice.pdfUrl != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: () => launchUrl(Uri.parse(invoice.pdfUrl!), mode: LaunchMode.externalApplication),
              tooltip: 'Download Invoice PDF',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Organization Logo & Name ──────────────────────────────
            if (organization != null) ...[
              Center(
                child: Column(
                  children: [
                    if (organization.logoUrl != null)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surface,
                          border: Border.all(color: cs.outline.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(organization.logoUrl!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withOpacity(0.1),
                        ),
                        child: Icon(Icons.business_rounded, size: 40, color: cs.primary),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      organization.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // ── Invoice Header ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: statusColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          switch (invoice.status) {
                            'PAID' => Icons.check_circle_rounded,
                            'OVERDUE' => Icons.warning_rounded,
                            'CANCELLED' => Icons.cancel_rounded,
                            _ => Icons.pending_rounded,
                          },
                          color: statusColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.monthLabel,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Invoice #${invoice.id.substring(0, 8).toUpperCase()}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          invoice.status,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Amount and due date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _fmt.format(invoice.totalAmount),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Due Date',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM yyyy').format(invoice.dueDate),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: invoice.isOverdue && !invoice.isPaid
                                  ? AppColors.error
                                  : cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Breakdown Section ─────────────────────────────────────
            Text(
              'Charge Breakdown',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: cs.outline),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _ChargeRow('Base Rent', invoice.baseRent, cs),
                  if (invoice.utilityCharges > 0) ...[
                    const Divider(height: 12),
                    _ChargeRow('Utilities', invoice.utilityCharges, cs, color: cs.primary),
                  ],
                  if (invoice.foodCharges > 0) ...[
                    const Divider(height: 12),
                    _ChargeRow('Food', invoice.foodCharges, cs, color: cs.primary),
                  ],
                  if (invoice.lateFee > 0) ...[
                    const Divider(height: 12),
                    _ChargeRow('Late Fee', invoice.lateFee, cs, color: AppColors.error, isAdditional: true),
                  ],
                  if (invoice.discount > 0) ...[
                    const Divider(height: 12),
                    _ChargeRow('Discount', -invoice.discount, cs, color: AppColors.success, isDiscount: true),
                  ],
                  Divider(height: 16, color: cs.outline),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        _fmt.format(invoice.totalAmount),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Payment Information ───────────────────────────────────
            if (invoice.payment != null) ...[
              Text(
                'Payment Information',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _InfoRow('Payment Method', _paymentMethod(invoice.payment!.method), cs),
                    const SizedBox(height: 12),
                    _InfoRow('Amount Paid', _fmt.format(invoice.payment!.amount), cs),
                    if (invoice.payment!.paidAt != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        'Paid On',
                        DateFormat('d MMM yyyy, hh:mm a').format(invoice.payment!.paidAt!),
                        cs,
                      ),
                    ],
                    if (invoice.payment!.gatewayTxnId != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        'Transaction ID',
                        invoice.payment!.gatewayTxnId!.length > 16
                            ? invoice.payment!.gatewayTxnId!.substring(0, 16) + '…'
                            : invoice.payment!.gatewayTxnId!,
                        cs,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Invoice Details ───────────────────────────────────────
            Text(
              'Additional Details',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: cs.outline),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _InfoRow('Invoice ID', invoice.id.substring(0, 8).toUpperCase(), cs),
                  const SizedBox(height: 12),
                  _InfoRow('Created On', DateFormat('d MMM yyyy').format(invoice.createdAt), cs),
                  const SizedBox(height: 12),
                  _InfoRow('Invoice Period', invoice.monthLabel, cs),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Payment Receipt (Production Level) ────────────────────
            if (invoice.isPaid && invoice.payment?.receiptUrl != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  border: Border.all(color: AppColors.success.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Payment Successful',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Payment ID: ${invoice.payment?.id.toUpperCase()}',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(invoice.payment!.receiptUrl!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Download Official Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Action Buttons ────────────────────────────────────────
            if (invoice.pdfUrl != null) ...[
              const SizedBox(height: 24),
              _ActionBtn(
                icon: Icons.file_download_rounded,
                label: 'Download Invoice PDF',
                subtitle: 'Get detailed invoice document',
                onTap: () async {
                  final uri = Uri.tryParse(invoice.pdfUrl!);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                cs: cs,
              ),
            ],

            // ── Help Section ──────────────────────────────────────────
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline_rounded, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Need Help?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'If you have questions about this invoice or your payment, please contact the property management through the app.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _paymentMethod(String method) => switch (method) {
    'UPI' => 'UPI Transfer',
    'CARD' => 'Credit/Debit Card',
    'NET_BANKING' => 'Net Banking',
    'WALLET' => 'Digital Wallet',
    'CASH' => 'Cash Payment',
    _ => method,
  };
}

// ─── Charge Row ───────────────────────────────────────────────────────────────
class _ChargeRow extends StatelessWidget {
  final String label;
  final double amount;
  final ColorScheme cs;
  final Color? color;
  final bool isAdditional;
  final bool isDiscount;

  const _ChargeRow(
    this.label,
    this.amount,
    this.cs, {
    this.color,
    this.isAdditional = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? cs.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${isDiscount ? '- ' : ''} ${_fmt.format(amount.abs())}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: displayColor,
          ),
        ),
      ],
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _InfoRow(this.label, this.value, this.cs);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: cs.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: cs.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
