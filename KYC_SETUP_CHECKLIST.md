# KYC Module - Integration Checklist & Configuration

## Pre-Integration Checklist

### 1. Backend Setup

#### Step 1: Update `app.module.ts`

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { KYCModule } from './kyc/kyc.module'; // ← Add this
// ... other imports

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    KYCModule, // ← Add this
    // ... other modules
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
```

#### Step 2: Create `.env` configuration

```env
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/athidihub"

# Encryption
ENCRYPTION_KEY="your-32-character-secret-key-here!"
ENCRYPTION_IV="your-16-character-iv!"

# API Configuration
API_BASE_URL="http://localhost:3000/api"
APP_BASE_URL="http://localhost:3000"

# DigiLocker Configuration
DIGILOCKER_CLIENT_ID="your-digilocker-client-id"
DIGILOCKER_CLIENT_SECRET="your-digilocker-client-secret"
DIGILOCKER_WEBHOOK_SECRET="your-digilocker-webhook-secret"
DIGILOCKER_REDIRECT_URI="http://localhost:3000/api/kyc/webhook/digilocker/callback"

# Setu Configuration (Alternative Provider)
SETU_CLIENT_ID="your-setu-client-id"
SETU_CLIENT_SECRET="your-setu-client-secret"
SETU_WEBHOOK_SECRET="your-setu-webhook-secret"

# Signzy Configuration
SIGNZY_CLIENT_ID="your-signzy-client-id"
SIGNZY_API_KEY="your-signzy-api-key"
SIGNZY_WEBHOOK_SECRET="your-signzy-webhook-secret"

# HyperVerge Configuration
HYPERVERGE_CLIENT_ID="your-hyperverge-client-id"
HYPERVERGE_API_KEY="your-hyperverge-api-key"
HYPERVERGE_WEBHOOK_SECRET="your-hyperverge-webhook-secret"

# AWS S3 (for document storage)
AWS_REGION="ap-south-1"
AWS_ACCESS_KEY_ID="your-aws-key"
AWS_SECRET_ACCESS_KEY="your-aws-secret"
AWS_S3_BUCKET="kyc-documents-bucket"
AWS_S3_ENCRYPTION="true"

# JWT
JWT_SECRET="your-jwt-secret"
JWT_EXPIRATION="24h"

# Redis (for caching and rate limiting)
REDIS_URL="redis://localhost:6379"

# Logging
LOG_LEVEL="debug"
LOG_FORMAT="json"

# Feature Flags
ENABLE_KYC_VERIFICATION="true"
REQUIRE_KYC_FOR_CHECKIN="true"
KYC_VERIFICATION_TIMEOUT="30m"
```

#### Step 3: Run Prisma Migration

```bash
cd athidihub-backend

# Generate Prisma Client
npx prisma generate

# Create migration
npx prisma migrate dev --name "add_kyc_verification_module"

# Verify schema
npx prisma db push
npx prisma studio
```

#### Step 4: Verify Backend Compilation

```bash
npm run build
npm run lint
npm run test
```

### 2. Flutter Setup

#### Step 1: Update `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Networking
  dio: ^5.3.0
  http: ^1.1.0
  
  # State Management
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  
  # Routing
  go_router: ^13.0.0
  
  # File & Image
  image_picker: ^1.0.0
  file_picker: ^6.0.0
  
  # WebView
  webview_flutter: ^4.4.0
  
  # Serialization
  json_annotation: ^4.8.0
  
  # Storage
  shared_preferences: ^2.2.0
  
  # Utils
  intl: ^0.19.0
  uuid: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
```

#### Step 2: Generate Dart Models

```bash
cd athidihub

# Install dependencies
flutter pub get

# Generate JSON serialization code
flutter pub run build_runner build --delete-conflicting-outputs

# For watch mode during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

#### Step 3: Add Routes to `go_router`

Update `lib/core/router/app_router.dart`:

```dart
import 'package:go_router/go_router.dart';
import '../features/kyc/screens/kyc_initiation_screen.dart';
import '../features/kyc/screens/kyc_document_upload_screen.dart';
import '../features/kyc/screens/kyc_verification_webview_screen.dart';
import '../features/kyc/screens/admin_kyc_review_screen.dart';

final appRouter = GoRouter(
  routes: [
    // ... existing routes
    
    GoRoute(
      path: '/kyc/initiation/:tenantId',
      name: 'kyc-initiation',
      pageBuilder: (context, state) {
        final tenantId = state.pathParameters['tenantId']!;
        return MaterialPage(
          child: KYCInitiationScreen(tenantId: tenantId),
        );
      },
    ),
    GoRoute(
      path: '/kyc/verification/:tenantId',
      name: 'kyc-verification',
      pageBuilder: (context, state) {
        final tenantId = state.pathParameters['tenantId']!;
        return MaterialPage(
          child: KYCVerificationWebViewScreen(tenantId: tenantId),
        );
      },
    ),
    GoRoute(
      path: '/kyc/document-upload/:tenantId',
      name: 'kyc-document-upload',
      pageBuilder: (context, state) {
        final tenantId = state.pathParameters['tenantId']!;
        return MaterialPage(
          child: KYCDocumentUploadScreen(tenantId: tenantId),
        );
      },
    ),
    GoRoute(
      path: '/admin/kyc-review',
      name: 'admin-kyc-review',
      pageBuilder: (context, state) => const MaterialPage(
        child: AdminKYCReviewScreen(),
      ),
    ),
  ],
);
```

#### Step 4: Update `dio_provider.dart`

Ensure KYC endpoints are included in the API client:

```dart
final dioProvider = Provider((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ),
  );

  // Add interceptors for token, error handling, etc.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle errors
        return handler.next(error);
      },
    ),
  );

  return dio;
});
```

#### Step 5: Test Flutter Build

```bash
# Clean
flutter clean

# Get dependencies
flutter pub get

# Analyze
flutter analyze

# Build
flutter build apk --debug
# or
flutter build ios --debug
```

## Database Schema Verification

### Verify KYC Tables Created

```sql
-- Check KYC tables
\dt *kyc*

-- Check KYC enums
SELECT * FROM pg_type WHERE typname LIKE '%kyc%' OR typname LIKE '%audit%';

-- Sample query: List all pending verifications
SELECT 
  k.id,
  t.name,
  t.email,
  k.status,
  k.created_at
FROM "KYCVerification" k
JOIN "Tenant" t ON k."tenantId" = t.id
WHERE k.status = 'PENDING'
ORDER BY k.created_at DESC;
```

## Testing Configuration

### Backend KYC Tests

```bash
cd athidihub-backend

# Run all KYC tests
npm run test kyc

# Run with coverage
npm run test:cov kyc

# E2E tests
npm run test:e2e kyc
```

### Flutter KYC Tests

```bash
cd athidihub

# Run unit tests
flutter test test/features/kyc/

# Run with coverage
flutter test --coverage test/features/kyc/

# E2E tests
flutter drive --target=test_driver/app.dart
```

## Provider Integration

### DigiLocker Setup

1. Go to https://digilocker.gov.in/developer
2. Register application
3. Get Client ID and Secret
4. Add to `.env`
5. Configure callback URL: `http://your-domain/api/kyc/webhook/digilocker`

### Setu Setup

1. Go to https://setu.co/
2. Create account and project
3. Enable Aadhaar verification
4. Get API credentials
5. Add to `.env`
6. Test with Setu's sandbox environment first

### Signzy Setup

1. Go to https://signzy.com/
2. Request enterprise account
3. Get API key and secret
4. Add to `.env`
5. Test with test credentials

### HyperVerge Setup

1. Go to https://hyperverge.co/
2. Create account
3. Get API credentials
4. Add to `.env`
5. Configure webhook endpoint

## Security Checklist

- [ ] Encryption keys stored in secure vault (not in code)
- [ ] Webhook signatures validated on every callback
- [ ] HTTPS enforced on all endpoints
- [ ] CORS configured correctly
- [ ] Rate limiting implemented
- [ ] Sensitive data fields encrypted
- [ ] Audit logs stored securely
- [ ] Access control enforced (RBAC)
- [ ] Files uploaded to encrypted storage
- [ ] Tokens have proper expiration
- [ ] SQL injection prevented (Prisma ORM handles this)
- [ ] CSRF protection enabled
- [ ] No sensitive data in logs

## Deployment Checklist

### Backend Deployment

```bash
# Build
npm run build

# Run migrations
npx prisma migrate deploy

# Start
npm start

# Or with PM2
pm2 start dist/main.js --name athidihub-kyc
```

### Frontend Deployment

```bash
# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Build Web
flutter build web --release
```

### Post-Deployment Verification

1. [ ] Health check: `GET /api/kyc/health`
2. [ ] List pending reviews: `GET /api/kyc/admin/pending-reviews`
3. [ ] Test webhook endpoint accessibility
4. [ ] Verify encryption/decryption working
5. [ ] Check audit logs are being created
6. [ ] Verify notifications are sent
7. [ ] Monitor webhook callbacks
8. [ ] Test admin approval/rejection

## Rollback Plan

If issues occur:

1. **Database**: Prisma migrations can be rolled back using:
   ```bash
   npx prisma migrate resolve --rolled-back add_kyc_verification_module
   ```

2. **Feature Flag**: Disable KYC via environment variable:
   ```env
   ENABLE_KYC_VERIFICATION=false
   ```

3. **Routing**: Remove KYC routes from `app_router.dart`

## Monitoring Setup

### Logs to Monitor

```bash
# Tail real-time logs
tail -f logs/kyc-*.log

# Search for errors
grep ERROR logs/kyc-*.log

# Monitor webhook processing
grep "webhook" logs/kyc-*.log
```

### Alerts to Configure

1. High verification failure rate (>20%)
2. Webhook processing failures
3. Database connection issues
4. Encryption/decryption failures
5. Admin review queue exceeding threshold

## Support Resources

- **KYC Implementation Guide**: See `KYC_IMPLEMENTATION_GUIDE.md`
- **API Documentation**: Swagger UI at `/api/docs`
- **Provider Documentation**:
  - DigiLocker: https://digilocker.gov.in/developer/doc
  - Setu: https://docs.setu.co/
  - Signzy: https://docs.signzy.com/
  - HyperVerge: https://docs.hyperverge.co/
