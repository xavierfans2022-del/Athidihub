import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/core/theme/app_semantic_colors.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Pending', 'In Progress', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: const Text('Maintenance'),
        actions: [
          RefreshButton(
            label: 'Refresh',
            onRefresh: () async {
              // TODO: Implement refresh logic when provider is available
              await Future.delayed(const Duration(seconds: 1));
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            onPressed: () => context.go('/maintenance/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final selected = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: AppConstants.animFast,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: selected ? colorScheme.primary : colorScheme.outline),
                      ),
                      child: Text(f, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _buildCard(context, i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, int i) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>() ?? AppSemanticColors.dark;

    final items = [
      {'title': 'Electricity issue in room 301', 'tenant': 'Arun Reddy', 'cat': 'Electricity', 'status': 'pending', 'time': '2h ago'},
      {'title': 'Water tap leaking', 'tenant': 'Priya Sharma', 'cat': 'Water', 'status': 'in_progress', 'time': '1d ago'},
      {'title': 'WiFi not working', 'tenant': 'Rahul Kumar', 'cat': 'Internet', 'status': 'completed', 'time': '3d ago'},
      {'title': 'Room cleaning needed', 'tenant': 'Sneha Patel', 'cat': 'Cleaning', 'status': 'pending', 'time': '4h ago'},
      {'title': 'AC not cooling', 'tenant': 'Vikram Singh', 'cat': 'Repairs', 'status': 'in_progress', 'time': '2d ago'},
      {'title': 'Broken door handle', 'tenant': 'Divya Menon', 'cat': 'Repairs', 'status': 'completed', 'time': '5d ago'},
    ];

    final item = items[i % items.length];
    final statusColor = item['status'] == 'completed' ? semantic.success : item['status'] == 'in_progress' ? semantic.info : semantic.warning;
    final catIcon = <String, IconData>{
      'Electricity': Icons.electric_bolt_rounded, 'Water': Icons.water_drop_outlined,
      'Internet': Icons.wifi_rounded, 'Cleaning': Icons.cleaning_services_rounded, 'Repairs': Icons.build_rounded,
    }[item['cat']] ?? Icons.build_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colorScheme.surface, border: Border.all(color: colorScheme.outline), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(catIcon, size: 18, color: statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item['title']!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 12, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(item['tenant']!, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(width: 12),
              Icon(Icons.access_time_rounded, size: 12, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(item['time']!, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(item['status']!.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
