# KYC Module - Webhook Examples & Testing Guide

## Webhook Payload Examples

### DigiLocker Webhook Payload

```json
{
  "event": "verification_complete",
  "status": "success",
  "state": "digilocker_kyc-id_timestamp",
  "request_id": "req_12345",
  "reference_id": "ref_12345",
  "name": "John Doe",
  "aadhaar_number": "1234567890123456",
  "dob": "1990-01-15",
  "address": "123 Main Street, New Delhi, Delhi 110001, India",
  "email": "john@example.com",
  "phone": "9876543210",
  "consent_timestamp": "2024-05-12T10:30:00Z",
  "timestamp": "1715504400000",
  "signature": "sha256_hmac_signature_here"
}
```

### Setu Webhook Payload

```json
{
  "event": "verification_completed",
  "status": "completed",
  "request_id": "req_12345",
  "reference_id": "ref_12345",
  "verified_data": {
    "name": "John Doe",
    "aadhaar_number": "1234567890123456",
    "dob": "1990-01-15",
    "address": "123 Main Street, New Delhi, Delhi 110001, India",
    "email": "john@example.com",
    "phone": "9876543210"
  },
  "consent_given": true,
  "consent_timestamp": "2024-05-12T10:30:00Z",
  "timestamp": "1715504400000",
  "signature": "hmac_sha256_signature"
}
```

### Signzy Webhook Payload

```json
{
  "event": "verification_complete",
  "session_id": "signzy_kyc-id_timestamp",
  "transaction_id": "txn_12345",
  "verification_status": "success",
  "identity_data": {
    "name": "John Doe",
    "aadhaar": "1234567890123456",
    "dob": "1990-01-15",
    "address": "123 Main Street, New Delhi, Delhi 110001, India",
    "email": "john@example.com",
    "phone": "9876543210"
  },
  "consent_given": true,
  "timestamp": "1715504400",
  "signature": "sha256_hmac_here"
}
```

### HyperVerge Webhook Payload

```json
{
  "event": "verification_update",
  "uuid": "hyperverge_kyc-id_timestamp",
  "reference_id": "ref_12345",
  "status": "approved",
  "verified_details": {
    "name": "John Doe",
    "aadhaar_number": "1234567890123456",
    "date_of_birth": "1990-01-15",
    "address": "123 Main Street, New Delhi, Delhi 110001, India",
    "email": "john@example.com",
    "phone": "9876543210"
  },
  "status_message": "Verification successful",
  "timestamp": "2024-05-12T10:30:00Z",
  "signature": "hmac_signature_here"
}
```

### Rejection Webhook

```json
{
  "event": "verification_failed",
  "status": "failed",
  "state": "digilocker_kyc-id_timestamp",
  "reference_id": "ref_12345",
  "error_code": "CONSENT_DENIED",
  "error_description": "User denied consent during verification",
  "timestamp": "1715504400000",
  "signature": "sha256_hmac_signature_here"
}
```

## Testing Webhook Endpoints

### 1. Signature Generation

```javascript
// Node.js - Generate test signature
const crypto = require('crypto');

function generateSignature(payload, secret) {
  const timestamp = Date.now().toString();
  const message = `${JSON.stringify(payload)}.${timestamp}`;
  const signature = crypto
    .createHmac('sha256', secret)
    .update(message)
    .digest('hex');
  
  return {
    signature,
    timestamp,
  };
}

// Example usage
const payload = {
  event: 'verification_complete',
  status: 'success',
  // ... payload data
};

const { signature, timestamp } = generateSignature(
  payload,
  'your-webhook-secret'
);

console.log(`Signature: ${signature}`);
console.log(`Timestamp: ${timestamp}`);
```

### 2. Test Webhook Using cURL

```bash
# Generate signature first
PAYLOAD='{"event":"verification_complete","status":"success","state":"test","reference_id":"ref_123"}'
SECRET="your-webhook-secret"
TIMESTAMP=$(date +%s)000

# For demo purposes (remove in production)
SIGNATURE="test-signature"

# Post webhook
curl -X POST http://localhost:3000/api/kyc/webhook/digilocker \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  -G \
  -d "signature=$SIGNATURE" \
  -d "timestamp=$TIMESTAMP" \
  -v
```

### 3. Test Using Postman

**URL**: `POST http://localhost:3000/api/kyc/webhook/digilocker`

**Headers**:
```
Content-Type: application/json
```

**Query Parameters**:
```
signature: test-signature
timestamp: 1715504400000
```

**Body**:
```json
{
  "event": "verification_complete",
  "status": "success",
  "state": "digilocker_kyc-id_timestamp",
  "reference_id": "ref_12345",
  "name": "John Doe",
  "aadhaar_number": "1234567890123456",
  "dob": "1990-01-15",
  "address": "123 Main Street",
  "email": "john@example.com",
  "phone": "9876543210",
  "consent_timestamp": "2024-05-12T10:30:00Z"
}
```

### 4. Integration Test Script

```typescript
// test/kyc/webhook.e2e-spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../app.module';
import * as crypto from 'crypto';

describe('KYC Webhook Endpoints (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /api/kyc/webhook/digilocker', () => {
    it('should handle successful verification', async () => {
      const payload = {
        event: 'verification_complete',
        status: 'success',
        state: 'digilocker_test',
        reference_id: 'ref_test',
        name: 'Test User',
        aadhaar_number: '1234567890123456',
        dob: '1990-01-15',
        address: 'Test Address',
        email: 'test@example.com',
        phone: '9876543210',
        consent_timestamp: new Date().toISOString(),
      };

      const timestamp = Date.now().toString();
      const message = `${JSON.stringify(payload)}.${timestamp}`;
      const signature = crypto
        .createHmac('sha256', process.env.DIGILOCKER_WEBHOOK_SECRET)
        .update(message)
        .digest('hex');

      const response = await request(app.getHttpServer())
        .post('/api/kyc/webhook/digilocker')
        .send(payload)
        .query({ signature, timestamp })
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
    });

    it('should reject invalid signature', async () => {
      const payload = {
        event: 'verification_complete',
        status: 'success',
      };

      const response = await request(app.getHttpServer())
        .post('/api/kyc/webhook/digilocker')
        .send(payload)
        .query({ signature: 'invalid-sig', timestamp: Date.now().toString() })
        .expect(400);

      expect(response.body).toHaveProperty('message');
    });

    it('should reject expired timestamps', async () => {
      const payload = {
        event: 'verification_complete',
      };

      const oldTimestamp = (Date.now() - 10 * 60 * 1000).toString(); // 10 mins ago
      const signature = crypto
        .createHmac('sha256', process.env.DIGILOCKER_WEBHOOK_SECRET)
        .update(`${JSON.stringify(payload)}.${oldTimestamp}`)
        .digest('hex');

      const response = await request(app.getHttpServer())
        .post('/api/kyc/webhook/digilocker')
        .send(payload)
        .query({ signature, timestamp: oldTimestamp })
        .expect(400);

      expect(response.body).toHaveProperty('message');
    });
  });

  describe('POST /api/kyc/webhook/setu', () => {
    it('should handle Setu webhook format', async () => {
      const payload = {
        event: 'verification_completed',
        status: 'completed',
        request_id: 'req_test',
        reference_id: 'ref_test',
        verified_data: {
          name: 'Test User',
          aadhaar_number: '1234567890123456',
          dob: '1990-01-15',
        },
      };

      const timestamp = Date.now().toString();
      const message = `${JSON.stringify(payload)}.${timestamp}`;
      const signature = crypto
        .createHmac('sha256', process.env.SETU_WEBHOOK_SECRET)
        .update(message)
        .digest('hex');

      const response = await request(app.getHttpServer())
        .post('/api/kyc/webhook/setu')
        .send(payload)
        .query({ signature, timestamp })
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
    });
  });
});
```

### 5. Testing Failure Scenarios

```bash
# Test with missing required fields
curl -X POST http://localhost:3000/api/kyc/webhook/digilocker \
  -H "Content-Type: application/json" \
  -d '{"event":"verification_failed","error_code":"CONSENT_DENIED"}' \
  -G -d "signature=test" -d "timestamp=1715504400000"

# Test with tampered payload
curl -X POST http://localhost:3000/api/kyc/webhook/digilocker \
  -H "Content-Type: application/json" \
  -d '{"event":"verification_complete","status":"tampered"}' \
  -G -d "signature=invalid-signature" -d "timestamp=1715504400000"

# Test with expired session
curl -X POST http://localhost:3000/api/kyc/webhook/digilocker \
  -H "Content-Type: application/json" \
  -d '{"event":"verification_complete","state":"expired_session"}' \
  -G -d "signature=test" -d "timestamp=$(($(date +%s)*1000 - 3600000))"
```

## Mock Provider for Development

For testing without actual provider integration:

```typescript
// kyc/providers/mock-provider.ts
import { VerificationProvider } from '../kyc.service';

export class MockVerificationProvider implements VerificationProvider {
  async initiateVerification(
    kycVerificationId: string,
    tenantData: any,
    redirectUrl: string,
  ): Promise<{ verificationUrl: string; sessionId: string; expiryInSeconds: number }> {
    // Return test verification URL
    const sessionId = `mock_${kycVerificationId}_${Date.now()}`;
    return {
      sessionId,
      verificationUrl: `http://localhost:3001/mock-verification?session=${sessionId}&redirect=${redirectUrl}`,
      expiryInSeconds: 30 * 60,
    };
  }

  validateWebhook(payload: any, signature: string): boolean {
    // Always accept in development
    return process.env.NODE_ENV === 'development';
  }

  async parseWebhookPayload(payload: any): Promise<any> {
    // Return mock successful verification
    return {
      success: true,
      sessionId: payload.sessionId,
      referenceId: `ref_${Date.now()}`,
      fullName: payload.name || 'Test User',
      aadhaarNumber: '1234567890123456',
      dob: '1990-01-15',
      address: 'Test Address',
      email: payload.email || 'test@example.com',
      phone: payload.phone || '9876543210',
      consentTimestamp: new Date().toISOString(),
    };
  }
}
```

## Database Verification Queries

### Check Webhook Logs

```sql
SELECT 
  id,
  provider,
  webhook_event,
  signature_valid,
  processed_at,
  error_message,
  created_at
FROM "KYCWebhookLog"
ORDER BY created_at DESC
LIMIT 20;
```

### Check Verification Status

```sql
SELECT 
  k.id,
  t.name,
  k.status,
  k.failure_reason,
  k.failure_count,
  k.next_retry_at,
  k.created_at,
  k.updated_at
FROM "KYCVerification" k
JOIN "Tenant" t ON k."tenantId" = t.id
WHERE k.status != 'VERIFIED'
ORDER BY k.created_at DESC;
```

### Check Audit Trail

```sql
SELECT 
  a.id,
  a.action,
  a.actor_id,
  a.actor_role,
  a.details,
  a.created_at
FROM "KYCAuditLog" a
JOIN "KYCVerification" k ON a."kycVerificationId" = k.id
JOIN "Tenant" t ON k."tenantId" = t.id
WHERE t.id = 'tenant-id-here'
ORDER BY a.created_at DESC;
```

## Debugging Tips

### Enable Verbose Logging

```env
LOG_LEVEL=debug
DEBUG=kyc:*
```

### Monitor Real-time Logs

```bash
# Tail backend logs
tail -f logs/kyc-*.log | grep -i "webhook\|error"

# Monitor database queries
tail -f /var/log/postgresql/postgresql.log | grep "KYC"

# Monitor API requests
curl -v http://localhost:3000/api/kyc/health
```

### Check Webhook Delivery

```bash
# Test webhook endpoint connectivity
nc -zv localhost:3000

# Test with timeout
timeout 5 curl -X POST http://localhost:3000/api/kyc/webhook/test \
  -H "Content-Type: application/json" \
  -d '{}' \
  -v
```

## Production Readiness Checklist

- [ ] All webhook endpoints secured with signature validation
- [ ] Encryption keys rotated and stored securely
- [ ] Database backups configured
- [ ] Monitoring and alerting set up
- [ ] Rate limiting implemented
- [ ] Webhook retry mechanism functional
- [ ] Audit logs being stored and accessible
- [ ] Sensitive data encryption verified
- [ ] Error handling and logging working
- [ ] Performance tested under load
