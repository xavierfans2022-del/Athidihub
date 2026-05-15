import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:athidihub/core/services/backend_storage_service.dart';
import 'package:athidihub/l10n/app_localizations.dart';
import 'package:athidihub/core/providers/supabase_provider.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/theme/theme_mode_provider.dart';
import 'package:athidihub/features/auth/providers/auth_provider.dart';
import 'package:athidihub/features/tenant_portal/providers/tenant_portal_provider.dart';
import 'package:athidihub/shared/widgets/language_selector_sheet.dart';

final _pkgProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class TenantProfileScreen extends ConsumerStatefulWidget {
  const TenantProfileScreen({super.key});
  @override
  ConsumerState<TenantProfileScreen> createState() => _State();
}

class _State extends ConsumerState<TenantProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromDashboard());
  }

  void _loadFromDashboard() {
    final tenant = ref.read(tenantDashboardProvider).valueOrNull?.tenant;
    if (tenant != null) {
      _nameCtrl.text = tenant.name;
      _phoneCtrl.text = tenant.phone;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      ref.read(tenantProfileNotifierProvider.notifier).reset();
      await ref.read(tenantProfileNotifierProvider.notifier).update({
        'name': _nameCtrl.text.trim(),
        if (_emerCtrl.text.trim().isNotEmpty)
          'emergencyContact': _emerCtrl.text.trim(),
      });
      final st = ref.read(tenantProfileNotifierProvider);
      if (st.hasError) throw st.error ?? 'Save failed';
      ref.invalidate(tenantDashboardProvider);
      setState(() => _editing = false);
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.profileUpdated),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.saveFailed(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      final url = await ref
          .read(backendStorageServiceProvider)
          .uploadAvatar(bytes: bytes, fileName: fileName);
      await ref.read(authNotifierProvider.notifier).updateUserData({
        'avatar_url': url,
      });
      setState(() {});
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.photoUpdated),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.uploadFailed(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final cs = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: cs.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.tenantPortalSignOutTitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.tenantPortalSignOutMessage,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.error.withOpacity(0.16)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations.unsavedProfileChangesLost,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.4,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(c, true),
            icon: const Icon(Icons.logout_rounded, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: Text(
              localizations.signOut,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(
              localizations.cancel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(tenantDashboardProvider);
    final tenant = dashAsync.valueOrNull?.tenant;
    final themeMode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && brightness == Brightness.dark);
    final pkgInfo = ref.watch(_pkgProvider);

    final name = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text
        : (tenant?.name ?? user?.email?.split('@').first ?? 'Tenant');
    final email = user?.email ?? tenant?.email ?? '';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.maybePop(context),
                  )
                : null,
            actions: [
              if (!_editing)
                TextButton.icon(
                  icon: Icon(Icons.edit_rounded, size: 15, color: cs.primary),
                  label: Text(
                    localizations.edit,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () => setState(() => _editing = true),
                )
              else
                TextButton.icon(
                  icon: _saving
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                  label: Text(
                    localizations.save,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(tenantDashboardProvider);
                  ref.invalidate(currentUserProvider);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withOpacity(0.15),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 44),
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: avatarUrl == null
                                  ? AppColors.gradientPrimary
                                  : null,
                              border: Border.all(
                                color: cs.primary.withOpacity(0.3),
                                width: 3,
                              ),
                            ),
                            child: avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            localizations.tenant,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Editable Fields ────────────────────────────────────
                if (_editing) ...[
                  _Label(localizations.editProfile),
                  _TF(
                    ctrl: _nameCtrl,
                    label: localizations.fullName,
                    icon: Icons.person_outline_rounded,
                    cs: cs,
                  ),
                  const SizedBox(height: 10),
                  _TF(
                    ctrl: _phoneCtrl,
                    label: localizations.phone,
                    icon: Icons.phone_outlined,
                    cs: cs,
                    readOnly: true,
                    hint: localizations.cannotBeChanged,
                  ),
                  const SizedBox(height: 10),
                  _TF(
                    ctrl: _emerCtrl,
                    label: localizations.emergencyContact,
                    icon: Icons.emergency_rounded,
                    cs: cs,
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Tenant Info Cards ──────────────────────────────────
                if (tenant != null) ...[
                  _Label(localizations.stayInfo),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: localizations.role,
                          value: localizations.tenant,
                          icon: Icons.person_rounded,
                          color: cs.primary,
                          cs: cs,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: localizations.status,
                          value: tenant.isActive
                              ? localizations.active
                              : localizations.inactive,
                          icon: Icons.circle_rounded,
                          color: tenant.isActive
                              ? AppColors.success
                              : AppColors.error,
                          cs: cs,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: localizations.aadhaar,
                          value: tenant.aadhaarVerified
                              ? localizations.verified
                              : localizations.pending,
                          icon: Icons.badge_rounded,
                          color: tenant.aadhaarVerified
                              ? AppColors.success
                              : AppColors.warning,
                          cs: cs,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: localizations.checkIn,
                          value: tenant.checkInCompleted
                              ? localizations.done
                              : localizations.pending,
                          icon: Icons.login_rounded,
                          color: tenant.checkInCompleted
                              ? AppColors.success
                              : AppColors.accent,
                          cs: cs,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Appearance ─────────────────────────────────────────
                _Label(localizations.appearance),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outline),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: isDark,
                    title: Text(
                      localizations.darkMode,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      localizations.useDarkTheme,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    activeColor: cs.primary,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).state = v
                        ? ThemeMode.dark
                        : ThemeMode.light,
                  ),
                ),
                _MenuTile(
                  context,
                  Icons.language_rounded,
                  localizations.selectLanguage,
                  () => showLanguageSelectorSheet(context, ref),
                  cs: cs,
                  theme: theme,
                ),
                const SizedBox(height: 20),

                // ── Settings ───────────────────────────────────────────
                _Label(localizations.more),
                _MenuTile(
                  context,
                  Icons.notifications_outlined,
                  localizations.notificationPreferences,
                  () {},
                  cs: cs,
                  theme: theme,
                ),
                _MenuTile(
                  context,
                  Icons.help_outline_rounded,
                  localizations.helpAndSupport,
                  () {},
                  cs: cs,
                  theme: theme,
                ),
                _MenuTile(
                  context,
                  Icons.privacy_tip_outlined,
                  localizations.privacyPolicy,
                  () {},
                  cs: cs,
                  theme: theme,
                ),
                pkgInfo.when(
                  data: (p) => _MenuTile(
                    context,
                    Icons.info_outline_rounded,
                    localizations.version('${p.version} (${p.buildNumber})'),
                    null,
                    cs: cs,
                    theme: theme,
                    trailing: const SizedBox(),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 24),

                // ── Sign Out ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.logout_rounded, color: cs.error, size: 18),
                    label: Text(
                      localizations.signOut,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: cs.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: cs.error.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _signOut,
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _TF extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final ColorScheme cs;
  final bool readOnly;
  final String? hint;
  const _TF({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.cs,
    this.readOnly = false,
    this.hint,
  });
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    readOnly: readOnly,
    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: cs.onSurface),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: cs.onSurfaceVariant),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: cs.onSurfaceVariant,
      ),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cs,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.surface,
      border: Border.all(color: cs.outline),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoRow {
  final IconData icon;
  final String label, value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  final ColorScheme cs;
  final ThemeData theme;
  const _InfoCard({required this.rows, required this.cs, required this.theme});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cs.surface,
      border: Border.all(color: cs.outline),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: rows
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(r.icon, size: 15, color: cs.primary),
                  const SizedBox(width: 10),
                  Text(
                    r.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      r.value,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

Widget _MenuTile(
  BuildContext context,
  IconData icon,
  String title,
  VoidCallback? onTap, {
  required ColorScheme cs,
  required ThemeData theme,
  Widget? trailing,
}) => Container(
  margin: const EdgeInsets.only(bottom: 8),
  decoration: BoxDecoration(
    color: cs.surface,
    border: Border.all(color: cs.outline),
    borderRadius: BorderRadius.circular(14),
  ),
  child: ListTile(
    leading: Icon(icon, size: 20, color: cs.onSurfaceVariant),
    title: Text(title, style: theme.textTheme.bodyMedium),
    trailing:
        trailing ??
        Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurfaceVariant),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
);
