import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/theme/app_semantic_colors.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';
import 'package:athidihub/features/tenants/providers/tenant_api_provider.dart';
import 'package:athidihub/features/tenants/data/tenant_api_repository.dart';

class TenantsScreen extends ConsumerStatefulWidget {
  const TenantsScreen({super.key});

  @override
  ConsumerState<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends ConsumerState<TenantsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  // Filter labels → backend status values
  static const _filters = ['All', 'Active', 'Inactive'];
  static const _filterValues = {'All': 'all', 'Active': 'active', 'Inactive': 'inactive'};

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Trigger fetchMore when 80% scrolled
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final threshold = _scrollCtrl.position.maxScrollExtent * 0.8;
    if (_scrollCtrl.position.pixels >= threshold) {
      ref.read(tenantListProvider.notifier).fetchMore();
    }
  }

  // Debounce search — 400ms after user stops typing
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(tenantListProvider.notifier).setSearch(value.trim());
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    ref.read(tenantListProvider.notifier).setSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        title: const Text('Tenants'),
        actions: [
          RefreshButton(
            label: 'Refresh',
            onRefresh: () async {
              ref.invalidate(tenantListProvider);
            },
          ),
          // Total count badge
          if (!state.isLoading && state.error == null)
            Padding(
              padding: const EdgeInsets.only(right: 4 ,left:4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${state.items.length}${state.hasMore ? '+' : ''}',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded, size: 22),
            onPressed: () => context.go('/tenants/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filters ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchCtrl,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone or email...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 10),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((label) {
                      final value = _filterValues[label]!;
                      final selected = state.status == value;
                      return GestureDetector(
                        onTap: () => ref.read(tenantListProvider.notifier).setStatus(value),
                        child: AnimatedContainer(
                          duration: AppConstants.animFast,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: selected ? colorScheme.primary : colorScheme.outline),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── List ──────────────────────────────────────────────────────
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TenantListState state) {
    final colorScheme = Theme.of(context).colorScheme;

    // Initial loading → skeleton
    if (state.isLoading && state.items.isEmpty) {
      return _TenantListSkeleton();
    }

    // Error with no data
    if (state.error != null && state.items.isEmpty) {
      return _buildError(context, state.error!);
    }

    // Empty state
    if (!state.isLoading && state.items.isEmpty) {
      return _buildEmpty(context);
    }

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: () => ref.read(tenantListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        // +1 for footer (loader / end indicator)
        itemCount: state.items.length + 1,
        itemBuilder: (context, index) {
          // Footer
          if (index == state.items.length) {
            return _buildFooter(context, state);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildTenantCard(context, state.items[index]),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context, TenantListState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state.isFetchingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2)),
      );
    }

    if (!state.hasMore && state.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(color: colorScheme.outline, endIndent: 12, indent: 0),
              Text('All ${state.items.length} tenants loaded', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return const SizedBox(height: 8);
  }

  Widget _buildTenantCard(BuildContext context, TenantModel tenant) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>() ?? AppSemanticColors.dark;

    return GestureDetector(
      onTap: () => context.go('/tenants/${tenant.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(tenant.initials, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.primary))),
            ),
            const SizedBox(width: 12),

            // Name + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenant.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(tenant.phone, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status badge + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (tenant.isActive ? semantic.success : colorScheme.onSurfaceVariant).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    tenant.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: tenant.isActive ? semantic.success : colorScheme.onSurfaceVariant, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right_rounded, size: 16, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Failed to load tenants', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(msg, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              onPressed: () => ref.read(tenantListProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSearching = _searchCtrl.text.isNotEmpty || ref.read(tenantListProvider).status != 'all';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded, size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(isSearching ? 'No results found' : 'No tenants yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              isSearching ? 'Try a different search or filter' : 'Add your first tenant to get started',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!isSearching)
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Add Tenant'),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                onPressed: () => context.go('/tenants/add'),
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('Clear filters'),
                onPressed: () {
                  _clearSearch();
                  ref.read(tenantListProvider.notifier).setStatus('all');
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _TenantListSkeleton extends StatefulWidget {
  @override
  State<_TenantListSkeleton> createState() => _TenantListSkeletonState();
}

class _TenantListSkeletonState extends State<_TenantListSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.75);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final dx = bounds.width * (_ctrl.value * 3 - 1);
          return LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds.shift(Offset(-dx, 0)));
        },
        child: child,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildCardSkeleton(context),
        ),
      ),
    );
  }

  Widget _buildCardSkeleton(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 140, height: 13, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(width: 100, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 48, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100))),
              const SizedBox(height: 6),
              Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ],
      ),
    );
  }
}
