import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:athidihub/core/services/backend_storage_service.dart';
import '../models/kyc_models.dart';
import '../providers/kyc_provider.dart';

class KYCDocumentUploadScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const KYCDocumentUploadScreen({
    required this.tenantId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<KYCDocumentUploadScreen> createState() =>
      _KYCDocumentUploadScreenState();
}

class _KYCDocumentUploadScreenState extends ConsumerState<KYCDocumentUploadScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final Map<KYCDocumentType, Uint8List?> _uploadedImages = {};
  final Map<KYCDocumentType, String?> _uploadErrors = {};
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: const Text(
                        'Please upload clear images of your documents for manual verification',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Required Documents
            const Text(
              'Required Documents',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDocumentUploadCard(
              KYCDocumentType.aadhaarFront,
              'Aadhaar Front',
              'Clear photo of Aadhaar front',
            ),
            const SizedBox(height: 12),
            _buildDocumentUploadCard(
              KYCDocumentType.aadhaarBack,
              'Aadhaar Back',
              'Clear photo of Aadhaar back',
            ),
            const SizedBox(height: 24),

            // Optional Documents
            const Text(
              'Optional Documents',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDocumentUploadCard(
              KYCDocumentType.pan,
              'PAN Card',
              'Photo of PAN card (optional)',
              isOptional: true,
            ),
            const SizedBox(height: 12),
            _buildDocumentUploadCard(
              KYCDocumentType.selfie,
              'Selfie',
              'Recent selfie for verification (optional)',
              isOptional: true,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploadedImages.isEmpty || _isUploading
                    ? null
                    : () => _submitDocuments(),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit for Verification'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isUploading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadCard(
    KYCDocumentType type,
    String title,
    String subtitle, {
    bool isOptional = false,
  }) {
    final hasImage = _uploadedImages[type] != null;
    final error = _uploadErrors[type];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (isOptional)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Optional',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasImage)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasImage)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _uploadedImages[type]!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(hasImage ? Icons.edit : Icons.photo_camera),
                label: Text(hasImage ? 'Change Photo' : 'Take Photo'),
                onPressed: () => _showImageSourcePicker(type),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(KYCDocumentType type, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxHeight: 1024,
        maxWidth: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _uploadedImages[type] = bytes;
          _uploadErrors.remove(type);
        });
      }
    } catch (e) {
      setState(() {
        _uploadErrors[type] = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _showImageSourcePicker(KYCDocumentType type) async {
    final picked = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(c, null),
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      await _pickImage(type, picked);
    }
  }

  Future<void> _submitDocuments() async {
    setState(() => _isUploading = true);

    try {
      final uploadNotifier =
          ref.read(kycDocumentUploadProvider(widget.tenantId).notifier);
      final storageService = ref.read(backendStorageServiceProvider);

      for (final entry in _uploadedImages.entries) {
        final type = entry.key;
        final imageBytes = entry.value;

        if (imageBytes != null) {
          final fileName = '${type.name}-${DateTime.now().millisecondsSinceEpoch}.jpg';
          final fileUrl = await storageService.uploadTenantDocument(
            tenantId: widget.tenantId,
            documentType: type.name,
            bytes: imageBytes,
            fileName: fileName,
          );

          await uploadNotifier.uploadDocument(
            documentType: type,
            fileData: fileUrl,
            fileName: fileName,
            mimeType: 'image/jpeg',
            fileSize: imageBytes.length,
          );
        }
      }

      // Ensure tenant documents/status screens show the latest server state.
      ref.invalidate(kycStatusProvider(widget.tenantId));
      ref.invalidate(kycDetailsProvider(widget.tenantId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }
}
