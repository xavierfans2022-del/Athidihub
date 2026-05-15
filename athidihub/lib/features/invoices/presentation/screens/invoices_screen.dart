import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:athidihub/l10n/app_localizations.dart';
import 'package:athidihub/core/theme/app_semantic_colors.dart';
import 'package:athidihub/features/invoices/providers/invoice_provider.dart';
import 'package:athidihub/features/invoices/data/models/invoice_model.dart';
import 'package:athidihub/features/notifications/providers/reminder_provider.dart';
import 'package:athidihub/features/dashboard/providers/dashboard_provider.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';
import 'package:athidihub/core/constants/app_constants.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _statuses = ['ALL', 'PENDING', 'PAID', 'OVERDUE'];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(invoiceListProvider.notifier).fetchMore();
    }
  }

  void _showFilterSheet() {
    final state = ref.read(invoiceListProvider);
    int? selectedMonth = state.filterMonth;
    int? selectedYear = state.filterYear ?? DateTime.now().year;

    final localizations = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final months = List.generate(
      12,
      (i) => DateFormat.MMM(localeName).format(DateTime(2024, i + 1)),
    );
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final cs = Theme.of(ctx).colorScheme;
          final tt = Theme.of(ctx).textTheme;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  localizations.filterByMonth,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                // Year selector
                Row(
                  children: List.generate(3, (i) {
                    final y = now.year - 1 + i;
                    final sel = selectedYear == y;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedYear = y),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? cs.primary
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? cs.primary : cs.outline,
                            ),
                          ),
                          child: Text(
                            '$y',
                            style: tt.labelMedium?.copyWith(
                              color: sel ? cs.onPrimary : cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Month grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(12, (i) {
                    final sel = selectedMonth == i + 1;
                    return GestureDetector(
                      onTap: () => setSheetState(
                        () => selectedMonth = sel ? null : i + 1,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? cs.primary.withAlpha(30)
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel ? cs.primary : cs.outline,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          months[i],
                          style: tt.labelMedium?.copyWith(
                            color: sel ? cs.primary : cs.onSurface,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref
                              .read(invoiceListProvider.notifier)
                              .setMonthYear(null, null);
                          Navigator.pop(ctx);
                        },
                        child: Text(localizations.clear),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(invoiceListProvider.notifier)
                              .setMonthYear(selectedMonth, selectedYear);
                          Navigator.pop(ctx);
                        },
                        child: Text(localizations.apply),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context)!;
    final state = ref.watch(invoiceListProvider);
    final hasActiveFilter =
        state.filterMonth != null || state.filterYear != null;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: Text(localizations.invoices),
        actions: [
          RefreshButton(
            label: localizations.refresh,
            onRefresh: () async {
              ref.read(invoiceListProvider.notifier).refresh();
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: localizations.filterByMonth,
                onPressed: _showFilterSheet,
              ),
              if (hasActiveFilter)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.message_rounded,
              size: 22,
              color: Colors.green,
            ),
            tooltip: localizations.sendBulkReminders,
            onPressed: _showReminderDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(invoiceListProvider.notifier).setSearch(v),
              decoration: InputDecoration(
                hintText: localizations.searchInvoices,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: state.search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(invoiceListProvider.notifier).setSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Status filter chips ─────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _statuses[i];
                final sel = state.status == s;
                return GestureDetector(
                  onTap: () =>
                      ref.read(invoiceListProvider.notifier).setStatus(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? cs.primary : cs.outline,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      switch (s) {
                        'ALL' => localizations.all,
                        'PENDING' => localizations.pendingStatus,
                        'PAID' => localizations.paidStatus,
                        _ => localizations.overdueStatus,
                      },
                      style: tt.labelMedium?.copyWith(
                        color: sel ? cs.onPrimary : cs.onSurface,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Active filter indicator ─────────────────────────
          if (hasActiveFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.filter_list_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    _buildFilterLabel(state),
                    style: tt.labelSmall?.copyWith(color: cs.primary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        ref.read(invoiceListProvider.notifier).clearFilters(),
                    child: Text(
                      localizations.clear,
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── List ────────────────────────────────────────────
          Expanded(child: _buildList(context, state)),
        ],
      ),
    );
  }

  void _showReminderDialog() async {
    final organizationId = await ref.read(
      selectedOrganizationIdProvider.future,
    );
    final localizations = AppLocalizations.of(context)!;

    if (organizationId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseSelectOrganizationFirst)),
      );
      return;
    }

    if (!mounted) return;
    int daysAhead = 3;
    bool includeOverdue = true;

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final reminderState = ref.watch(reminderStateProvider);
          final isLoading = reminderState.isLoading;

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.message_rounded, color: Colors.green),
                SizedBox(width: 10),
                Text(localizations.sendBulkReminders),
              ],
            ),
            content: reminderState.when(
              data: (result) {
                if (result != null) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.remindersQueued,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _ResultRow(
                        label: localizations.successfullyQueued,
                        value: '${result['remindersQueued']}',
                        color: Colors.green,
                      ),
                      _ResultRow(
                        label: localizations.alreadySentToday,
                        value: '${result['remindersSkippedAlreadySent']}',
                        color: Colors.orange,
                      ),
                      _ResultRow(
                        label: localizations.missingPhoneNo,
                        value: '${result['remindersSkippedNoPhone']}',
                        color: Colors.red,
                      ),
                    ],
                  );
                }
                return StatefulBuilder(
                  builder: (ctx, setDialogState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(localizations.sendPersonalizedWhatsAppReminders),
                        const SizedBox(height: 20),
                        _OptionTile(
                          title: localizations.includeOverdue,
                          subtitle: localizations.remindForPastDueDates,
                          value: includeOverdue,
                          onChanged: (val) => setDialogState(
                            () => includeOverdue = val ?? true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          localizations.dueWindow,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(localizations.dueWithinDays(daysAhead)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 20,
                                    ),
                                    onPressed: daysAhead > 1
                                        ? () =>
                                              setDialogState(() => daysAhead--)
                                        : null,
                                  ),
                                  Text(
                                    '$daysAhead',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                    ),
                                    onPressed: daysAhead < 30
                                        ? () =>
                                              setDialogState(() => daysAhead++)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20),
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(height: 20),
                  Text(localizations.queuingWhatsAppMessages),
                  SizedBox(height: 10),
                  Text(
                    localizations.thisMayTakeAMoment,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              error: (err, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    localizations.failedToSendReminders,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(reminderStateProvider.notifier).reset();
                  Navigator.pop(ctx);
                },
                child: Text(
                  reminderState.value != null || reminderState.hasError
                      ? localizations.close
                      : localizations.cancel,
                ),
              ),
              if (reminderState.value == null &&
                  !isLoading &&
                  !reminderState.hasError)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(reminderStateProvider.notifier)
                        .sendBulkReminders(
                          organizationId: organizationId,
                          daysAhead: daysAhead,
                          includeOverdue: includeOverdue,
                        );
                  },
                  child: Text(localizations.sendNow),
                ),
            ],
          );
        },
      ),
    );
  }

  String _buildFilterLabel(InvoiceListState state) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (state.filterMonth != null && state.filterYear != null) {
      return '${months[state.filterMonth! - 1]} ${state.filterYear}';
    }
    if (state.filterYear != null) return '${state.filterYear}';
    return AppLocalizations.of(context)!.filtered;
  }

  Widget _buildList(BuildContext context, InvoiceListState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.couldNotLoadInvoices,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    ref.read(invoiceListProvider.notifier).refresh(),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 56,
              color: cs.onSurfaceVariant.withAlpha(102),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noInvoicesFound,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              state.search.isNotEmpty
                  ? AppLocalizations.of(context)!.tryDifferentSearchTerm
                  : AppLocalizations.of(context)!.invoicesWillAppearHere,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(invoiceListProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: state.items.length + (state.isFetchingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _InvoiceCard(invoice: state.items[i]);
        },
      ),
    );
  }
}

// ── Invoice Card ──────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  const _InvoiceCard({required this.invoice});

  static const _months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context)!;
    final semantic =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.dark;

    final statusColor = switch (invoice.status) {
      'PAID' => semantic.success,
      'OVERDUE' => semantic.error,
      _ => semantic.warning,
    };
    final statusBg = switch (invoice.status) {
      'PAID' => semantic.successBg,
      'OVERDUE' => semantic.errorBg,
      _ => semantic.warningBg,
    };

    final tenantName =
        (invoice.tenant?['name'] ?? invoice.tenant?['fullName']) as String? ??
        'Tenant';
    final localeName = Localizations.localeOf(context).toString();
    final monthLabel = invoice.month > 0 && invoice.month <= 12
        ? DateFormat.MMM(localeName).format(DateTime(2024, invoice.month))
        : '?';
    final dueStr = DateFormat(
      'dd MMM yyyy',
      localeName,
    ).format(invoice.dueDate);

    return GestureDetector(
      onTap: () => context.go('/invoices/${invoice.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      tenantName.isNotEmpty ? tenantName[0].toUpperCase() : '?',
                      style: tt.titleSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenantName,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$monthLabel ${invoice.year}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${invoice.totalAmount.toStringAsFixed(0)}',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        switch (invoice.status) {
                          'PAID' => localizations.paidStatus,
                          'OVERDUE' => localizations.overdueStatus,
                          _ => localizations.pendingStatus,
                        },
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  localizations.due(dueStr),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                if (invoice.status == 'PENDING' || invoice.status == 'OVERDUE')
                  GestureDetector(
                    onTap: () => context.go('/payments', extra: invoice.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        localizations.payNow,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ),
                if (invoice.status == 'PAID')
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: semantic.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        localizations.paid,
                        style: tt.labelSmall?.copyWith(
                          color: semantic.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
