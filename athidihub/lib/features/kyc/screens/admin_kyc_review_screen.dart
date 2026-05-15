import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kyc_models.dart';
import '../providers/kyc_provider.dart';
import 'package:athidihub/features/tenant_portal/providers/tenant_portal_provider.dart';
import 'package:athidihub/shared/widgets/refresh_button.dart';

class AdminKYCReviewScreen extends ConsumerStatefulWidget {
  const AdminKYCReviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminKYCReviewScreen> createState() =>
      _AdminKYCReviewScreenState();
}

class _AdminKYCReviewScreenState extends ConsumerState<AdminKYCReviewScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchQuery = '';
  String _filter = 'all'; // all | flagged | unflagged

  @override
  Widget build(BuildContext context) {
    final pendingReviewsAsync = ref.watch(
      kycAdminPendingReviewsProvider((
        skip: _currentPage * _itemsPerPage,
        take: _itemsPerPage,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('KYC Review'),
        elevation: 0,
        actions: [
          RefreshButton(
            label: 'Refresh',
            onRefresh: () async {
              ref.invalidate(kycAdminPendingReviewsProvider((
                skip: _currentPage * _itemsPerPage,
                take: _itemsPerPage,
              )));
              await ref.read(kycAdminPendingReviewsProvider((
                skip: _currentPage * _itemsPerPage,
                take: _itemsPerPage,
              )).future);
            },
          ),
        ],
      ),
      body: pendingReviewsAsync.when(
        data: (data) => _buildReviewList(context, data),
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
                onPressed: () => ref.refresh(
                  kycAdminPendingReviewsProvider((
                    skip: _currentPage * _itemsPerPage,
                    take: _itemsPerPage,
                  )),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewList(BuildContext context, Map<String, dynamic> data) {
    final pending = List<Map<String, dynamic>>.from(data['pending'] ?? []);
    // apply client-side search + filter
    final query = _searchQuery.trim().toLowerCase();
    var filtered = pending.where((p) {
      if (_filter == 'flagged' && p['flaggedForSuspicion'] != true) return false;
      if (_filter == 'unflagged' && p['flaggedForSuspicion'] == true) return false;
      if (query.isEmpty) return true;
      final name = (p['tenantName'] ?? '').toString().toLowerCase();
      final email = (p['tenantEmail'] ?? '').toString().toLowerCase();
      return name.contains(query) || email.contains(query) || p['tenantId'].toString().contains(query);
    }).toList();
    final totalPending = data['totalPending'] ?? 0;
    final totalPages = (totalPending / _itemsPerPage).ceil();

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'All KYC verifications are up to date!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search & filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name, email or id', border: OutlineInputBorder()),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'flagged', child: Text('Flagged')),
                  DropdownMenuItem(value: 'unflagged', child: Text('Unflagged')),
                ],
                onChanged: (v) => setState(() => _filter = v ?? 'all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildReviewCard(context, filtered[index]),
          ),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text(
                  'Page ${_currentPage + 1} of $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> item) {
    final tenantId = item['tenantId'];
    final tenantName = item['tenantName'] ?? 'Unknown';
    final createdAt = DateTime.parse(item['createdAt'] ?? '');
    final daysAgo = DateTime.now().difference(createdAt).inDays;
    final flagged = item['flaggedForSuspicion'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: flagged
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning, color: Colors.red),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_add, color: Colors.blue),
              ),
        title: Text(tenantName),
        subtitle: Text('$daysAgo days ago'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showReviewDetails(context, tenantId),
      ),
    );
  }

  void _showReviewDetails(BuildContext context, String tenantId) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AdminKYCDetailPanel(tenantId: tenantId),
    ).then((approved) {
      if (approved == true) {
        ref.invalidate(
          kycAdminPendingReviewsProvider((
            skip: _currentPage * _itemsPerPage,
            take: _itemsPerPage,
          )),
        );
      }
    });
  }
}

class AdminKYCDetailPanel extends ConsumerStatefulWidget {
  final String tenantId;

  const AdminKYCDetailPanel({required this.tenantId, Key? key}) : super(key: key);

  @override
  ConsumerState<AdminKYCDetailPanel> createState() =>
      _AdminKYCDetailPanelState();
}

class _AdminKYCDetailPanelState extends ConsumerState<AdminKYCDetailPanel> {
  late TextEditingController _notesController;
  String? _suspicionReason;
  bool _flagForSuspicion = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kycDetailsAsync =
        ref.watch(kycDetailsProvider(widget.tenantId));

    return kycDetailsAsync.when(
      data: (details) {
        if (details == null) {
          return _buildMissingKycPanel(context);
        }
        return _buildDetailPanel(context, details);
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: 200,
        child: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildMissingKycPanel(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.34,
      minChildSize: 0.24,
      maxChildSize: 0.48,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  size: 42,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No KYC record found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'This tenant has not started KYC yet, so there is nothing to review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(BuildContext context, KYCDetails details) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Review KYC Verification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tenant Info
              if (details.tenantInfo != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tenant Information',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Name: ${details.tenantInfo!.name}'),
                        Text('Email: ${details.tenantInfo!.email}'),
                        Text('Phone: ${details.tenantInfo!.phone}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Verification Status
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Status: ${details.verification.status}'),
                      Text(
                        'Aadhaar: ${details.verification.maskedAadhaarNumber ?? 'Not verified'}',
                      ),
                      Text(
                        'Reference ID: ${details.verification.verificationReferenceId ?? 'N/A'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Uploaded Documents
              if (details.documents.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uploaded Documents',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...details.documents.map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            leading: SizedBox(
                              width: 56,
                              height: 56,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: doc.fileUrl != null
                                    ? Image.network(
                                        doc.fileUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: Colors.grey.shade200,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            doc.verified ? Icons.check_circle : Icons.description,
                                            color: doc.verified ? Colors.green : Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          doc.verified ? Icons.check_circle : Icons.description,
                                          color: doc.verified ? Colors.green : Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(_getDocumentLabel(doc.documentType)),
                            subtitle: Text(
                              doc.verified
                                  ? 'Verified'
                                  : (doc.fileUrl != null ? 'Tap open to preview' : 'Pending'),
                            ),
                            trailing: doc.fileUrl != null
                                ? IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    tooltip: 'Open document',
                                    onPressed: () => _openDocumentPreview(
                                      context,
                                      _getDocumentLabel(doc.documentType),
                                      doc.fileUrl!,
                                    ),
                                  )
                                : const Icon(Icons.link_off, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Admin Actions
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Admin Actions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Flag for Suspension
              CheckboxListTile(
                title: const Text('Flag for Suspension'),
                subtitle: const Text('Mark this profile as suspicious'),
                value: _flagForSuspicion,
                onChanged: (value) => setState(() {
                  _flagForSuspicion = value ?? false;
                }),
              ),
              if (_flagForSuspicion)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter reason for suspension...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => _suspicionReason = value,
                  ),
                ),
              const SizedBox(height: 12),

              // Admin Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Enter admin notes/reason...',
                  border: OutlineInputBorder(),
                  labelText: 'Admin Notes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      onPressed: () => _approveKYC(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      onPressed: () => _rejectKYC(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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
  }

  Future<void> _approveKYC() async {
    try {
      final approvalNotifier =
          ref.read(kycAdminApprovalProvider(widget.tenantId).notifier);
      await approvalNotifier.approveKYC(
        adminNotes: _notesController.text,
        flaggedForSuspicion: _flagForSuspicion,
        suspicionReason: _suspicionReason,
      );

      ref.invalidate(kycDetailsProvider(widget.tenantId));
      ref.invalidate(kycStatusProvider(widget.tenantId));
      ref.invalidate(tenantDashboardProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectKYC() async {
    if (_notesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter rejection reason')),
      );
      return;
    }

    try {
      final rejectionNotifier =
          ref.read(kycAdminRejectionProvider(widget.tenantId).notifier);
      await rejectionNotifier.rejectKYC(
        rejectionReason: _notesController.text,
      );

      ref.invalidate(kycDetailsProvider(widget.tenantId));
      ref.invalidate(kycStatusProvider(widget.tenantId));
      ref.invalidate(tenantDashboardProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC rejected successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openDocumentPreview(BuildContext context, String title, String fileUrl) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 6, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    fileUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Unable to preview this file. URL:\n$fileUrl',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDocumentLabel(KYCDocumentType type) {
    switch (type) {
      case KYCDocumentType.aadhaarFront:
        return 'Aadhaar (Front)';
      case KYCDocumentType.aadhaarBack:
        return 'Aadhaar (Back)';
      case KYCDocumentType.pan:
        return 'PAN';
      case KYCDocumentType.selfie:
        return 'Selfie';
    }
  }
}
