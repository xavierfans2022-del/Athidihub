import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:athidihub/core/logging/app_logger.dart';
import 'package:athidihub/core/services/backend_storage_service.dart';
import 'package:athidihub/l10n/app_localizations.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/theme/theme_mode_provider.dart';
import 'package:athidihub/features/auth/providers/auth_provider.dart';
import 'package:athidihub/core/providers/supabase_provider.dart';
import 'package:athidihub/features/dashboard/providers/reminder_provider.dart';
import 'package:athidihub/features/dashboard/providers/dashboard_provider.dart';
import 'package:athidihub/shared/widgets/language_selector_sheet.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    _nameCtrl.text =
        user?.userMetadata?['name'] ?? user?.userMetadata?['full_name'] ?? '';
    _phoneCtrl.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
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
      final fileName = file.path.split(RegExp(r'[\\/]')).last;
      final url = await ref
          .read(backendStorageServiceProvider)
          .uploadAvatar(bytes: bytes, fileName: fileName);
      ref.read(authNotifierProvider.notifier).reset();
      await ref.read(authNotifierProvider.notifier).updateUserData({
        'avatar_url': url,
      });
      final authState = ref.read(authNotifierProvider);
      if (authState.hasError)
        throw authState.error ?? 'Avatar metadata update failed';
      setState(() {});
      AppLogger.info('Avatar upload succeeded');
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.avatarUpdated),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Avatar upload failed', error: e);
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.uploadFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      ref.read(authNotifierProvider.notifier).reset();
      await ref.read(authNotifierProvider.notifier).updateUserData({
        'name': _nameCtrl.text.trim(),
        'full_name': _nameCtrl.text.trim(),
      });
      final authState = ref.read(authNotifierProvider);
      if (authState.hasError) throw authState.error ?? 'Profile update failed';
      setState(() => _isEditing = false);
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.profileUpdated),
            backgroundColor: AppColors.success,
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
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.error.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: colorScheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                localizations.signOutTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.signOutMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(c, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        localizations.cancel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        localizations.signOut,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final name = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text
      : (user?.phone ?? 'User');
    final phone = user?.phone ?? '';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    final packageInfo = ref.watch(_packageInfoProvider);
    final themeMode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final isDarkMode =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && brightness == Brightness.dark);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  )
                : null,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: colorScheme.onSurface),
                onPressed: () async {
                  // Simple refresh: re-read auth provider and package info
                  ref.invalidate(currentUserProvider);
                  ref.invalidate(_packageInfoProvider);
                },
              ),
              if (!_isEditing)
                TextButton.icon(
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    localizations.edit,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  onPressed: () => setState(() => _isEditing = true),
                )
              else
                TextButton.icon(
                  icon: _isSaving
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
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
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.15),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),
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
                                color: colorScheme.primary.withOpacity(0.3),
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
                                        color: AppColors.white,
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
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 13,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                if (_isEditing) ...[
                  _sectionLabel(context, localizations.personalInfo),
                  _buildTextField(
                    context,
                    _nameCtrl,
                    localizations.fullName,
                    Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context,
                    _phoneCtrl,
                    localizations.phone,
                    Icons.phone_outlined,
                    readOnly: true,
                    hint: localizations.cannotBeChanged,
                  ),
                  const SizedBox(height: 24),
                ],

                _sectionLabel(context, localizations.yourAccount),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        localizations.role,
                        localizations.owner,
                        Icons.admin_panel_settings_rounded,
                        colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        localizations.status,
                        localizations.active,
                        Icons.verified_rounded,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Actions (moved here to keep dashboard light)
                _profileQuickActions(context),
                const SizedBox(height: 24),

                _sectionLabel(context, localizations.appearance),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: isDarkMode,
                    title: Text(
                      localizations.darkMode,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      localizations.useDarkAppearanceAcrossApp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).state = value
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                _sectionLabel(context, localizations.organization),
                _menuTile(
                  context,
                  Icons.business_rounded,
                  localizations.organizationDetails,
                  () {
                    // TODO: Replace with dynamic organization ID from user's current organization
                    // For now, navigate with placeholder - backend should support fetching user's primary org
                    context.push('/organization/primary');
                  },
                ),
                const SizedBox(height: 24),

                _sectionLabel(context, localizations.settings),
                _menuTile(
                  context,
                  Icons.notifications_outlined,
                  localizations.notificationPreferences,
                  () {},
                ),
                _menuTile(
                  context,
                  Icons.language_rounded,
                  localizations.languageAndRegion,
                  () => showLanguageSelectorSheet(context, ref),
                ),
                _menuTile(
                  context,
                  Icons.security_rounded,
                  localizations.securityAndPassword,
                  () {},
                ),
                _menuTile(
                  context,
                  Icons.privacy_tip_outlined,
                  localizations.privacyPolicy,
                  () {},
                ),
                _menuTile(
                  context,
                  Icons.help_outline_rounded,
                  localizations.helpAndSupport,
                  () {},
                ),
                const SizedBox(height: 8),

                _sectionLabel(context, localizations.about),
                packageInfo.when(
                  data: (info) => _menuTile(
                    context,
                    Icons.info_outline_rounded,
                    localizations.version(
                      '${info.version} (${info.buildNumber})',
                    ),
                    null,
                    trailing: const SizedBox(),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(
                      Icons.logout_rounded,
                      color: colorScheme.error,
                      size: 18,
                    ),
                    label: Text(
                      localizations.signOut,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(
                        color: colorScheme.error.withOpacity(0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _confirmSignOut,
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

  Widget _sectionLabel(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool readOnly = false,
    String? hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
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
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback? onTap, {
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        title: Text(title, style: theme.textTheme.bodyMedium),
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _profileQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    Widget action(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap,
    ) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.18)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.quickActions,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              action(
                Icons.person_add_rounded,
                localizations.addTenant,
                AppColors.secondary,
                () => context.go('/tenants/add'),
              ),
              const SizedBox(width: 10),
              action(
                Icons.home_work_rounded,
                localizations.addProperty,
                AppColors.primary,
                () => context.go('/properties/add'),
              ),
              const SizedBox(width: 10),
              action(
                Icons.receipt_long_rounded,
                localizations.invoices,
                AppColors.warning,
                () => context.go('/invoices'),
              ),
              const SizedBox(width: 10),
              action(
                Icons.verified_user_rounded,
                localizations.kycReview,
                AppColors.info,
                () => context.go('/admin/kyc-review'),
              ),
              const SizedBox(width: 10),
              action(
                Icons.notifications_active_rounded,
                'Reminders',
                AppColors.warning,
                () async {
                  final orgId = await ref.read(
                    selectedOrganizationIdProvider.future,
                  );
                  if (orgId == null) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations.noOrganizationSelected),
                        ),
                      );
                    return;
                  }
                  int daysAhead = 3;
                  String? message;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (c) => StatefulBuilder(
                      builder: (c, setSt) {
                        return AlertDialog(
                          scrollable: true,
                          title: Text(localizations.sendPaymentReminders),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<int>(
                                value: daysAhead,
                                items: [1, 3, 7, 14]
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(localizations.daysCount(d)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setSt(() => daysAhead = v ?? daysAhead),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: localizations.optionalMessage,
                                ),
                                onChanged: (t) => message = t,
                                maxLines: 3,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text(localizations.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: Text(localizations.send),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                  if (confirmed == true) {
                    final res = await ref
                        .read(reminderSendProvider.notifier)
                        .sendPaymentReminders(
                          organizationId: orgId,
                          daysAhead: daysAhead,
                          message: message,
                        );
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            res != null
                                ? localizations.remindersQueued
                                : localizations.failedToSendReminders,
                          ),
                        ),
                      );
                  }
                },
              ),
              const SizedBox(width: 10),
              action(
                Icons.build_rounded,
                localizations.maintenance,
                AppColors.info,
                () => context.go('/maintenance'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
