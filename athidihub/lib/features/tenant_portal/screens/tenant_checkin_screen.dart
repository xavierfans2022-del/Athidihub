import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/features/tenant_portal/providers/tenant_portal_provider.dart';

class TenantCheckInScreen extends ConsumerStatefulWidget {
  const TenantCheckInScreen({super.key});
  @override
  ConsumerState<TenantCheckInScreen> createState() => _State();
}

class _State extends ConsumerState<TenantCheckInScreen> {
  bool _agreed = false;

  Future<void> _doCheckIn() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please agree to the terms before checking in'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    ref.read(checkInNotifierProvider.notifier).reset();
    await ref.read(checkInNotifierProvider.notifier).completeCheckIn();
    final state = ref.read(checkInNotifierProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.error?.toString() ?? 'Check-in failed'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ref.invalidate(tenantDashboardProvider);
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SuccessDialog(onDone: () {
            Navigator.pop(context);
            context.go('/tenant/home');
          }),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dashAsync = ref.watch(tenantDashboardProvider);
    final checkInState = ref.watch(checkInNotifierProvider);

    final tenant = dashAsync.valueOrNull?.tenant;
    final isVerified = tenant?.aadhaarVerified ?? false;
    final alreadyDone = tenant?.checkInCompleted ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Digital Check-In',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: alreadyDone
          ? _AlreadyCheckedIn(tenant: tenant!, cs: cs, theme: theme)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Progress Steps ──────────────────────────────────────
                _StepRow(steps: [
                  _Step('Upload Aadhaar', Icons.upload_file_rounded, isVerified || (tenant?.aadhaarUrl != null), isVerified),
                  _Step('Verification', Icons.admin_panel_settings_rounded, isVerified, isVerified),
                  _Step('Check-In', Icons.login_rounded, false, false),
                ]),
                const SizedBox(height: 24),

                // ── Blocked if not verified ─────────────────────────────
                if (!isVerified) ...[
                  _BlockedBanner(cs: cs, onGo: () => context.go('/tenant/documents')),
                  const SizedBox(height: 24),
                ],

                // ── Assignment Summary ──────────────────────────────────
                if (dashAsync.valueOrNull?.assignment != null) ...[
                  _SectionLabel('Your Stay Details'),
                  _AssignmentSummary(
                    assignment: dashAsync.valueOrNull!.assignment!,
                    cs: cs, theme: theme,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Check-In Terms ──────────────────────────────────────
                _SectionLabel('Terms & Conditions'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(color: cs.outline),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...[
                        'I confirm that the information provided is accurate and complete.',
                        'I agree to abide by the PG rules and regulations.',
                        'I understand the monthly rent and payment schedule.',
                        'I acknowledge the security deposit terms.',
                        'I agree to maintain the property and report any damages.',
                      ].map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 16, color: cs.primary),
                                const SizedBox(width: 10),
                                Expanded(child: Text(t, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.onSurface, height: 1.5))),
                              ],
                            ),
                          )),
                      const Divider(height: 20),
                      GestureDetector(
                        onTap: () => setState(() => _agreed = !_agreed),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: _agreed ? cs.primary : Colors.transparent,
                                border: Border.all(color: _agreed ? cs.primary : cs.outline, width: 2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: _agreed ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'I agree to all the above terms and conditions',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── CTA Button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: (!isVerified || checkInState.isLoading) ? null : _doCheckIn,
                    icon: checkInState.isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.login_rounded),
                    label: Text(
                      checkInState.isLoading ? 'Processing…' : 'Complete Check-In',
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVerified ? cs.primary : cs.onSurface.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
    );
  }
}

// ─── Already Checked In ───────────────────────────────────────────────────────
class _AlreadyCheckedIn extends StatelessWidget {
  final dynamic tenant;
  final ColorScheme cs;
  final ThemeData theme;
  const _AlreadyCheckedIn({required this.tenant, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientSuccess,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text('Check-In Complete!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.success)),
            const SizedBox(height: 10),
            if (tenant.checkInDate != null)
              Text('Checked in on ${DateFormat('d MMMM yyyy').format(tenant.checkInDate!)}',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.person_rounded, label: 'Name', value: tenant.name, cs: cs),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.verified_rounded, label: 'Status', value: 'Active Tenant', cs: cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.success),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: cs.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
      ],
    );
  }
}

// ─── Step Row ─────────────────────────────────────────────────────────────────
class _Step {
  final String label;
  final IconData icon;
  final bool reached;
  final bool done;
  const _Step(this.label, this.icon, this.reached, this.done);
}

class _StepRow extends StatelessWidget {
  final List<_Step> steps;
  const _StepRow({required this.steps});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector
          final prevDone = steps[i ~/ 2].done;
          return Expanded(child: Container(height: 2, color: prevDone ? AppColors.success : cs.outline));
        }
        final step = steps[i ~/ 2];
        final color = step.done ? AppColors.success : step.reached ? AppColors.warning : cs.onSurfaceVariant.withOpacity(0.4);
        return Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(step.done ? Icons.check_rounded : step.icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: Text(step.label, textAlign: TextAlign.center, maxLines: 2,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Blocked Banner ───────────────────────────────────────────────────────────
class _BlockedBanner extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onGo;
  const _BlockedBanner({required this.cs, required this.onGo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aadhaar Verification Required',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning)),
                const SizedBox(height: 4),
                Text('Your Aadhaar must be verified before check-in.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onGo,
            child: const Text('Go →', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning)),
          ),
        ],
      ),
    );
  }
}

// ─── Assignment Summary ───────────────────────────────────────────────────────
class _AssignmentSummary extends StatelessWidget {
  final dynamic assignment;
  final ColorScheme cs;
  final ThemeData theme;
  const _AssignmentSummary({required this.assignment, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surface, border: Border.all(color: cs.outline), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          _R(icon: Icons.home_work_rounded, label: 'Property', value: assignment.propertyName ?? '—', cs: cs),
          const SizedBox(height: 8),
          _R(icon: Icons.meeting_room_rounded, label: 'Room', value: assignment.roomNumber ?? '—', cs: cs),
          const SizedBox(height: 8),
          _R(icon: Icons.bed_rounded, label: 'Bed', value: assignment.bedNumber ?? '—', cs: cs),
          const SizedBox(height: 8),
          _R(icon: Icons.currency_rupee_rounded, label: 'Monthly Rent', value: '₹${assignment.monthlyRent?.toStringAsFixed(0) ?? "—"}', cs: cs),
        ],
      ),
    );
  }
}

class _R extends StatelessWidget {
  final IconData icon; final String label, value; final ColorScheme cs;
  const _R({required this.icon, required this.label, required this.value, required this.cs});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: cs.primary), const SizedBox(width: 10),
    Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.onSurfaceVariant)),
    const Spacer(),
    Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
  ]);
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
  );
}

// ─── Success Dialog ───────────────────────────────────────────────────────────
class _SuccessDialog extends StatefulWidget {
  final VoidCallback onDone;
  const _SuccessDialog({required this.onDone});
  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(gradient: AppColors.gradientSuccess, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('Welcome Home! 🎉', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('Your digital check-in is complete. You are now an official resident!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: cs.onSurfaceVariant, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Go to Dashboard', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
