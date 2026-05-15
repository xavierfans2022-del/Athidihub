import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/theme/app_semantic_colors.dart';
import 'package:athidihub/features/invoices/providers/invoice_provider.dart';
import 'package:athidihub/features/payments/providers/payment_provider.dart';
import 'package:athidihub/features/payments/presentation/screens/payment_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));
    final paymentsAsync = ref.watch(paymentsByInvoiceProvider(invoiceId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Invoice Detail'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () async {
              final invoice = await ref.read(invoiceDetailProvider(invoiceId).future);
              await _downloadPdf(context, invoice);
            },
          ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: colorScheme.error))),
        data: (invoice) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context, invoice),
              const SizedBox(height: 16),
              _buildActions(context, ref, invoice.id),
              const SizedBox(height: 16),
              _buildSummarySection(context, invoice),
              const SizedBox(height: 16),
              _buildPaymentBreakdown(context, invoice),
              const SizedBox(height: 16),
              Text('Payments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              paymentsAsync.when(
                loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Error loading payments: $e', style: TextStyle(color: colorScheme.error)),
                data: (payments) {
                  if (payments.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colorScheme.outline)),
                      child: Text('No payments recorded yet.', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    );
                  }
                  return ListView.separated(
                    itemCount: payments.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final payment = payments[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colorScheme.outline)),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: colorScheme.primary.withAlpha(20),
                              child: Icon(Icons.payments_outlined, size: 18, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('₹${payment.amount.toStringAsFixed(2)}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text('${payment.method} • ${payment.status}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Text(payment.paidAt ?? '', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, dynamic invoice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INVOICE', style: TextStyle(color: AppColors.white70, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Invoice #${invoice.id.substring(0, 8).toUpperCase()}', style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(invoice.tenant?['name'] ?? invoice.tenantId, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(
            children: [
              _statusChip(context, invoice.status),
              const SizedBox(width: 10),
              Text(DateFormat('dd MMM yyyy').format(invoice.dueDate), style: const TextStyle(color: AppColors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final isPaid = status.toUpperCase() == 'PAID';
    final semantic = Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.dark;
    final bg = isPaid ? semantic.successBg : semantic.warningBg;
    final fg = isPaid ? semantic.success : semantic.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.toUpperCase(), style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, String id) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(invoiceId: id))),
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: const Text('Record Payment'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final invoice = await ref.read(invoiceDetailProvider(id).future);
              await _downloadPdf(context, invoice);
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Download PDF'),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, dynamic invoice) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = [
      ('Base Rent', invoice.baseRent), ('Utility Charges', invoice.utilityCharges),
      ('Food Charges', invoice.foodCharges), ('Late Fee', invoice.lateFee), ('Discount', -invoice.discount),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: colorScheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invoice Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.$1, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                Text('₹${(entry.$2 as double).toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          )),
          Divider(height: 24, color: colorScheme.outline),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text('₹${invoice.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(BuildContext context, dynamic invoice) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monthName = DateFormat.MMMM().format(DateTime(invoice.year, invoice.month));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: colorScheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Billing Period', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('$monthName ${invoice.year}', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Text('Generated on ${DateFormat('dd MMM yyyy').format(invoice.createdAt)}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, dynamic invoice) async {
    try {
      final pdf = pw.Document();
      final monthName = DateFormat.MMMM().format(DateTime(invoice.year, invoice.month));
      final logoImage = await _resolveLogoImage(invoice);
      pdf.addPage(pw.Page(
        build: (pw.Context ctx) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 54,
                    height: 54,
                    decoration: pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(10)),
                    child: pw.ClipRRect(
                      horizontalRadius: 10,
                      verticalRadius: 10,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ATHIDIHUB INVOICE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Billing statement', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text('Invoice #: ${invoice.id}'),
              pw.Text('Tenant: ${invoice.tenant?['name'] ?? invoice.tenantId}'),
              pw.Text('Billing Period: $monthName ${invoice.year}'),
              pw.Text('Due Date: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}'),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(width: 0.6),
                columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1.5)},
                children: [
                  _pdfRow('Base Rent', invoice.baseRent), _pdfRow('Utility Charges', invoice.utilityCharges),
                  _pdfRow('Food Charges', invoice.foodCharges), _pdfRow('Late Fee', invoice.lateFee),
                  _pdfRow('Discount', -invoice.discount), _pdfRow('Total Amount', invoice.totalAmount, bold: true),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text('Status: ${invoice.status}'),
            ],
          ),
        ),
      ));
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'invoice_${invoice.id.substring(0, 8)}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      if (context.mounted) {
        await OpenFilex.open(file.path);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF saved to ${file.path}')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    }
  }

  Future<pw.ImageProvider> _resolveLogoImage(dynamic invoice) async {
    final organization = invoice.tenant?['organization'];
    final logoUrl = organization is Map ? organization['logoUrl'] as String? : null;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(logoUrl);
        final client = HttpClient();
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode == HttpStatus.ok) {
          final bytes = await consolidateHttpClientResponseBytes(response);
          return pw.MemoryImage(bytes);
        }
      } catch (_) {
        // Fall through to the local app logo.
      }
    }

    final data = await rootBundle.load('assets/images/Athidihub_logo.png');
    return pw.MemoryImage(data.buffer.asUint8List());
  }

  pw.TableRow _pdfRow(String label, num value, {bool bold = false}) {
    final textStyle = pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.TableRow(children: [
      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(label, style: textStyle)),
      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('₹${value.toStringAsFixed(2)}', style: textStyle)),
    ]);
  }
}
