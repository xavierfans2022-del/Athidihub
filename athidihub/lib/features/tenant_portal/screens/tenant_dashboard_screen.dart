import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/features/tenant_portal/data/models/tenant_portal_models.dart';
import 'package:athidihub/features/tenant_portal/providers/tenant_portal_provider.dart';
import 'package:athidihub/features/tenant_portal/screens/tenant_invoice_details_screen.dart';
import 'package:athidihub/features/tenant_portal/screens/tenant_payment_history_screen.dart';
import 'package:athidihub/shared/widgets/language_selector_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class TenantDashboardScreen extends ConsumerWidget {
  const TenantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(tenantDashboardProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme; // This line is kept for context but will be removed in the next change.

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          // ignore: unused_result
          await ref.refresh(tenantDashboardProvider.future);
          // ignore: unused_result
          await ref.refresh(tenantInvoicesProvider.future);
          // ignore: unused_result
          await ref.refresh(tenantPaymentsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()) : null,
              actions: [
                IconButton(
                  icon: Icon(Icons.language_rounded, color: cs.primary),
                  onPressed: () => showLanguageSelectorSheet(context, ref),
                  tooltip: 'Change Language',
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: cs.onSurface),
                  onPressed: () => ref.invalidate(tenantDashboardProvider),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary.withOpacity(0.18),
                        cs.primary.withOpacity(0.04),
                      ],
                    ),
                  ),
                  child: dashAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (dashboard) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _Avatar(name: dashboard?.tenant.name ?? 'Tenant', size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Good ${_greeting()},',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dashboard?.tenant.name ?? '—',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700, letterSpacing: -0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    dashboard?.organization?.name ?? '',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: cs.primary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status badges
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (dashboard != null) ...[
                                _StatusBadge(
                                  icon: Icons.verified_rounded,
                                  label: dashboard.tenant.aadhaarVerified ? 'Verified' : 'Pending',
                                  color: dashboard.tenant.aadhaarVerified
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                                const SizedBox(height: 6),
                                _StatusBadge(
                                  icon: Icons.login_rounded,
                                  label: dashboard.tenant.checkInCompleted ? 'Checked In' : 'Pending',
                                  color: dashboard.tenant.checkInCompleted
                                      ? AppColors.success
                                      : cs.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────────
            SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: dashAsync.when(
              loading: () => const SliverToBoxAdapter(child: _LoadingState()),
              error: (e, _) => SliverToBoxAdapter(child: _ErrorState(message: e.toString(), onRetry: () => ref.invalidate(tenantDashboardProvider))),
              data: (dashboard) {
                if (dashboard == null) {
                  return const SliverToBoxAdapter(child: _NotTenantState());
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Monthly Rent Card ──────────────────────────────
                    _MonthlyRentCard(dashboard: dashboard, cs: cs, theme: theme),
                    const SizedBox(height: 14),

                    // ── Stats Row ─────────────────────────────────────
                    _StatsRow(dashboard: dashboard, cs: cs, theme: theme),
                    const SizedBox(height: 20),

                    // ── Bed Assignment Card ────────────────────────────
                    if (dashboard.assignment != null) ...[
                      _SectionLabel(label: 'Your Room'),
                      _AssignmentCard(assignment: dashboard.assignment!, cs: cs, theme: theme),
                      const SizedBox(height: 20),
                    ],

                    // ── Quick Actions ─────────────────────────────────
                    _SectionLabel(label: 'Quick Actions'),
                    _QuickActions(tenant: dashboard.tenant, cs: cs),
                    const SizedBox(height: 20),

                    // ── Recent Payments ───────────────────────────────
                    if (dashboard.recentPayments.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionLabel(label: 'Recent Payments'),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TenantPaymentHistoryScreen(initialIndex: 0),
                              ),
                            ),
                            child: Text('View All',
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 12, color: cs.primary)),
                          ),
                        ],
                      ),
                      ...dashboard.recentPayments
                          .map((p) => _PaymentTile(payment: p, cs: cs, theme: theme)),
                      const SizedBox(height: 20),
                    ],

                    // ── Overdue Invoices ──────────────────────────────
                    if (dashboard.overdueInvoices.isNotEmpty) ...[
                      _SectionLabel(label: 'Overdue Payments', color: AppColors.error),
                      ...dashboard.overdueInvoices
                          .map((inv) => _InvoiceTile(invoice: inv, cs: cs, theme: theme)),
                      const SizedBox(height: 20),
                    ],

                    // ── Upcoming Invoices ─────────────────────────────
                    if (dashboard.upcomingInvoices.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionLabel(label: 'Upcoming Invoices'),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TenantPaymentHistoryScreen(initialIndex: 1),
                              ),
                            ),
                            child: Text('View All',
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 12, color: cs.primary)),
                          ),
                        ],
                      ),
                      ...dashboard.upcomingInvoices
                          .map((inv) => _InvoiceTile(invoice: inv, cs: cs, theme: theme)),
                      const SizedBox(height: 8),
                    ],
                  ]),
                );
              },
            ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ─── Monthly Rent Card ────────────────────────────────────────────────────────
class _MonthlyRentCard extends StatelessWidget {
  final TenantDashboard dashboard;
  final ColorScheme cs;
  final ThemeData theme;
  const _MonthlyRentCard({required this.dashboard, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    final invoice = dashboard.currentInvoice;
    final isPaid = invoice?.isPaid ?? false;
    final isOverdue = invoice?.isOverdue ?? false;
    final amount = invoice?.totalAmount ?? dashboard.assignment?.monthlyRent ?? 0;
    final dueDate = invoice?.dueDate;

    String statusLabel = isPaid ? 'PAID' : isOverdue ? 'OVERDUE' : 'DUE';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, Color.lerp(cs.primary, AppColors.secondary, 0.4)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: cs.primary.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice != null ? invoice.monthLabel : DateFormat('MMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monthly Rent',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currencyFmt.format(amount),
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1),
          ),
          if (dueDate != null && !isPaid) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  'Due ${DateFormat('d MMM yyyy').format(dueDate)}',
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
          if (!isPaid && invoice != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/tenant/payments'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: cs.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Pay Now',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final TenantDashboard dashboard;
  final ColorScheme cs;
  final ThemeData theme;
  const _StatsRow({required this.dashboard, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Paid',
            value: _currencyFmt.format(dashboard.totalPaid),
            icon: Icons.payments_rounded,
            color: AppColors.success,
            cs: cs,
            theme: theme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Deposit',
            value: _currencyFmt.format(dashboard.assignment?.securityDeposit ?? 0),
            icon: Icons.account_balance_wallet_rounded,
            color: cs.primary,
            cs: cs,
            theme: theme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Overdue',
            value: '${dashboard.overdueCount}',
            icon: Icons.error_outline_rounded,
            color: dashboard.overdueCount > 0 ? AppColors.error : AppColors.success,
            cs: cs,
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;
  final ThemeData theme;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 10, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─── Assignment Card ──────────────────────────────────────────────────────────
class _AssignmentCard extends StatelessWidget {
  final TenantAssignment assignment;
  final ColorScheme cs;
  final ThemeData theme;
  const _AssignmentCard({required this.assignment, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _Row(icon: Icons.home_work_rounded, label: 'Property', value: assignment.propertyName ?? '—', cs: cs),
          const SizedBox(height: 10),
          _Row(icon: Icons.meeting_room_rounded, label: 'Room', value: '${assignment.roomNumber ?? "—"} · Floor ${assignment.floorNumber ?? "—"}', cs: cs),
          const SizedBox(height: 10),
          _Row(icon: Icons.bed_rounded, label: 'Bed', value: '${assignment.bedNumber ?? "—"} (${assignment.bedType ?? "—"})', cs: cs),
          const SizedBox(height: 10),
          _Row(icon: Icons.location_on_rounded, label: 'Address', value: '${assignment.propertyAddress ?? "—"}, ${assignment.propertyCity ?? ""}', cs: cs),
          const SizedBox(height: 10),
          _Row(icon: Icons.calendar_month_rounded, label: 'Since', value: DateFormat('d MMM yyyy').format(assignment.startDate), cs: cs),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  const _Row({required this.icon, required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final TenantInfo tenant;
  final ColorScheme cs;
  const _QuickActions({required this.tenant, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionBtn(
          icon: Icons.receipt_long_rounded,
          label: 'Invoices',
          color: cs.primary,
          onTap: () => context.go('/tenant/payments'),
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          icon: Icons.badge_rounded,
          label: tenant.aadhaarVerified ? 'Verified' : 'Verify ID',
          color: tenant.aadhaarVerified ? AppColors.success : AppColors.warning,
          onTap: () => context.go('/tenant/documents'),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    
    return Expanded(
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Payment Tile ─────────────────────────────────────────────────────────────
class _PaymentTile extends StatelessWidget {
  final TenantPayment payment;
  final ColorScheme cs;
  final ThemeData theme;
  const _PaymentTile({required this.payment, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
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
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.invoice != null ? payment.invoice!.monthLabel : 'Payment',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment.paidAt != null 
                            ? DateFormat('d MMM yyyy, hh:mm a').format(payment.paidAt!)
                            : 'Date missing',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  _currencyFmt.format(payment.amount),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16, color: cs.onSurfaceVariant.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientPrimary,
        border: Border.all(color: cs.primary.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Text(initials, style: TextStyle(fontFamily: 'Inter', fontSize: size * 0.32, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;
  const _SectionLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ?? cs.onSurfaceVariant,
              letterSpacing: 0.5)),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 40),
        CircularProgressIndicator(color: cs.primary),
        const SizedBox(height: 16),
        Text('Loading your dashboard…',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.wifi_off_rounded, size: 48, color: cs.onSurfaceVariant),
        const SizedBox(height: 16),
        Text('Could not load dashboard', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _NotTenantState extends StatelessWidget {
  const _NotTenantState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.person_off_rounded, size: 64, color: cs.onSurfaceVariant),
        const SizedBox(height: 20),
        Text('No tenant record found.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 8),
        Text('Contact your PG owner to be assigned a room.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ─── Invoice Tile ─────────────────────────────────────────────────────────────
class _InvoiceTile extends StatelessWidget {
  final TenantInvoice invoice;
  final ColorScheme cs;
  final ThemeData theme;
  const _InvoiceTile({required this.invoice, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (invoice.status) {
      'PAID'      => AppColors.success,
      'OVERDUE'   => AppColors.error,
      'CANCELLED' => cs.onSurfaceVariant,
      _           => AppColors.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TenantInvoiceDetailsScreen(invoice: invoice),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  invoice.isPaid ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.monthLabel,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Due: ${DateFormat('d MMM yyyy').format(invoice.dueDate)}',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFmt.format(invoice.totalAmount),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      invoice.status,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w800, color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
