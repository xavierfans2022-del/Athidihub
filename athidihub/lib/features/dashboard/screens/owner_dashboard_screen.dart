import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/theme/app_semantic_colors.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/shared/widgets/app_logo.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';
import 'package:athidihub/core/cache/cache_provider.dart';
import 'package:athidihub/features/dashboard/providers/dashboard_provider.dart';
import 'package:athidihub/l10n/app_localizations.dart';
// reminder provider removed from this screen after moving quick actions to Profile

// ─── Shimmer core ────────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = isDark
        ? Colors.white.withOpacity(0.09)
        : Colors.white.withOpacity(0.75);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_ctrl.value * 3 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds.shift(Offset(-dx, 0)));
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─── Skeleton box helper ──────────────────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Dashboard skeleton ───────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            const _SkeletonBox(width: 220, height: 22, radius: 6),
            const SizedBox(height: 8),
            const _SkeletonBox(width: 160, height: 14, radius: 6),
            const SizedBox(height: 20),

            // Revenue card
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),

            // Stat cards row 1
            Row(
              children: [
                Expanded(child: _buildStatSkeleton(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatSkeleton(context)),
              ],
            ),
            const SizedBox(height: 12),

            // Stat cards row 2
            Row(
              children: [
                Expanded(child: _buildStatSkeleton(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatSkeleton(context)),
              ],
            ),
            const SizedBox(height: 20),

            // Quick actions label
            const _SkeletonBox(width: 110, height: 16, radius: 6),
            const SizedBox(height: 12),

            // Quick action chips - scrollable
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  4,
                  (i) => Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
                    child: Container(
                      width: 110,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Chart label
            const _SkeletonBox(width: 130, height: 16, radius: 6),
            const SizedBox(height: 12),

            // Chart
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),

            // Activity label
            const _SkeletonBox(width: 120, height: 16, radius: 6),
            const SizedBox(height: 12),

            // Activity items
            ...List.generate(3, (_) => _buildActivitySkeleton(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSkeleton(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 80,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySkeleton(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 13,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 120,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main screen ─────────────────────────────────────────────────────────────

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(dashboardAnalyticsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.dark;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: const AppLogo(compact: true),
            actions: [
              RefreshButton(
                label: 'Refresh',
                onRefresh: () async {
                  final cacheService = ref.read(cacheServiceProvider);
                  final orgId = await ref.read(
                    selectedOrganizationIdProvider.future,
                  );
                  if (orgId != null) {
                    await cacheService.remove('dashboard_analytics_$orgId');
                    ref.invalidate(dashboardAnalyticsProvider);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'B',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          analyticsAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: _DashboardSkeleton(),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: _ErrorState(
                message: err.toString(),
                onRetry: () => ref.refresh(dashboardAnalyticsProvider),
              ),
            ),
            data: (analytics) => SliverPadding(
              padding: const EdgeInsets.all(AppConstants.spacingMD),
              sliver: Builder(
                builder: (context) {
                  final children = <Widget>[];
                  if (analytics.organizationId == null) {
                    children.addAll([
                      _NoOrganizationState(
                        onSetup: () => context.go('/onboarding'),
                      ),
                      const SizedBox(height: 80),
                    ]);
                  } else {
                    children.addAll([
                      // Greeting
                      Text(
                        '${_greeting(localizations)}${analytics.organizationName != null ? ', ${analytics.organizationName}' : ''} 👋',
                        style: (theme.textTheme.titleLarge ?? const TextStyle())
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        localizations.portfolioOverview,
                        style: (theme.textTheme.bodySmall ?? const TextStyle())
                            .copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),

                      // Revenue card (batched in RepaintBoundary)
                      const RepaintBoundary(child: _RevenueCardConsumer()),
                      const SizedBox(height: 16),

                      // Stat cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              localizations.occupancy,
                              '${analytics.occupancyRate.toStringAsFixed(1)}%',
                              Icons.bed_rounded,
                              AppColors.secondary,
                              '${analytics.occupiedBedCount}/${analytics.bedCount} beds',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              localizations.vacantBeds,
                              '${analytics.availableBedCount}',
                              Icons.hotel_rounded,
                              Colors.teal,
                              'Available now',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              localizations.pending,
                              '${analytics.pendingCount}',
                              Icons.warning_amber_rounded,
                              AppColors.warning,
                              '₹${analytics.pendingAmount.toStringAsFixed(0)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              localizations.overdueStatus,
                              '${analytics.overdueCount}',
                              Icons.error_outline_rounded,
                              AppColors.error,
                              '₹${analytics.overdueAmount.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        context,
                        localizations.tenants,
                        '${analytics.activeTenantCount}',
                        Icons.people_rounded,
                        AppColors.primary,
                        '${analytics.activeAssignmentCount} active assignments across ${analytics.propertyCount} properties',
                      ),
                      const SizedBox(height: 20),

                      // Quick actions removed (moved to Profile screen to reduce dashboard rebuilds)

                      // Revenue chart
                      Text(
                        localizations.revenueLastSixMonths,
                        style: (theme.textTheme.titleSmall ?? const TextStyle())
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      const RepaintBoundary(child: _RevenueChartConsumer()),
                      const SizedBox(height: 20),

                      // Recent activity
                      Text(
                        localizations.recentActivity,
                        style: (theme.textTheme.titleSmall ?? const TextStyle())
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      // Activity feed built lazily
                      RepaintBoundary(
                        child: _ActivityFeedConsumer(semantic: semantic),
                      ),
                      const SizedBox(height: 80),
                    ]);
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => children[index],
                      childCount: children.length,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String sub,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: (theme.textTheme.titleLarge ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  // Quick action helper removed (moved to Profile screen)

  String _greeting(AppLocalizations localizations) {
    final hour = DateTime.now().hour;
    if (hour < 12) return localizations.goodMorning;
    if (hour < 17) return localizations.goodAfternoon;
    return localizations.goodEvening;
  }
}

class _NoOrganizationState extends StatelessWidget {
  final VoidCallback onSetup;

  const _NoOrganizationState({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.apartment_rounded, color: colorScheme.primary),
          ),
          const SizedBox(height: 14),
          Text(
            localizations.setUpYourOrganization,
            style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            localizations.createYourOrganizationDescription,
            style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onSetup,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(localizations.createOrganization),
          ),
        ],
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.couldNotLoadDashboard,
              style: (theme.textTheme.titleMedium ?? const TextStyle())
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(localizations.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Consumers that select only required slices to minimise rebuilds ───────

class _RevenueCardConsumer extends ConsumerWidget {
  const _RevenueCardConsumer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyRevenue = ref.watch(
      dashboardAnalyticsProvider.select((a) => a.asData?.value?.monthlyRevenue),
    );
    final localeName = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat(
      'MMM yyyy',
      localeName,
    ).format(DateTime.now());
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    final revenue = monthlyRevenue ?? 0;

    return Container(
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.monthlyRevenue,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${revenue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      monthLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.white),
                      const SizedBox(width: 6),
                      Text(
                        localizations.fromLastMonth,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChartConsumer extends ConsumerWidget {
  const _RevenueChartConsumer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(
      dashboardAnalyticsProvider.select(
        (a) => a.asData?.value?.monthlySeries ?? <dynamic>[],
      ),
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final series = List<dynamic>.from(points);
    final maxRevenue = series.fold<double>(
      0,
      (m, p) => (p?.revenue ?? 0) > m ? (p?.revenue ?? 0) : m,
    );
    final chartMax = maxRevenue <= 0 ? 1.0 : maxRevenue * 1.3;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => colorScheme.primaryContainer,
              tooltipRoundedRadius: 8,
              getTooltipItems: (spots) {
                return spots.map((s) {
                  return LineTooltipItem(
                    '₹${s.y.toStringAsFixed(0)}',
                    TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxRevenue > 0 ? maxRevenue / 4 : 1,
            getDrawingHorizontalLine: (v) => FlLine(
              color: colorScheme.outline.withOpacity(0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) {
                  if (v == meta.max || v == meta.min) return const SizedBox();
                  return Text(
                    v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= series.length) return const SizedBox();
                  final label = series[i]?.label ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                series.length,
                (i) => FlSpot(i.toDouble(), (series[i]?.revenue ?? 0).toDouble()),
              ),
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: colorScheme.surface,
                  strokeWidth: 2,
                  strokeColor: AppColors.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minY: 0,
          maxY: chartMax,
        ),
      ),
    );
  }
}

class _ActivityFeedConsumer extends ConsumerWidget {
  final AppSemanticColors semantic;
  const _ActivityFeedConsumer({required this.semantic, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final recentPayments = ref.watch(
      dashboardAnalyticsProvider.select(
        (a) => a.asData?.value?.recentPayments ?? [],
      ),
    );
    final recentInvoices = ref.watch(
      dashboardAnalyticsProvider.select(
        (a) => a.asData?.value?.recentInvoices ?? [],
      ),
    );
    final recentMaintenance = ref.watch(
      dashboardAnalyticsProvider.select(
        (a) => a.asData?.value?.recentMaintenance ?? [],
      ),
    );

    // Limit mapping to a small sample from each source to avoid allocating large lists while scrolling.
    final paymentsSample = recentPayments.take(4);
    final invoicesSample = recentInvoices.take(4);
    final maintenanceSample = recentMaintenance.take(4);

    final activities = <_DashboardActivity>[];
    activities.addAll(
      paymentsSample.map(
        (p) => _DashboardActivity(
          icon: Icons.payments_rounded,
          color: semantic.success,
          title: '${p.tenantName} paid ₹${p.amount.toStringAsFixed(0)}',
          subtitle:
              '${p.method} • Invoice ${p.invoiceId.length >= 8 ? p.invoiceId.substring(0, 8) : p.invoiceId}',
          time: _relativeTime(localizations, p.paidAt ?? p.createdAt),
          createdAt:
              DateTime.tryParse(p.paidAt ?? p.createdAt) ?? DateTime.now(),
        ),
      ),
    );
    activities.addAll(
      invoicesSample.map(
        (inv) => _DashboardActivity(
          icon: Icons.receipt_long_rounded,
          color: inv.status.toUpperCase() == 'PAID'
              ? semantic.success
              : semantic.warning,
          title: 'Invoice ${inv.status.toLowerCase()} for ${inv.tenantName}',
          subtitle:
              '₹${inv.totalAmount.toStringAsFixed(0)} • Due ${DateFormat('dd MMM').format(DateTime.tryParse(inv.dueDate) ?? DateTime.now())}',
          time: _relativeTime(localizations, inv.createdAt),
          createdAt: DateTime.tryParse(inv.createdAt) ?? DateTime.now(),
        ),
      ),
    );
    activities.addAll(
      maintenanceSample.map(
        (m) => _DashboardActivity(
          icon: Icons.build_circle_rounded,
          color: semantic.warning,
          title: 'Maintenance ${m.status.toLowerCase()}',
          subtitle:
              '${m.category} • Property ${m.propertyId.length >= 8 ? m.propertyId.substring(0, 8) : m.propertyId}',
          time: _relativeTime(localizations, m.createdAt),
          createdAt: DateTime.tryParse(m.createdAt) ?? DateTime.now(),
        ),
      ),
    );

    activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final visible = activities.take(4).toList();
    if (visible.isEmpty) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          localizations.noRecentActivityYet,
          style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final a = visible[index];
        return RepaintBoundary(child: _buildActivityItem(context, a));
      },
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _DashboardActivity {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final DateTime createdAt;

  _DashboardActivity({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.createdAt,
  });
}

String _relativeTime(AppLocalizations localizations, String rawDate) {
  final parsed = DateTime.tryParse(rawDate);
  if (parsed == null) return localizations.justNow;
  final diff = DateTime.now().difference(parsed);
  if (diff.inMinutes < 1) return localizations.justNow;
  if (diff.inMinutes < 60) return localizations.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return localizations.hoursAgo(diff.inHours);
  return localizations.daysAgo(diff.inDays);
}

Widget _buildActivityItem(BuildContext context, _DashboardActivity a) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      border: Border.all(color: colorScheme.outline),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: a.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(a.icon, size: 18, color: a.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.title,
                style: (theme.textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                a.subtitle,
                style: (theme.textTheme.bodySmall ?? const TextStyle())
                    .copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Text(
          a.time,
          style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
