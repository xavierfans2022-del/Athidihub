import 'package:athidihub/core/providers/locale_provider.dart';
import 'package:athidihub/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showLanguageSelectorSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final localizations = AppLocalizations.of(context)!;
  final currentLocale = ref.read(localePreferenceProvider).valueOrNull;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colorScheme = theme.colorScheme;
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.selectLanguage,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  localizations.chooseAppLanguage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _LanguageOption(
                  label: localizations.systemDefault,
                  isSelected: currentLocale == null,
                  onTap: () async {
                    await ref
                        .read(localePreferenceProvider.notifier)
                        .setLocale(null);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _LanguageOption(
                  label: localizations.english,
                  isSelected: currentLocale?.languageCode == 'en',
                  onTap: () async {
                    await ref
                        .read(localePreferenceProvider.notifier)
                        .setLocale(const Locale('en'));
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _LanguageOption(
                  label: localizations.hindi,
                  isSelected: currentLocale?.languageCode == 'hi',
                  onTap: () async {
                    await ref
                        .read(localePreferenceProvider.notifier)
                        .setLocale(const Locale('hi'));
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _LanguageOption(
                  label: localizations.telugu,
                  isSelected: currentLocale?.languageCode == 'te',
                  onTap: () async {
                    await ref
                        .read(localePreferenceProvider.notifier)
                        .setLocale(const Locale('te'));
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.35)
                  : colorScheme.outline,
            ),
          ),
          minVerticalPadding: 12,
          title: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
