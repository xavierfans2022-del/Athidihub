import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/logging/app_logger.dart';
import '../providers/kyc_provider.dart';

class KYCWebViewScreen extends ConsumerStatefulWidget {
  final String tenantId;
  final String authorizationUrl;
  final String sessionId;
  final String verificationId;

  const KYCWebViewScreen({
    required this.tenantId,
    required this.authorizationUrl,
    required this.sessionId,
    required this.verificationId,
    super.key,
  });

  @override
  ConsumerState<KYCWebViewScreen> createState() => _KYCWebViewScreenState();
}

class _KYCWebViewScreenState extends ConsumerState<KYCWebViewScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppLogger.info('[KYC WebView] initState', data: {
      'tenantId': widget.tenantId,
      'verificationId': widget.verificationId,
      'sessionId': widget.sessionId,
      'authorizationUrl': widget.authorizationUrl,
    });
    _initializeWebView();
  }

  void _initializeWebView() {
    final uri = Uri.tryParse(widget.authorizationUrl);
    if (uri == null) {
      AppLogger.error('[KYC WebView] Invalid authorization URL', data: {
        'authorizationUrl': widget.authorizationUrl,
      });
      setState(() {
        _error = 'Invalid authorization URL';
        _isLoading = false;
      });
      return;
    }

    AppLogger.debug('[KYC WebView] Initializing WebViewController', data: {
      'scheme': uri.scheme,
      'host': uri.host,
      'path': uri.path,
      'hasQuery': uri.query.isNotEmpty,
    });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            AppLogger.debug('[KYC WebView] Page started', data: {'url': url});
            if (mounted) {
              setState(() => _isLoading = true);
            }
            _checkForCallback(url);
          },
          onPageFinished: (String url) {
            AppLogger.debug('[KYC WebView] Page finished', data: {'url': url});
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _checkForCallback(url);
          },
          onWebResourceError: (WebResourceError error) {
            AppLogger.error('[KYC WebView] Web resource error', data: {
              'description': error.description,
              'errorType': error.errorType.toString(),
              'url': error.url,
              'isForMainFrame': error.isForMainFrame,
            });
            if (mounted) {
              setState(() {
                _error = error.description;
                _isLoading = false;
              });
            }
          },
          onProgress: (int progress) {
            AppLogger.debug('[KYC WebView] Load progress', data: {'progress': progress});
            if (mounted) {
              setState(() => _progress = progress / 100);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            AppLogger.debug('[KYC WebView] Navigation request', data: {'url': request.url});

            if (_isCallbackUrl(request.url)) {
              AppLogger.info('[KYC WebView] Callback detected', data: {'url': request.url});
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    AppLogger.info('[KYC WebView] Loading authorization URL', data: {'url': uri.toString()});
    try {
      _webViewController.loadRequest(uri);
    } catch (e, stackTrace) {
      AppLogger.error('[KYC WebView] Failed to load authorization URL', error: e, stackTrace: stackTrace);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Check if URL is the callback URL
  bool _isCallbackUrl(String url) {
    return url.contains('/api/kyc/callback/digilocker') ||
        url.contains('api.sandbox.co.in/callbacks') ||
        url.startsWith('http://192.168') && url.contains('kyc/callback');
  }

  /// Check for callback in current URL
  void _checkForCallback(String url) {
    AppLogger.debug('[KYC WebView] Checking URL for callback', data: {'url': url});
    if (_isCallbackUrl(url)) {
      AppLogger.info('[KYC WebView] Callback URL detected: $url');
      _handleCallback(url);
    }
  }

  /// Handle callback URL extraction
  Future<void> _handleCallback(String callbackUrl) async {
    try {
      AppLogger.debug('[KYC WebView] Handling callback: $callbackUrl');
      
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      AppLogger.debug('[KYC WebView] Parsed callback parameters', data: {
        'hasCode': code != null,
        'hasState': state != null,
        'hasError': error != null,
        'queryKeys': uri.queryParameters.keys.toList(),
      });

      if (error != null) {
        AppLogger.error('[KYC WebView] Callback error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: $error')),
          );
          context.pop();
        }
        return;
      }

      if (code == null) {
        AppLogger.error('[KYC WebView] No authorization code in callback');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authorization code not received')),
          );
        }
        return;
      }

      AppLogger.info('[KYC WebView] Authorization code received', data: {
        'preview': code.length > 10 ? '${code.substring(0, 10)}...' : code,
        'verificationId': widget.verificationId,
        'sessionId': widget.sessionId,
      });

      // Show loading dialog
      if (mounted) {
        AppLogger.debug('[KYC WebView] Showing processing dialog');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verifying your identity...'),
                ],
              ),
            ),
          ),
        );
      }

      // Process callback via API
      final flowNotifier = ref.read(kycFlowStateProvider(widget.tenantId).notifier);
      AppLogger.debug('[KYC WebView] Calling processOAuthCallback');
      await flowNotifier.processOAuthCallback(
        code: code,
        state: state,
        sessionId: widget.sessionId,
        verificationId: widget.verificationId,
      );
      AppLogger.info('[KYC WebView] processOAuthCallback completed');

      // Close loading dialog and navigate back
      if (mounted) {
        AppLogger.debug('[KYC WebView] Closing processing dialog and returning to previous screen');
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification completed successfully!')),
        );
        Future.delayed(const Duration(milliseconds: 1500), () {
          AppLogger.debug('[KYC WebView] Delayed pop after success');
          if (mounted) context.pop(); // Close WebView
          ref.invalidate(kycStatusProvider(widget.tenantId));
        });
      }
    } catch (e) {
      AppLogger.error('[KYC WebView] Callback handling error', error: e);
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('[KYC WebView] build invoked', data: {
      'isLoading': _isLoading,
      'progress': _progress,
      'hasError': _error != null,
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        AppLogger.debug('[KYC WebView] Pop requested', data: {'didPop': didPop});
        if (didPop) {
          return;
        }

        final navigator = Navigator.of(context);

        if (await _webViewController.canGoBack()) {
          AppLogger.debug('[KYC WebView] WebView canGoBack=true, going back');
          await _webViewController.goBack();
        } else if (mounted) {
          AppLogger.debug('[KYC WebView] WebView cannot go back, popping screen');
          navigator.pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KYC Verification'),
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
            WebViewWidget(controller: _webViewController),
            if (_isLoading && _progress < 1.0)
              LinearProgressIndicator(value: _progress),
            if (_error != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _initializeWebView();
                      },
                      child: const Text('Retry'),
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
