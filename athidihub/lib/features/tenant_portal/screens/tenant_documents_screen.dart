import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/theme/app_colors.dart';
import 'package:athidihub/core/logging/app_logger.dart';
import 'package:athidihub/features/kyc/models/kyc_models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:athidihub/features/kyc/providers/kyc_provider.dart';
import 'package:athidihub/features/kyc/screens/kyc_webview_screen.dart';
import 'package:athidihub/features/tenant_portal/providers/tenant_portal_provider.dart';
import 'package:athidihub/l10n/app_localizations.dart';

class TenantDocumentsScreen extends ConsumerWidget {
  const TenantDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(tenantDashboardProvider);
    final tenantId = dashAsync.valueOrNull?.tenant.id;

    if (tenantId == null) {
      return Scaffold(
        appBar: AppBar(
          leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
          title: Text(AppLocalizations.of(context)!.documents, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final kycStatusAsync = ref.watch(kycStatusProvider(tenantId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.documents, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(kycStatusProvider(tenantId));
              ref.invalidate(tenantDashboardProvider);
            },
          ),
        ],
      ),
      body: kycStatusAsync.when(
        data: (status) => _buildContent(context, ref, tenantId, status, dashAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.errorLoadingDocuments, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(error.toString(), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(kycStatusProvider(tenantId)),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, String tenantId, KYCStatus status, AsyncValue dashAsync) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _StatusBanner(status: status, cs: cs),
        const SizedBox(height: 24),
        _buildStatusCard(context, cs, status),
        const SizedBox(height: 24),
        _buildProgressIndicator(context, status),
        const SizedBox(height: 24),
        if (status.status == KYCVerificationStatus.pending || status.status == KYCVerificationStatus.retry)
          _buildVerificationOptions(context, ref, tenantId),
        if (status.status == KYCVerificationStatus.inProgress) _buildInProgressWidget(context, cs),
        if (status.status == KYCVerificationStatus.verified) _buildVerifiedWidget(context, cs),
        if (status.status == KYCVerificationStatus.rejected) _buildRejectedWidget(context, ref, tenantId, status, cs),
        if (status.status == KYCVerificationStatus.manualReview) _buildManualReviewWidget(context, cs),
        if (status.status == KYCVerificationStatus.expired) _buildExpiredWidget(context, ref, tenantId, cs),
        const SizedBox(height: 24),
        if (status.documents.isNotEmpty) ...[
          _buildUploadedDocumentsHeader(context),
          const SizedBox(height: 12),
          ..._buildDocumentsList(context, ref, tenantId, status.documents),
          const SizedBox(height: 24),
        ],
        _DocCard(
          title: 'Rental Agreement',
          subtitle: 'Issued by the PG owner after check-in is complete',
          icon: Icons.description_rounded,
          status: dashAsync.valueOrNull?.tenant.checkInCompleted == true ? _DocStatus.verified : _DocStatus.notUploaded,
          cs: cs,
          theme: theme,
          readOnly: true,
        ),
        const SizedBox(height: 24),
        _buildInfoSection(cs),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, ColorScheme cs, KYCStatus status) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColors[status.status]!.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getStatusIcon(status.status), color: statusColors[status.status]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.verificationStatusTitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(statusLabels[status.status] ?? 'Unknown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  ],
                ),
              ),
            ],
          ),
          if (status.nextAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(status.nextAction!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, KYCStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.completionProgress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
            Text('${status.completionPercentage}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
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

  Widget _buildVerificationOptions(BuildContext context, WidgetRef ref, String tenantId) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.security_rounded),
            label: Text(AppLocalizations.of(context)!.startKycVerificationButton),
            onPressed: () async {
              AppLogger.info('[Tenant Documents] Start KYC tapped', data: {'tenantId': tenantId});
              final notifier = ref.read(kycVerificationProvider(tenantId).notifier);
              await notifier.initiateVerification();
              final state = ref.read(kycVerificationProvider(tenantId));

              if (!context.mounted) return;

              if (state.hasError) {
                final error = state.error;
                final message = error is DioException
                    ? error.response?.data is Map<String, dynamic>
                        ? (error.response!.data['message']?.toString() ?? error.message ?? 'KYC verification failed')
                        : (error.message ?? 'KYC verification failed')
                    : 'KYC verification failed';

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message), backgroundColor: Colors.red),
                );

                if (message.contains('KYC provider configuration missing')) {
                  context.pushNamed(
                    'kyc-document-upload',
                    pathParameters: {'tenantId': tenantId},
                  );
                }
                return;
              }

              final initiation = state.value;
              if (initiation == null) {
                AppLogger.error('[Tenant Documents] KYC initiation returned null response', data: {'tenantId': tenantId});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.couldNotStartKyc)),
                );
                return;
              }

              await _openVerificationUrl(
                context: context,
                ref: ref,
                tenantId: tenantId,
                verificationUrl: initiation.verificationUrl,
                sessionId: initiation.sessionId,
                verificationId: initiation.kycVerificationId,
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.file_upload_rounded),
            label: Text(AppLocalizations.of(context)!.openDocumentUploadButton),
            onPressed: () {
              context.pushNamed(
                'kyc-document-upload',
                pathParameters: {'tenantId': tenantId},
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInProgressWidget(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.verificationInProgressTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.verificationInProgressSubtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildVerifiedWidget(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.kycVerifiedSuccessfullyTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.kycVerifiedSuccessfullySubtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildRejectedWidget(BuildContext context, WidgetRef ref, String tenantId, KYCStatus status, ColorScheme cs) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.verificationRejectedTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
              if (status.verification?.failureReason != null) ...[
                const SizedBox(height: 8),
                Text('Reason: ${status.verification!.failureReason}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (status.verification?.canRetry == true)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(kycRetryProvider(tenantId).notifier).retryVerification();
                ref.invalidate(kycStatusProvider(tenantId));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.retryInitiated)));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.retryVerification),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildManualReviewWidget(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          Text('Under Admin Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text('Your documents are being reviewed by our team. You will be notified once the review is complete.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildExpiredWidget(BuildContext context, WidgetRef ref, String tenantId, ColorScheme cs) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Icon(Icons.schedule_rounded, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text('Verification Expired', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
              const SizedBox(height: 8),
              Text('Your verification session has expired. Please start a new verification.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              AppLogger.info('[Tenant Documents] Start new verification tapped', data: {'tenantId': tenantId});
              await ref.read(kycVerificationProvider(tenantId).notifier).initiateVerification();
              final state = ref.read(kycVerificationProvider(tenantId));

              if (!context.mounted) return;

              final initiation = state.value;
              if (state.hasError || initiation == null) {
                AppLogger.error('[Tenant Documents] Restart verification failed or returned null', data: {'tenantId': tenantId});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.couldNotStartKyc)),
                );
                ref.invalidate(kycStatusProvider(tenantId));
                return;
              }

              await _openVerificationUrl(
                context: context,
                ref: ref,
                tenantId: tenantId,
                verificationUrl: initiation.verificationUrl,
                sessionId: initiation.sessionId,
                verificationId: initiation.kycVerificationId,
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppLocalizations.of(context)!.startNewVerification),
          ),
        ),
      ],
    );
  }

  Future<void> _openVerificationUrl({
    required BuildContext context,
    required WidgetRef ref,
    required String tenantId,
    required String verificationUrl,
    required String sessionId,
    required String verificationId,
  }) async {
    AppLogger.info('[Tenant Documents] Opening verification URL', data: {
      'tenantId': tenantId,
      'sessionId': sessionId,
      'verificationId': verificationId,
      'isWeb': kIsWeb,
    });

    final uri = Uri.tryParse(verificationUrl);
    if (uri == null) {
      AppLogger.error('[Tenant Documents] Invalid verification URL', data: {'verificationUrl': verificationUrl});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.invalidKycVerificationUrl)),
      );
      return;
    }

    if (kIsWeb) {
      final launched = await launchUrl(uri, webOnlyWindowName: '_self');
      AppLogger.info('[Tenant Documents] Web launch result', data: {'launched': launched});
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenKycVerificationPage)),
        );
      }
      return;
    }

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => KYCWebViewScreen(
          tenantId: tenantId,
          authorizationUrl: verificationUrl,
          sessionId: sessionId,
          verificationId: verificationId,
        ),
      ),
    );

    AppLogger.info('[Tenant Documents] Returned from verification WebView', data: {'tenantId': tenantId});
    if (context.mounted) {
      ref.invalidate(kycStatusProvider(tenantId));
    }
  }

  Widget _buildUploadedDocumentsHeader(BuildContext context) {
    return Text(AppLocalizations.of(context)!.uploadedDocuments, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter'));
  }

  List<Widget> _buildDocumentsList(BuildContext context, WidgetRef ref, String tenantId, List<KYCDocument> documents) {
    return documents.map((doc) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          child: ListTile(
            leading: Icon(doc.verified ? Icons.check_circle_rounded : Icons.pending_rounded, color: doc.verified ? Colors.green : Colors.orange),
            title: Text(_getDocumentLabel(doc.documentType)),
            subtitle: Text(doc.verified ? AppLocalizations.of(context)!.verifiedWithScore(doc.verificationScore ?? 0) : AppLocalizations.of(context)!.pendingVerification),
            onTap: doc.fileUrl != null ? () async {
              final uri = Uri.tryParse(doc.fileUrl!);
                if (uri != null) {
                if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenDocument)));
                }
              }
            } : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (doc.fileUrl != null) IconButton(
                  icon: const Icon(Icons.visibility_rounded),
                  tooltip: AppLocalizations.of(context)!.view,
                  onPressed: () async {
                    final uri = Uri.tryParse(doc.fileUrl!);
                      if (uri != null) {
                      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenDocument)));
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file_rounded),
                  tooltip: AppLocalizations.of(context)!.reupload,
                  onPressed: () {
                    context.pushNamed('kyc-document-upload', pathParameters: {'tenantId': tenantId});
                  },
                ),
                if (doc.rejectionReason != null)
                  Tooltip(message: doc.rejectionReason, child: const Icon(Icons.info_rounded, color: Colors.red)),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildInfoSection(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Text('About KYC Verification', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary)),
          ]),
          const SizedBox(height: 10),
          Text(
            '• KYC verification is required before check-in\n'
            '• We use secure Aadhaar verification for identity confirmation\n'
            '• Your data is encrypted and stored securely\n'
            '• Only the last 4 digits of Aadhaar are stored\n'
            '• Verification usually takes 5-10 minutes',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.onSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(KYCVerificationStatus status) {
    switch (status) {
      case KYCVerificationStatus.pending:
        return Icons.radio_button_unchecked_rounded;
      case KYCVerificationStatus.inProgress:
        return Icons.hourglass_bottom_rounded;
      case KYCVerificationStatus.verified:
        return Icons.check_circle_rounded;
      case KYCVerificationStatus.rejected:
        return Icons.cancel_rounded;
      case KYCVerificationStatus.manualReview:
        return Icons.person_search_rounded;
      case KYCVerificationStatus.expired:
        return Icons.schedule_rounded;
      case KYCVerificationStatus.retry:
        return Icons.refresh_rounded;
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

class _StatusBanner extends StatelessWidget {
  final KYCStatus status;
  final ColorScheme cs;

  const _StatusBanner({required this.status, required this.cs});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String title;
    final String sub;

    switch (status.status) {
      case KYCVerificationStatus.verified:
        color = AppColors.success;
        icon = Icons.verified_rounded;
        title = 'Identity Verified';
        sub = 'Your Aadhaar has been verified';
        break;
      case KYCVerificationStatus.inProgress:
      case KYCVerificationStatus.manualReview:
        color = AppColors.warning;
        icon = Icons.pending_rounded;
        title = 'Verification In Progress';
        sub = 'Your document is being reviewed';
        break;
      case KYCVerificationStatus.rejected:
        color = AppColors.error;
        icon = Icons.error_rounded;
        title = 'Verification Rejected';
        sub = 'Please try again or upload manually';
        break;
      default:
        color = cs.primary;
        icon = Icons.upload_file_rounded;
        title = 'Upload Required';
        sub = 'Please verify your Aadhaar to proceed';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 3),
                Text(sub, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _DocStatus { notUploaded, pending, verified }

class _DocCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final _DocStatus status;
  final ColorScheme cs;
  final ThemeData theme;
  final bool readOnly;

  const _DocCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    required this.cs,
    required this.theme,
    this.readOnly = false,
  });

  Color get _statusColor => switch (status) {
    _DocStatus.verified => AppColors.success,
    _DocStatus.pending => AppColors.warning,
    _DocStatus.notUploaded => cs.onSurfaceVariant,
  };

  String get _statusLabel => switch (status) {
    _DocStatus.verified => 'Ready',
    _DocStatus.pending => 'Pending',
    _DocStatus.notUploaded => 'Not Ready',
  };

  IconData get _statusIcon => switch (status) {
    _DocStatus.verified => Icons.check_circle_rounded,
    _DocStatus.pending => Icons.pending_rounded,
    _DocStatus.notUploaded => Icons.radio_button_unchecked_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant, height: 1.4)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon, size: 11, color: _statusColor),
                  const SizedBox(width: 4),
                  Text(_statusLabel, style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
