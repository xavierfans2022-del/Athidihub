import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/logging/app_logger.dart';
import 'package:athidihub/l10n/app_localizations.dart';

/// Reusable WebView widget with built-in error handling, progress tracking, and callback support
class AppWebView extends StatefulWidget {
  final String url;
  final Function(String url)? onUrlChanged;
  final Function(String error)? onError;
  final Function()? onPageFinished;
  final Function(int progress)? onProgress;
  final bool enableJavaScript;
  final Set<String>? callbackUrlPatterns; // URLs that trigger onUrlChanged callback
  final Duration? loadTimeout;

  const AppWebView({
    required this.url,
    this.onUrlChanged,
    this.onError,
    this.onPageFinished,
    this.onProgress,
    this.enableJavaScript = true,
    this.callbackUrlPatterns,
    this.loadTimeout = const Duration(seconds: 30),
    super.key,
  });

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(
        widget.enableJavaScript ? JavaScriptMode.unrestricted : JavaScriptMode.disabled,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            AppLogger.debug('[AppWebView] Page started: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            AppLogger.debug('[AppWebView] Page finished: $url');
            setState(() => _isLoading = false);
            widget.onPageFinished?.call();
            _checkCallbackUrl(url);
          },
          onWebResourceError: (WebResourceError error) {
            AppLogger.error('[AppWebView] Error: ${error.description}');
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
            widget.onError?.call(error.description);
          },
          onProgress: (int progress) {
            setState(() => _progress = progress / 100);
            widget.onProgress?.call(progress);
          },
          onNavigationRequest: (NavigationRequest request) {
            _checkCallbackUrl(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Check if URL matches any callback patterns
  void _checkCallbackUrl(String url) {
    if (widget.callbackUrlPatterns != null) {
      for (final pattern in widget.callbackUrlPatterns!) {
        if (url.contains(pattern)) {
          AppLogger.info('[AppWebView] Callback URL matched: $url');
          widget.onUrlChanged?.call(url);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        final navigator = Navigator.of(context);
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else if (mounted) {
          navigator.pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.webView),
          elevation: 0,
          actions: [
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading && _progress < 1.0)
              LinearProgressIndicator(value: _progress),
            if (_error != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        localizations.errorPrefix(_error ?? ''),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _initializeWebView();
                      },
                      child: Text(localizations.retry),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

}
