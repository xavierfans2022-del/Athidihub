# KYC Verification Module - Implementation Guide

## Overview

This document describes the production-grade KYC (Know Your Customer) verification module implemented for the PG Management System. The module provides comprehensive Aadhaar-based identity verification with fallback manual document upload support, admin review capabilities, and full audit logging.

## Architecture

### Backend (NestJS)

#### Database Schema (Prisma)

The KYC module uses the following core tables:

1. **KYCVerification** - Main verification record
   - Stores verification status, provider, verified identity data (encrypted)
   - Tracks verification lifecycle, retries, and admin review
   - Relationships: One-to-One with Tenant, One-to-Many with Documents & AuditLogs

2. **KYCDocument** - Document records for fallback upload
   - Stores document type, file URL, verification score
   - Supports Aadhaar (front/back), PAN, Selfie documents

3. **KYCAuditLog** - Audit trail for compliance
   - Tracks all actions: initiation, completion, approval, rejection
   - Records actor, timestamp, and action details

4. **KYCWebhookLog** - Webhook tracking
   - Logs all webhook calls from verification providers
   - Validates signatures and tracks processing status

### Services & Providers

#### Verification Providers

The module supports multiple verification providers with a pluggable architecture:

1. **DigiLocker** - Official DigiLocker API (Primary)
2. **Setu** - Aggregator platform
3. **Signzy** - Third-party KYC provider
4. **HyperVerge** - Additional provider option

Each provider implements the `VerificationProvider` interface with methods:
- `initiateVerification()` - Start verification flow
- `validateWebhook()` - Validate webhook signature
- `parseWebhookPayload()` - Parse provider-specific response

#### Encryption Service

All sensitive data (full name, email, phone, address) is encrypted using AES-256-CBC:

```dart
- Encryption key loaded from `ENCRYPTION_KEY` environment variable
- IV generated from `ENCRYPTION_IV` environment variable
- Only masked Aadhaar (last 4 digits) stored unencrypted for reference
```

### API Endpoints

#### Tenant Endpoints

```
POST   /kyc/initiate                 - Start KYC verification
GET    /kyc/status/:tenantId         - Get verification status
GET    /kyc/details/:tenantId        - Get detailed KYC info
POST   /kyc/upload-document          - Upload fallback document
POST   /kyc/retry                    - Retry failed verification
POST   /kyc/webhook/:provider        - Webhook callback
```

#### Admin Endpoints

```
GET    /kyc/admin/pending-reviews    - List pending reviews (paginated)
GET    /kyc/admin/details/:tenantId  - Get KYC details for review
PATCH  /kyc/admin/approve/:tenantId  - Approve verification
PATCH  /kyc/admin/reject/:tenantId   - Reject verification
```

### Flutter Frontend

#### Directory Structure

```
lib/features/kyc/
├── models/
│   └── kyc_models.dart             - Data models, enums
├── providers/
│   └── kyc_provider.dart           - Riverpod state management
├── screens/
│   ├── kyc_initiation_screen.dart           - Main KYC screen
│   ├── kyc_document_upload_screen.dart      - Fallback upload
│   ├── kyc_verification_webview_screen.dart - Provider redirect
│   └── admin_kyc_review_screen.dart         - Admin review panel
├── services/
│   └── kyc_service.dart            - API client
```

#### State Management (Riverpod)

- `kycStatusProvider` - Current KYC status
- `kycDetailsProvider` - Detailed KYC information
- `kycDocumentUploadProvider` - Document upload state
- `kycRetryProvider` - Retry verification state
- `kycFlowStateProvider` - Combined flow state
- `kycAdminPendingReviewsProvider` - Admin pending list
- `kycAdminApprovalProvider` - Admin approval state
- `kycAdminRejectionProvider` - Admin rejection state

## Workflow

### Primary Flow: Aadhaar Verification

1. **Tenant Initiates Verification**
   - Tenant navigates to KYC screen and clicks "Verify with Aadhaar"
   - Backend creates `KYCVerification` record with status `PENDING`
   - Backend calls verification provider (DigiLocker/Setu/etc)
   - Provider returns verification URL and session ID
   - Frontend redirects to provider via WebView or external browser

2. **Consent & Verification**
   - Tenant grants consent at provider platform
   - Provider performs OTP verification
   - Provider redirects to callback URL

3. **Webhook Callback Processing**
   - Provider sends webhook to `POST /kyc/webhook/:provider`
   - Backend validates webhook signature
   - Extracts verified data (name, DOB, address, Aadhaar)
   - Encrypts sensitive fields before storage
   - Updates KYC status to `VERIFIED` or `FAILED`
   - Triggers notifications (SMS/WhatsApp/Email)

### Fallback Flow: Manual Document Upload

1. **User Selects Fallback**
   - Tenant clicks "Upload Documents" button
   - Navigate to document upload screen

2. **Document Capture**
   - Capture Aadhaar front/back using camera
   - Optional: PAN card, Selfie
   - Convert to base64 and upload

3. **Admin Review**
   - Documents move to `MANUAL_REVIEW` status
   - Admin reviews documents via dashboard
   - Admin approves/rejects with reason
   - Tenant notified of outcome

### Retry Mechanism

- Failed verifications can be retried after exponential backoff
- 1st failure: Retry after 1 hour
- 2nd failure: Retry after 2 hours
- 3rd failure: Moves to `MANUAL_REVIEW` (no more automatic retries)
- Admin can override and allow retry

## Compliance & Security

### Data Protection

- **Encryption**: All sensitive PII encrypted at rest (AES-256-CBC)
- **Masking**: Aadhaar stored as masked (****1234 format)
- **Secure Storage**: Document files stored on encrypted cloud storage
- **Access Control**: Role-based access (ADMIN, OWNER, MANAGER)

### Audit Logging

All actions logged with:
- Actor (User ID, Role)
- Action type (Initiate, Approve, Reject, etc)
- Timestamp
- IP address & User agent
- Relevant details
- Structured audit trail for compliance

### Rate Limiting

- Per-tenant KYC initiation: 5 per hour
- Retry attempts: Limited with exponential backoff
- Webhook processing: Idempotent handling

### Webhook Security

- HMAC-SHA256 signature validation
- Timestamp-based replay attack prevention (5-minute tolerance)
- Provider-specific secrets from environment variables

## Integration Points

### Environment Variables

```env
# Encryption
ENCRYPTION_KEY=your-256-bit-key
ENCRYPTION_IV=your-16-byte-iv

# DigiLocker
DIGILOCKER_CLIENT_ID=your-client-id
DIGILOCKER_WEBHOOK_SECRET=your-webhook-secret

# Setu
SETU_CLIENT_ID=your-client-id
SETU_WEBHOOK_SECRET=your-webhook-secret

# Signzy
SIGNZY_CLIENT_ID=your-client-id
SIGNZY_WEBHOOK_SECRET=your-webhook-secret

# HyperVerge
HYPERVERGE_CLIENT_ID=your-client-id
HYPERVERGE_WEBHOOK_SECRET=your-webhook-secret

# App
APP_BASE_URL=http://localhost:3000
```

### Database Migration

Run Prisma migration to create KYC tables:

```bash
cd athidihub-backend
npx prisma migrate dev --name add_kyc_verification_module
```

### Backend Module Integration

Add KYC module to `app.module.ts`:

```typescript
import { KYCModule } from './kyc/kyc.module';

@Module({
  imports: [
    // ... existing modules
    KYCModule,
  ],
})
export class AppModule {}
```

### Flutter Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Existing packages
  webview_flutter: ^4.0.0
  image_picker: ^1.0.0
  go_router: ^13.0.0
  riverpod: ^2.5.0
  json_annotation: ^4.8.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
```

Generate JSON models:

```bash
cd athidihub
flutter pub run build_runner build --delete-conflicting-outputs
```

### Router Configuration

Add routes to `app_router.dart`:

```dart
GoRoute(
  path: '/kyc/initiation/:tenantId',
  name: 'kyc-initiation',
  builder: (context, state) {
    final tenantId = state.pathParameters['tenantId']!;
    return KYCInitiationScreen(tenantId: tenantId);
  },
),
GoRoute(
  path: '/kyc/verification/:tenantId',
  name: 'kyc-verification',
  builder: (context, state) {
    final tenantId = state.pathParameters['tenantId']!;
    return KYCVerificationWebViewScreen(tenantId: tenantId);
  },
),
GoRoute(
  path: '/kyc/document-upload/:tenantId',
  name: 'kyc-document-upload',
  builder: (context, state) {
    final tenantId = state.pathParameters['tenantId']!;
    return KYCDocumentUploadScreen(tenantId: tenantId);
  },
),
GoRoute(
  path: '/admin/kyc-review',
  name: 'admin-kyc-review',
  builder: (context, state) => const AdminKYCReviewScreen(),
),
```

## Notifications

The module integrates with the notification service to send:

1. **Verification Initiated**
   - Tenant notified via SMS/WhatsApp

2. **Verification Approved**
   - Can proceed with check-in

3. **Verification Failed**
   - Retry instructions sent

4. **Admin Review Completed**
   - Approved or rejected

5. **Suspicious Profile Flagged**
   - Admin notified

## Testing

### Unit Tests (Backend)

```bash
cd athidihub-backend
npm run test kyc.service.spec.ts
npm run test kyc.controller.spec.ts
```

### Integration Tests

- Verify provider webhooks: Mock webhook calls with signatures
- Document upload: Test base64 encoding and file handling
- Audit logs: Verify all actions logged correctly

### Manual Testing (Flutter)

1. Navigate to KYC screen
2. Click "Verify with Aadhaar"
3. Complete verification flow in WebView
4. Verify callback is processed and status updated
5. Test fallback: Upload documents manually
6. Test admin review: Approve/reject from admin panel

## Monitoring & Logging

### Key Metrics to Monitor

1. **Verification Success Rate**: (Verified count) / (Initiated count)
2. **Average Completion Time**: Time from initiation to verification
3. **Failure Reasons**: Breakdown of rejection causes
4. **Webhook Success Rate**: Successful callbacks / Total callbacks
5. **Admin Review Time**: Average time to admin action

### Logging

Enable structured logging:

```typescript
this.logger.log(`KYC verification initiated: ${kycVerificationId}`);
this.logger.debug(`Webhook received from ${provider}`);
this.logger.error(`Verification failed: ${reason}`);
```

## Troubleshooting

### Common Issues

1. **Verification URL not loading**
   - Check internet connectivity
   - Verify provider credentials in env vars
   - Check callback URL is accessible

2. **Webhook not received**
   - Verify webhook secret matches provider
   - Check firewall/WAF rules
   - Verify endpoint is public

3. **Documents not uploading**
   - Check file size limits
   - Verify storage bucket permissions
   - Check encryption key is valid

4. **Admin panel not showing pending reviews**
   - Verify admin role assignments
   - Check database has MANUAL_REVIEW records
   - Verify pagination parameters

## Future Enhancements

1. **Background Jobs**: Move webhook processing to Bull queues
2. **ML-Based Verification**: Implement document validation using ML
3. **Provider Failover**: Auto-switch providers on failure
4. **Batch Processing**: Process multiple verifications in batches
5. **Advanced Analytics**: Dashboard with verification metrics
6. **International Support**: Support non-Indian identity documents
7. **Biometric Verification**: Add face recognition via HyperVerge

## Support & Contact

For issues or questions:
- Check logs: `logs/kyc-*.log`
- Review audit trail: `KYCAuditLog` table
- Contact admin team
- Enable debug mode: `DEBUG=kyc:*`

---

**Last Updated**: May 12, 2026
**Version**: 1.0.0
**Status**: Production Ready
