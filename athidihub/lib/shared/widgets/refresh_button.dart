import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/l10n/app_localizations.dart';

/// Production-level refresh button with rate limiting, loading state, and user feedback
class RefreshButton extends ConsumerStatefulWidget {
  final String label;
  final Future<void> Function() onRefresh;
  final Duration rateLimitWindow;
  final Icon? icon;

  const RefreshButton({
    super.key,
    this.label = 'Refresh',
    required this.onRefresh,
    this.rateLimitWindow = const Duration(seconds: 2),
    this.icon,
  });

  @override
  ConsumerState<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<RefreshButton> {
  bool _isLoading = false;
  DateTime? _nextAllowedRefresh;

  Future<void> _handleRefresh() async {
    final now = DateTime.now();
    final localizations = AppLocalizations.of(context)!;

    // Check rate limit
    if (_nextAllowedRefresh != null && now.isBefore(_nextAllowedRefresh!)) {
      final secondsLeft = (_nextAllowedRefresh!.difference(now).inMilliseconds / 1000).ceil();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseWaitBeforeRefreshingAgain(secondsLeft)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.onRefresh();
      _nextAllowedRefresh = DateTime.now().add(widget.rateLimitWindow);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.dataRefreshedSuccessfully),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.failedToRefresh(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = _isLoading || (_nextAllowedRefresh != null && DateTime.now().isBefore(_nextAllowedRefresh!));
    final localizations = AppLocalizations.of(context)!;

    return FilledButton.icon(
      onPressed: isDisabled ? null : _handleRefresh,
      icon: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : (widget.icon ?? const Icon(Icons.refresh_rounded)),
      label: Text(_isLoading ? localizations.refreshing : widget.label),
    );
  }
}
