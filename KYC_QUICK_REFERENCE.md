# KYC Module - Quick Reference Card

## 🔗 File Locations

### Backend Files
| What | Path | Lines |
|------|------|-------|
| Service | `src/kyc/kyc.service.ts` | 680 |
| Controller | `src/kyc/kyc.controller.ts` | 280 |
| DTOs | `src/kyc/dto/kyc.dto.ts` | 400 |
| Module | `src/kyc/kyc.module.ts` | 15 |
| Crypto Service | `src/common/crypto/crypto.service.ts` | 60 |
| Database | `prisma/schema.prisma` | +180 |

### Frontend Files
| What | Path | Lines |
|------|------|-------|
| Models | `lib/features/kyc/models/kyc_models.dart` | 200 |
| Service | `lib/features/kyc/services/kyc_service.dart` | 150 |
| Providers | `lib/features/kyc/providers/kyc_provider.dart` | 450 |
| Main Screen | `lib/features/kyc/screens/kyc_initiation_screen.dart` | 350 |
| Upload Screen | `lib/features/kyc/screens/kyc_document_upload_screen.dart` | 280 |
| WebView Screen | `lib/features/kyc/screens/kyc_verification_webview_screen.dart` | 250 |
| Admin Screen | `lib/features/kyc/screens/admin_kyc_review_screen.dart` | 450 |

---

## 📋 API Endpoints Reference

### Tenant Endpoints
```
POST   /kyc/initiate
├─ Request: { tenantId, preferredProvider }
├─ Response: { verificationId, verificationUrl, expiresAt }
└─ Errors: Tenant not found, Already in progress

GET    /kyc/status/:tenantId
├─ Response: { status, provider, lastUpdated, documents }
└─ Errors: Tenant not found

GET    /kyc/details/:tenantId
├─ Response: { status, provider, documents, auditLog, nextRetryAt }
└─ Errors: Tenant not found

POST   /kyc/upload-document
├─ Request: { tenantId, documentType, fileBase64, fileName }
├─ Response: { documentId, verified, verificationScore }
└─ Errors: Max documents reached, Invalid document type

POST   /kyc/retry
├─ Request: { tenantId }
├─ Response: { verificationId, verificationUrl }
└─ Errors: Cannot retry (wrong status), Max retries exceeded
```

### Admin Endpoints
```
GET    /kyc/admin/pending-reviews?page=1&limit=10
├─ Response: [ { tenantId, name, status, uploadedAt, flags } ]
└─ Requires: ADMIN role

GET    /kyc/admin/details/:tenantId
├─ Response: { full KYC details, documents, auditLog }
└─ Requires: ADMIN role

PATCH  /kyc/admin/approve/:tenantId
├─ Request: { adminNotes, suspicionFlag }
├─ Response: { approved, timestamp }
└─ Requires: ADMIN role

PATCH  /kyc/admin/reject/:tenantId
├─ Request: { rejectionReason, adminNotes }
├─ Response: { rejected, timestamp }
└─ Requires: ADMIN role
```

### Webhook Endpoint
```
POST   /kyc/webhook/:provider
├─ Providers: digilocker, setu, signzy, hyperverge
├─ Validation: HMAC-SHA256 signature, 5-min timestamp
└─ Response: { success, message }
```

---

## 🗄️ Database Enums

### KYCVerificationStatus
```
PENDING, IN_PROGRESS, VERIFIED, REJECTED, MANUAL_REVIEW, EXPIRED, RETRY
```

### KYCVerificationProvider
```
DIGILOCKER, SETU, SIGNZY, HYPERVERGE, MANUAL
```

### KYCDocumentType
```
AADHAAR_FRONT, AADHAAR_BACK, PAN, SELFIE
```

### AuditActionType
```
VERIFICATION_INITIATED, INITIATED, COMPLETED, FAILED, 
APPROVED, REJECTED, FLAGGED_FOR_SUSPENSION, RETRIED
```

---

## ⚙️ Environment Variables

```bash
# REQUIRED
ENCRYPTION_KEY="32-character-key"
ENCRYPTION_IV="16-byte-iv"

# Provider Credentials
DIGILOCKER_CLIENT_ID="xxx"
DIGILOCKER_CLIENT_SECRET="xxx"
DIGILOCKER_WEBHOOK_SECRET="xxx"

# Optional
SETU_CLIENT_ID="xxx"
SIGNZY_CLIENT_ID="xxx"
HYPERVERGE_CLIENT_ID="xxx"

# App
APP_BASE_URL="http://localhost:3000"
API_BASE_URL="http://localhost:3000/api"
```

---

## 🔍 Key Database Queries

### Check pending KYCs
```sql
SELECT tenantId, status, createdAt FROM "KYCVerification" 
WHERE status IN ('PENDING', 'IN_PROGRESS', 'MANUAL_REVIEW')
ORDER BY createdAt DESC;
```

### View audit trail
```sql
SELECT action, actorRole, details, createdAt FROM "KYCAuditLog"
WHERE "kycVerificationId" = 'kyc-id'
ORDER BY createdAt DESC;
```

### Monitor webhooks
```sql
SELECT provider, signatureValid, processedAt, errorMessage 
FROM "KYCWebhookLog"
ORDER BY createdAt DESC LIMIT 50;
```

### Find failed verifications
```sql
SELECT tenantId, failureReason, failureCount, nextRetryAt 
FROM "KYCVerification"
WHERE status = 'FAILED'
ORDER BY failureCount DESC;
```

---

## 🎯 Verification Flow State Machine

```
PENDING
  ↓
  ├→ Initiate Provider → IN_PROGRESS
  │                      ↓
  │              Provider Callback
  │                      ↓
  │          ┌─→ VERIFIED ✓
  │          │
  │  Success │
  │          └─→ MANUAL_REVIEW (for fallback)
  │
  └→ Failure → FAILED
              ↓
              ├→ Retry limit? → MANUAL_REVIEW
              ├→ Backoff wait? → RETRY
              └→ Expired? → EXPIRED
```

---

## 📞 Flutter Integration Steps

1. **Add to pubspec.yaml**
   ```yaml
   dependencies:
     webview_flutter: ^4.0.0
     image_picker: ^0.8.0
     json_annotation: ^4.8.0
   
   dev_dependencies:
     build_runner: ^2.4.0
     json_serializable: ^6.7.0
   ```

2. **Generate models**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Add routes in app_router.dart**
   ```dart
   GoRoute(
     path: '/kyc/initiation',
     name: 'kyc-initiation',
     builder: (context, state) => KYCInitiationScreen(),
   ),
   GoRoute(
     path: '/kyc/verify/:tenantId',
     name: 'kyc-verify',
     builder: (context, state) => KYCVerificationWebviewScreen(),
   ),
   // ... other routes
   ```

4. **Navigate to KYC**
   ```dart
   context.pushNamed('kyc-initiation');
   ```

---

## 🔧 NestJS Integration Steps

1. **Update app.module.ts**
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

2. **Run migration**
   ```bash
   npx prisma migrate dev --name "add_kyc_verification_module"
   ```

3. **Configure .env**
   ```
   ENCRYPTION_KEY=your-32-char-key
   ENCRYPTION_IV=your-16-byte-iv
   DIGILOCKER_CLIENT_ID=xxx
   DIGILOCKER_WEBHOOK_SECRET=xxx
   ```

4. **Test endpoint**
   ```bash
   curl http://localhost:3000/kyc/health
   ```

---

## 📊 Webhook Signature Generation

### DigiLocker (Node.js)
```typescript
const crypto = require('crypto');

function generateSignature(payload, timestamp, secret) {
  const message = `${JSON.stringify(payload)}.${timestamp}`;
  return crypto
    .createHmac('sha256', secret)
    .update(message)
    .digest('hex');
}

// Usage
const signature = generateSignature(body, Date.now(), SECRET);
```

### Verification (Express middleware)
```typescript
app.post('/kyc/webhook/:provider', (req, res) => {
  const { signature, timestamp } = req.query;
  const body = req.body;
  
  const expected = generateSignature(body, timestamp, SECRET);
  
  if (signature !== expected) {
    return res.status(400).json({ error: 'Invalid signature' });
  }
  
  // Process webhook
});
```

---

## 🔐 Security Checklist

- [ ] Encryption key in vault (not .env.local)
- [ ] Webhook signature validation on every callback
- [ ] HTTPS enforced on all endpoints
- [ ] Rate limiting configured (3 initiations per hour per tenant)
- [ ] Audit logging enabled
- [ ] Full Aadhaar never logged
- [ ] CORS configured correctly
- [ ] Input validation on all endpoints
- [ ] Error messages don't leak sensitive data

---

## 🧪 Testing Commands

```bash
# Backend unit tests
npm run test src/kyc

# Backend integration tests
npm run test:e2e kyc

# Frontend widget tests
flutter test test/features/kyc/

# Webhook test (cURL)
curl -X POST http://localhost:3000/kyc/webhook/digilocker \
  -H "Content-Type: application/json" \
  -d '{"state":"session-id","status":"success"}' \
  -G -d "signature=xxx" -d "timestamp=$(date +%s)000"
```

---

## 📈 Monitoring Metrics

```sql
-- Success rate
SELECT 
  COUNT(*) FILTER (WHERE status = 'VERIFIED') as verified,
  COUNT(*) as total,
  ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'VERIFIED') / COUNT(*), 2) as success_rate
FROM "KYCVerification";

-- Average time to verification
SELECT 
  AVG(EXTRACT(EPOCH FROM ("updatedAt" - "createdAt"))) as avg_seconds
FROM "KYCVerification"
WHERE status = 'VERIFIED';

-- Failure breakdown
SELECT status, COUNT(*) FROM "KYCVerification"
GROUP BY status;
```

---

## 🚨 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| `KYC record not found` | Ensure tenant assigned to bed first |
| `Webhook signature invalid` | Verify secret matches in .env |
| `CORS error on WebView` | Add provider domain to CORS whitelist |
| `Documents not uploading` | Check S3 credentials and encryption key |
| `Status not updating` | Check webhook logs for errors |
| `Retry button disabled` | Verify failure count < 3 and > 1 hour elapsed |

---

## 📚 Documentation Map

| Need | File |
|------|------|
| Quick start | [KYC_README.md](./KYC_README.md) |
| Architecture | [KYC_IMPLEMENTATION_GUIDE.md](./KYC_IMPLEMENTATION_GUIDE.md) |
| Integration | [KYC_SETUP_CHECKLIST.md](./KYC_SETUP_CHECKLIST.md) |
| Webhooks | [KYC_WEBHOOK_TESTING.md](./KYC_WEBHOOK_TESTING.md) |
| Serverless | [SUPABASE_EDGE_FUNCTIONS.md](./SUPABASE_EDGE_FUNCTIONS.md) |
| Overview | [KYC_IMPLEMENTATION_SUMMARY.md](./KYC_IMPLEMENTATION_SUMMARY.md) |

---

## ⏱️ Implementation Timeline

- **30 min**: Read documentation + plan
- **1-2 hours**: Backend integration
- **1-2 hours**: Frontend integration
- **1 hour**: Testing & debugging
- **1 hour**: Deployment setup
- **Total**: ~5-6 hours for full integration

---

**Last Updated**: May 12, 2026 | **Version**: 1.0.0 | **Status**: Production Ready
