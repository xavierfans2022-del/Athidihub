import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/logging/app_logger.dart';
import '../models/kyc_models.dart';
import '../providers/kyc_provider.dart';
import 'kyc_webview_screen.dart';

class KYCInitiationScreen extends ConsumerWidget {
  final String tenantId;

  const KYCInitiationScreen({
    required this.tenantId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycStatusAsync = ref.watch(kycStatusProvider(tenantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
        elevation: 0,
      ),
      body: kycStatusAsync.when(
        data: (status) => _buildKYCContent(context, ref, status),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(kycStatusProvider(tenantId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKYCContent(
    BuildContext context,
    WidgetRef ref,
    KYCStatus status,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(status),
          const SizedBox(height: 24),

          // Progress Indicator
          _buildProgressIndicator(status),
          const SizedBox(height: 24),

          // Main Actions
          if (status.status == KYCVerificationStatus.pending ||
              status.status == KYCVerificationStatus.retry)
            _buildVerificationOptions(context, ref, tenantId),

          if (status.status == KYCVerificationStatus.inProgress)
            _buildInProgressWidget(context, ref, status),

          if (status.status == KYCVerificationStatus.verified)
            _buildVerifiedWidget(),

          if (status.status == KYCVerificationStatus.rejected)
            _buildRejectedWidget(context, ref, status),

          if (status.status == KYCVerificationStatus.manualReview)
            _buildManualReviewWidget(),

          if (status.status == KYCVerificationStatus.expired)
            _buildExpiredWidget(context, ref),

          const SizedBox(height: 24),

          // Uploaded Documents Section
          if (status.documents.isNotEmpty)
            _buildUploadedDocuments(status.documents),

          const SizedBox(height: 24),

          // Info Section
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(KYCStatus status) {
    final statusColors = {
      KYCVerificationStatus.pending: Colors.blue,
      KYCVerificationStatus.inProgress: Colors.orange,
      KYCVerificationStatus.verified: Colors.green,
      KYCVerificationStatus.rejected: Colors.red,
      KYCVerificationStatus.manualReview: Colors.amber,
      KYCVerificationStatus.expired: Colors.grey,
      KYCVerificationStatus.retry: Colors.deepOrange,
    };

    final statusLabels = {
      KYCVerificationStatus.pending: 'Not Started',
      KYCVerificationStatus.inProgress: 'In Progress',
      KYCVerificationStatus.verified: 'Verified',
      KYCVerificationStatus.rejected: 'Rejected',
      KYCVerificationStatus.manualReview: 'Under Review',
      KYCVerificationStatus.expired: 'Expired',
      KYCVerificationStatus.retry: 'Retry Available',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColors[status.status]!.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status.status),
                    color: statusColors[status.status],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Status',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusLabels[status.status] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (status.nextAction != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  status.nextAction!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(KYCStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Completion Progress',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '${status.completionPercentage}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: status.completionPercentage / 100,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildVerificationOptions(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.verified_user),
            label: const Text('Verify with Aadhaar'),
            onPressed: () async {
              await _startAndOpenVerification(context, ref);
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.file_upload),
            label: const Text('Upload Documents (Fallback)'),
            onPressed: () {
              context.pushNamed(
                'kyc-document-upload',
                pathParameters: {'tenantId': tenantId},
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInProgressWidget(BuildContext context, WidgetRef ref, KYCStatus status) {
    final verification = status.verification;
    final canResume = verification?.verificationUrl != null;

    return Column(
      children: [
        Card(
          color: Colors.blue.withAlpha(26),
          child: const Padding(
            padding:  EdgeInsets.all(16),
            child: Column(
              children: [
               CircularProgressIndicator(),
               SizedBox(height: 16),
                 Text(
                  'Verification in Progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                 SizedBox(height: 8),
                 Text(
                  'Please wait while we verify your Aadhaar. This may take a few minutes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(canResume ? 'Continue Verification' : 'Refresh Status'),
            onPressed: () async {
              if (!canResume) {
                ref.invalidate(kycStatusProvider(tenantId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification URL not available yet. Status refreshed.')),
                  );
                }
                return;
              }

              await _openVerificationUrl(
                context: context,
                ref: ref,
                verificationUrl: verification!.verificationUrl!,
                sessionId: verification.digilockerSessionId,
                verificationId: verification.id,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedWidget() {
    return Column(
      children: [
        Card(
          color: Colors.green.withAlpha(26),
          child: const Padding(
            padding:  EdgeInsets.all(16),
            child: Column(
              children: [
                 Icon(Icons.check_circle, color: Colors.green, size: 48),
                 SizedBox(height: 16),
                 Text(
                  'KYC Verified Successfully',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                 SizedBox(height: 8),
                 Text(
                  'Your identity has been verified. You can now proceed with check-in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedWidget(
    BuildContext context,
    WidgetRef ref,
    KYCStatus status,
  ) {
    return Column(
      children: [
        Card(
          color: Colors.red.withAlpha(26),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Verification Rejected',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (status.verification?.failureReason != null)
                  Text(
                    'Reason: ${status.verification!.failureReason}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (status.verification?.canRetry == true)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final retryNotifier = ref.read(kycRetryProvider(tenantId).notifier);
                await retryNotifier.retryVerification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Retry initiated')),
                  );
                  ref.invalidate(kycStatusProvider(tenantId));
                }
              },
              child: const Text('Retry Verification'),
            ),
          ),
      ],
    );
  }

  Widget _buildManualReviewWidget() {
    return Card(
      color: Colors.amber.withAlpha(26),
      child:  const Padding(
        padding:  EdgeInsets.all(16),
        child: Column(
          children: [
             Icon(Icons.hourglass_empty, color: Colors.amber, size: 48),
            SizedBox(height: 16),
            Text(
              'Under Admin Review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
             SizedBox(height: 8),
             Text(
              'Your documents are being reviewed by our team. You will be notified once the review is complete.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredWidget(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Card(
          color: Colors.grey.withAlpha(26),
          child: const Padding(
            padding:  EdgeInsets.all(16),
            child: Column(
              children: [
                 Icon(Icons.schedule, color: Colors.grey, size: 48),
                 SizedBox(height: 16),
                 Text(
                  'Verification Expired',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                 SizedBox(height: 8),
                 Text(
                  'Your verification session has expired. Please start a new verification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await _startAndOpenVerification(context, ref);
            },
            child: const Text('Start New Verification'),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadedDocuments(List<KYCDocument> documents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uploaded Documents',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...documents.map((doc) => _buildDocumentTile(doc)),
      ],
    );
  }

  Widget _buildDocumentTile(KYCDocument doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(
            doc.verified ? Icons.check_circle : Icons.pending,
            color: doc.verified ? Colors.green : Colors.orange,
          ),
          title: Text(_getDocumentLabel(doc.documentType)),
          subtitle: Text(
            doc.verified
                ? 'Verified (${doc.verificationScore}%)'
                : 'Pending verification',
          ),
          trailing: doc.rejectionReason != null
              ? Tooltip(
                  message: doc.rejectionReason,
                  child: const Icon(Icons.info, color: Colors.red),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      color: Colors.blue.withAlpha(13),
      child: const Padding(
        padding:  EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'About KYC Verification',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
             SizedBox(height: 12),
             Text(
              '• KYC verification is required before check-in\n'
              '• We use secure Aadhaar verification for identity confirmation\n'
              '• Your data is encrypted and stored securely\n'
              '• Only the last 4 digits of Aadhaar are stored\n'
              '• Verification usually takes 5-10 minutes',
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAndOpenVerification(BuildContext context, WidgetRef ref) async {
    AppLogger.info('[KYC UI] Starting verification flow for tenant=$tenantId');
    final flowNotifier = ref.read(kycFlowStateProvider(tenantId).notifier);
    await flowNotifier.startVerification(sandboxMode: true);

    final flowState = ref.read(kycFlowStateProvider(tenantId));
    final initiation = flowState.initiationResponse;

    AppLogger.debug(
      '[KYC UI] Initiation completed: hasResponse=${initiation != null}, hasError=${flowState.error != null}',
    );

    if (!context.mounted) {
      AppLogger.warning('[KYC UI] Context unmounted before opening verification URL');
      return;
    }

    if (initiation == null || flowState.error != null) {
      final errorMessage = flowState.error ?? 'Unable to start verification';
      AppLogger.error('[KYC UI] Verification initiation failed: $errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMessage')),
      );
      return;
    }

    await _openVerificationUrl(
      context: context,
      ref: ref,
      verificationUrl: initiation.verificationUrl,
      sessionId: initiation.sessionId,
      verificationId: initiation.kycVerificationId,
    );
  }

  Future<void> _openVerificationUrl({
    required BuildContext context,
    required WidgetRef ref,
    required String verificationUrl,
    String? sessionId,
    String? verificationId,
  }) async {
    AppLogger.info('[KYC UI] Opening verification URL: $verificationUrl');
    AppLogger.debug('[KYC UI] Open decision', data: {
      'isWeb': kIsWeb,
      'hasSessionId': sessionId != null,
      'hasVerificationId': verificationId != null,
      'tenantId': tenantId,
    });

    final uri = Uri.tryParse(verificationUrl);
    if (uri == null) {
      AppLogger.error('[KYC UI] Invalid verification URL: $verificationUrl');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid verification URL returned by server.')),
        );
      }
      return;
    }

    if (kIsWeb) {
      final launched = await launchUrl(uri, webOnlyWindowName: '_self');
      AppLogger.info('[KYC UI] Web launch result: launched=$launched');
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open verification page.')),
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    if (sessionId == null || verificationId == null) {
      AppLogger.warning('[KYC UI] Missing session/verification IDs for WebView; falling back to external browser');
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      AppLogger.info('[KYC UI] External browser launch result', data: {'launched': launched});
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open verification page.')),
        );
      }
      return;
    }

    AppLogger.info('[KYC UI] Pushing KYCWebViewScreen', data: {
      'tenantId': tenantId,
      'verificationId': verificationId,
      'sessionId': sessionId,
    });

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => KYCWebViewScreen(
          tenantId: tenantId,
          authorizationUrl: verificationUrl,
          sessionId: sessionId,
          verificationId: verificationId,
        ),
      ),
    );

    AppLogger.info('[KYC UI] Returned from KYCWebViewScreen');

    if (context.mounted) {
      ref.invalidate(kycStatusProvider(tenantId));
    }
  }

  IconData _getStatusIcon(KYCVerificationStatus status) {
    switch (status) {
      case KYCVerificationStatus.pending:
        return Icons.radio_button_unchecked;
      case KYCVerificationStatus.inProgress:
        return Icons.hourglass_bottom;
      case KYCVerificationStatus.verified:
        return Icons.check_circle;
      case KYCVerificationStatus.rejected:
        return Icons.cancel;
      case KYCVerificationStatus.manualReview:
        return Icons.person_search;
      case KYCVerificationStatus.expired:
        return Icons.schedule;
      case KYCVerificationStatus.retry:
        return Icons.refresh;
    }
  }

  String _getDocumentLabel(KYCDocumentType type) {
    switch (type) {
      case KYCDocumentType.aadhaarFront:
        return 'Aadhaar (Front)';
      case KYCDocumentType.aadhaarBack:
        return 'Aadhaar (Back)';
      case KYCDocumentType.pan:
        return 'PAN Card';
      case KYCDocumentType.selfie:
        return 'Selfie';
    }
  }
}
