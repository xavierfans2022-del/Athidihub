# PG Management System - KYC Verification Module

## 🎯 Overview

A production-grade **Know Your Customer (KYC)** verification module for the PG Management System that provides:

- **Primary Flow**: DigiLocker-based Aadhaar verification with provider fallback (Setu, Signzy, HyperVerge)
- **Fallback Flow**: Manual document upload (Aadhaar, PAN) + Selfie verification for admin review
- **Compliance**: Encrypted storage, audit logging, masked Aadhaar (last 4 digits only)
- **Admin Tools**: Dashboard for reviewing pending verifications, approving/rejecting tenants
- **Notifications**: SMS/WhatsApp/Email updates for verification status changes
- **Production Ready**: Rate limiting, idempotent webhooks, comprehensive error handling

## 📁 Project Structure

```
athidihub-backend/
├── src/
│   ├── kyc/
│   │   ├── dto/
│   │   │   └── kyc.dto.ts              # Request/Response DTOs
│   │   ├── kyc.service.ts              # Business logic
│   │   ├── kyc.controller.ts           # API endpoints
│   │   └── kyc.module.ts               # Module definition
│   ├── common/crypto/
│   │   ├── crypto.service.ts           # Encryption/Decryption
│   │   └── crypto.module.ts
│   └── prisma/
│       └── schema.prisma               # Updated with KYC tables

athidihub/
├── lib/features/kyc/
│   ├── models/
│   │   └── kyc_models.dart             # Dart models & enums
│   ├── providers/
│   │   └── kyc_provider.dart           # Riverpod state management
│   ├── screens/
│   │   ├── kyc_initiation_screen.dart           # Main KYC flow
│   │   ├── kyc_document_upload_screen.dart      # Document upload
│   │   ├── kyc_verification_webview_screen.dart # Provider redirect
│   │   └── admin_kyc_review_screen.dart         # Admin review
│   └── services/
│       └── kyc_service.dart            # API client

Documentation/
├── KYC_IMPLEMENTATION_GUIDE.md          # Complete technical guide
├── KYC_SETUP_CHECKLIST.md               # Step-by-step setup
├── KYC_WEBHOOK_TESTING.md               # Webhook examples & testing
├── SUPABASE_EDGE_FUNCTIONS.md           # Serverless alternative
└── README.md                            # This file
```

## 🚀 Quick Start

### Backend Setup (5 minutes)

```bash
cd athidihub-backend

# 1. Update app.module.ts (add KYCModule to imports)
# See: KYC_SETUP_CHECKLIST.md → Step 1

# 2. Create .env file with credentials
cp .env.example .env
# Update with your provider credentials (see section below)

# 3. Run database migration
npx prisma migrate dev --name "add_kyc_verification_module"

# 4. Start backend
npm run start
```

### Frontend Setup (5 minutes)

```bash
cd athidihub

# 1. Update pubspec.yaml dependencies
# See: KYC_SETUP_CHECKLIST.md → Step 1

# 2. Get dependencies
flutter pub get

# 3. Generate models
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Update routing in app_router.dart
# See: KYC_SETUP_CHECKLIST.md → Step 3

# 5. Run app
flutter run
```

## ⚙️ Environment Configuration

### Required Environment Variables

```env
# ENCRYPTION (REQUIRED)
ENCRYPTION_KEY="use-32-character-key-from-vault"
ENCRYPTION_IV="use-16-byte-iv"

# DIGILOCKER (Primary Provider)
DIGILOCKER_CLIENT_ID="your-client-id"
DIGILOCKER_CLIENT_SECRET="your-secret"
DIGILOCKER_WEBHOOK_SECRET="your-webhook-secret"

# Optional: Alternative Providers
SETU_CLIENT_ID="..."
SIGNZY_CLIENT_ID="..."
HYPERVERGE_CLIENT_ID="..."

# App Configuration
APP_BASE_URL="http://localhost:3000"
API_BASE_URL="http://localhost:3000/api"
```

**Security**: Store secrets in environment vault (AWS Secrets Manager, HashiCorp Vault), never in code.

## 📊 Architecture

### Database Schema

```
Tenant (1) ──── (1) KYCVerification
                    ├── (1..n) KYCDocument
                    ├── (1..n) KYCAuditLog
                    └── (1..n) KYCWebhookLog
```

### Verification Flow

```
┌─────────────┐
│   Tenant    │
└──────┬──────┘
       │ 1. Click "Verify Aadhaar"
       ▼
┌─────────────────────┐
│ Backend: Create KYC │
└──────┬──────────────┘
       │ 2. Call Provider (DigiLocker/Setu/etc)
       ▼
┌──────────────────────────────┐
│ Provider: Consent Flow (OTP) │
└──────┬───────────────────────┘
       │ 3. User grants consent
       ▼
┌──────────────────────┐
│ Provider: Webhook    │
│ Backend: Validate    │
└──────┬───────────────┘
       │ 4. Store verified data (encrypted)
       ▼
┌──────────────────┐
│ Notify Tenant    │
│ Status: VERIFIED │
└──────────────────┘
```

### Fallback Flow (if verification fails)

```
┌─────────────────────────┐
│ Click "Upload Documents"│
└──────┬──────────────────┘
       │
       ▼
┌────────────────────────────────┐
│ Capture & Upload:              │
│ • Aadhaar (Front/Back)         │
│ • PAN (Optional)               │
│ • Selfie (Optional)            │
└──────┬─────────────────────────┘
       │
       ▼
┌──────────────────────┐
│ Status: MANUAL_REVIEW│
└──────┬───────────────┘
       │ Admin reviews
       ▼
┌──────────────────────┐
│ Admin Decision       │
│ Approve / Reject     │
└──────────────────────┘
```

## 🔑 Key Features

### 1️⃣ Aadhaar Verification

- **Instant**: Real-time verification via DigiLocker
- **Secure**: OTP-based consent flow
- **Compliant**: Encrypted storage, audit trails
- **Masked**: Only last 4 digits stored

### 2️⃣ Fallback Manual Upload

- **Document Types**: Aadhaar (front/back), PAN, Selfie
- **Admin Review**: Dashboard for verification
- **Decision**: Approve/Reject with reason
- **Retry**: Allow tenant to retry after rejection

### 3️⃣ Admin Dashboard

- **Pending Reviews**: List of pending KYCs
- **Document Inspection**: View uploaded documents
- **Quick Actions**: Approve/Reject with notes
- **Audit Trail**: Complete action history

### 4️⃣ Compliance & Security

- **Encryption**: AES-256-CBC for sensitive data
- **Audit Logs**: All actions recorded with actor/timestamp
- **Signature Validation**: HMAC-SHA256 for webhooks
- **Rate Limiting**: Per-tenant rate limits
- **Notifications**: Status updates via SMS/WhatsApp/Email

### 5️⃣ Error Handling

- **Retry Mechanism**: Exponential backoff (1h → 2h → 4h)
- **Max Retries**: 3 attempts before manual review
- **Failure Reasons**: Detailed error messages
- **Recovery**: Option to retry or upload fallback

## 📱 API Endpoints

### Tenant Endpoints

```
POST   /kyc/initiate              Initiate verification
GET    /kyc/status/:tenantId      Get current status
GET    /kyc/details/:tenantId     Get detailed info
POST   /kyc/upload-document       Upload document (fallback)
POST   /kyc/retry                 Retry verification
POST   /kyc/webhook/:provider     Webhook callback
```

### Admin Endpoints

```
GET    /kyc/admin/pending-reviews           List pending verifications
GET    /kyc/admin/details/:tenantId         Get KYC details for review
PATCH  /kyc/admin/approve/:tenantId         Approve KYC
PATCH  /kyc/admin/reject/:tenantId          Reject KYC
```

## 🧪 Testing

### Unit Tests

```bash
cd athidihub-backend

# Run KYC service tests
npm run test kyc.service.spec.ts

# Run with coverage
npm run test:cov kyc
```

### Integration Tests

```bash
# Test webhook endpoints
npm run test:e2e kyc.controller.e2e-spec.ts

# Test with mock provider
npm run test kyc kyc.mock-provider.spec.ts
```

### Manual Testing

```bash
# 1. Start backend
npm run start

# 2. Navigate to KYC screen in Flutter app
# context.pushNamed('kyc-initiation', queryParameters: {'tenantId': 'xxx'})

# 3. Test verification flow
# - Click "Verify with Aadhaar"
# - Complete provider flow
# - Check status updates

# 4. Test fallback
# - Click "Upload Documents"
# - Take photos
# - Submit

# 5. Test admin review
# - Go to admin dashboard
# - Review pending KYCs
# - Approve/Reject
```

## 📊 Database Queries

### Check Verification Status

```sql
SELECT id, tenant_id, status, created_at 
FROM "KYCVerification" 
WHERE status != 'VERIFIED'
ORDER BY created_at DESC;
```

### View Audit Trail

```sql
SELECT a.action, a.actor_role, a.details, a.created_at
FROM "KYCAuditLog" a
WHERE a."kycVerificationId" = 'kyc-id-here'
ORDER BY a.created_at DESC;
```

### Monitor Webhook Processing

```sql
SELECT provider, webhook_event, signature_valid, processed_at, error_message
FROM "KYCWebhookLog"
ORDER BY created_at DESC
LIMIT 20;
```

## 🔍 Monitoring & Logs

### Enable Debug Logging

```env
LOG_LEVEL=debug
DEBUG=kyc:*
```

### Monitor Real-time Logs

```bash
# Backend logs
tail -f logs/kyc-*.log

# Filter by event
grep "VERIFICATION_COMPLETED" logs/kyc-*.log

# Search for errors
grep "ERROR" logs/kyc-*.log
```

### Key Metrics

- Verification success rate: (Verified) / (Initiated)
- Average verification time: Initiation → Verified
- Failure reasons breakdown
- Webhook success rate
- Admin review time

## 🐛 Troubleshooting

### Verification not starting

```
❌ Error: "KYC record not found"
✅ Solution: Ensure tenant is assigned to a bed first
```

### Webhook not received

```
❌ Error: "Webhook signature invalid"
✅ Solution: Verify webhook secret in .env matches provider settings
```

### Documents not uploading

```
❌ Error: "Failed to upload document"
✅ Solution: Check S3 bucket permissions and encryption key
```

### Admin panel showing no reviews

```
❌ Error: "No pending reviews"
✅ Solution: Manually upload documents to move KYC to MANUAL_REVIEW status
```

See [KYC_IMPLEMENTATION_GUIDE.md](./KYC_IMPLEMENTATION_GUIDE.md) → Troubleshooting section for more details.

## 📚 Documentation

1. **[KYC_IMPLEMENTATION_GUIDE.md](./KYC_IMPLEMENTATION_GUIDE.md)** - Complete technical documentation
2. **[KYC_SETUP_CHECKLIST.md](./KYC_SETUP_CHECKLIST.md)** - Step-by-step integration guide
3. **[KYC_WEBHOOK_TESTING.md](./KYC_WEBHOOK_TESTING.md)** - Webhook examples and testing
4. **[SUPABASE_EDGE_FUNCTIONS.md](./SUPABASE_EDGE_FUNCTIONS.md)** - Serverless alternative setup

## 🚀 Deployment

### Production Checklist

- [ ] Encryption keys in vault (not in code)
- [ ] All environment variables configured
- [ ] Database migrations applied
- [ ] Webhook signatures validated
- [ ] Rate limiting enabled
- [ ] Audit logging working
- [ ] Notifications configured
- [ ] Error handling tested
- [ ] Performance tested under load
- [ ] Backup/recovery plan ready

### Deploy Backend

```bash
cd athidihub-backend

# Build
npm run build

# Apply migrations
npx prisma migrate deploy

# Start
npm start
# or with PM2
pm2 start dist/main.js --name kyc
```

### Deploy Frontend

```bash
cd athidihub

# iOS
flutter build ios --release

# Android
flutter build apk --release

# Web
flutter build web --release
```

## 🔐 Security Best Practices

1. **Never store full Aadhaar**: Use masked format (****1234)
2. **Always encrypt sensitive data**: Full name, DOB, address
3. **Validate webhook signatures**: HMAC-SHA256 on every callback
4. **Use HTTPS**: Enforce on all endpoints
5. **Rate limit**: Prevent abuse
6. **Audit log everything**: For compliance
7. **Rotate keys**: Encryption and webhook secrets
8. **Secure storage**: Use encrypted cloud storage for documents

## 📞 Support

For issues or questions:

1. Check logs: `tail -f logs/kyc-*.log`
2. Review audit trail: `KYCAuditLog` table
3. Check webhook logs: `KYCWebhookLog` table
4. Enable debug mode: `DEBUG=kyc:*`
5. Contact admin team with error details

## 📝 License

This module is part of the PG Management System and is proprietary.

## ✅ Checklist for Go-Live

- [ ] All tests passing
- [ ] Load testing completed
- [ ] Security audit done
- [ ] Documentation reviewed
- [ ] Team trained on KYC module
- [ ] Provider credentials verified
- [ ] Notification service ready
- [ ] Monitoring/alerting configured
- [ ] Backup and recovery tested
- [ ] Rollback plan documented

---

**Last Updated**: May 12, 2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
