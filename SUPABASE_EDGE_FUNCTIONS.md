# KYC Module - Supabase Edge Functions Alternative

This guide explains how to use Supabase Edge Functions as an alternative for webhook processing instead of direct backend endpoints.

## Overview

Supabase Edge Functions can process KYC webhooks with benefits:
- Serverless architecture
- Auto-scaling
- Built-in authentication
- Direct database access
- Cost-effective for low-volume webhooks

## Setup

### 1. Initialize Supabase Functions

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Create new function
supabase functions new kyc-webhook-digilocker
supabase functions new kyc-webhook-setu
supabase functions new kyc-webhook-signzy
supabase functions new kyc-webhook-hyperverge
```

### 2. DigiLocker Webhook Function

Create `supabase/functions/kyc-webhook-digilocker/index.ts`:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import * as crypto from 'https://deno.land/std@0.208.0/crypto/mod.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const webhookSecret = Deno.env.get('DIGILOCKER_WEBHOOK_SECRET')!;

serve(async (req) => {
  // Only allow POST
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    // Get signature and timestamp from query params
    const url = new URL(req.url);
    const signature = url.searchParams.get('signature');
    const timestamp = url.searchParams.get('timestamp');

    if (!signature || !timestamp) {
      return new Response(
        JSON.stringify({ error: 'Missing signature or timestamp' }),
        { status: 400 }
      );
    }

    // Get request body
    const body = await req.json();

    // Validate webhook signature
    const message = `${JSON.stringify(body)}.${timestamp}`;
    const encoder = new TextEncoder();
    const keyData = encoder.encode(webhookSecret);
    const key = await crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );
    
    const signatureData = await crypto.subtle.sign(
      'HMAC',
      key,
      encoder.encode(message)
    );
    
    const expectedSignature = Array.from(new Uint8Array(signatureData))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');

    // Constant-time comparison
    if (signature !== expectedSignature) {
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 400 }
      );
    }

    // Validate timestamp (within 5 minutes)
    const now = Date.now();
    const requestTime = parseInt(timestamp);
    if (Math.abs(now - requestTime) > 5 * 60 * 1000) {
      return new Response(
        JSON.stringify({ error: 'Timestamp expired' }),
        { status: 400 }
      );
    }

    // Create Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse payload
    const kycSessionId = body.state;
    const referenceId = body.reference_id;
    const status = body.status === 'success' ? 'VERIFIED' : 'REJECTED';

    // Find KYC verification by provider transaction ID
    const { data: kycData, error: kycError } = await supabase
      .from('KYCVerification')
      .select('*')
      .eq('providerTransactionId', kycSessionId)
      .single();

    if (kycError) {
      console.error('KYC record not found:', kycError);
      return new Response(
        JSON.stringify({ error: 'KYC record not found' }),
        { status: 404 }
      );
    }

    if (body.status === 'success') {
      // Update with verified data
      const { error: updateError } = await supabase
        .from('KYCVerification')
        .update({
          status: 'VERIFIED',
          verifiedFullName: body.name,
          verifiedEmail: body.email,
          verifiedPhone: body.phone,
          verifiedDOB: body.dob,
          verifiedAddress: body.address,
          maskedAadhaarNumber: `****${body.aadhaar_number.slice(-4)}`,
          verificationReferenceId: referenceId,
          consentGrantedAt: new Date(body.consent_timestamp).toISOString(),
          updatedAt: new Date().toISOString(),
        })
        .eq('id', kycData.id);

      if (updateError) {
        console.error('Update error:', updateError);
        return new Response(
          JSON.stringify({ error: 'Failed to update KYC' }),
          { status: 500 }
        );
      }

      // Log audit entry
      await supabase
        .from('KYCAuditLog')
        .insert({
          kycVerificationId: kycData.id,
          action: 'VERIFICATION_COMPLETED',
          actorRole: 'SYSTEM',
          details: { provider: 'DIGILOCKER' },
        });

      // Log webhook
      await supabase
        .from('KYCWebhookLog')
        .insert({
          kycVerificationId: kycData.id,
          provider: 'DIGILOCKER',
          webhookEvent: 'verification_complete',
          webhookPayload: body,
          signatureValid: true,
          processedAt: new Date().toISOString(),
        });

      // Send notification (integrate with your notification service)
      // await notifyTenant(kycData.tenantId, 'KYC_VERIFIED');

    } else {
      // Handle failure
      const { error: updateError } = await supabase
        .from('KYCVerification')
        .update({
          status: 'FAILED',
          failureReason: body.error_description || 'Verification failed',
          failureCount: (kycData.failureCount || 0) + 1,
          lastFailureAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        })
        .eq('id', kycData.id);

      if (updateError) {
        console.error('Update error:', updateError);
        return new Response(
          JSON.stringify({ error: 'Failed to update KYC' }),
          { status: 500 }
        );
      }

      // Log audit entry
      await supabase
        .from('KYCAuditLog')
        .insert({
          kycVerificationId: kycData.id,
          action: 'VERIFICATION_FAILED',
          actorRole: 'SYSTEM',
          details: { 
            reason: body.error_description,
            provider: 'DIGILOCKER',
          },
        });
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Webhook processed successfully',
        verificationId: kycData.id,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );

  } catch (error) {
    console.error('Error processing webhook:', error);
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      { status: 500 }
    );
  }
});
```

### 3. Setu Webhook Function

Create `supabase/functions/kyc-webhook-setu/index.ts`:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const body = await req.json();
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const requestId = body.request_id;
    const status = body.status === 'completed' ? 'VERIFIED' : 'FAILED';

    // Find KYC verification
    const { data: kycData, error: kycError } = await supabase
      .from('KYCVerification')
      .select('*')
      .eq('providerTransactionId', requestId)
      .single();

    if (kycError) {
      return new Response(
        JSON.stringify({ error: 'KYC record not found' }),
        { status: 404 }
      );
    }

    if (body.status === 'completed') {
      const verifiedData = body.verified_data;

      const { error: updateError } = await supabase
        .from('KYCVerification')
        .update({
          status: 'VERIFIED',
          verifiedFullName: verifiedData.name,
          verifiedEmail: verifiedData.email,
          verifiedPhone: verifiedData.phone,
          verifiedDOB: verifiedData.dob,
          verifiedAddress: verifiedData.address,
          maskedAadhaarNumber: `****${verifiedData.aadhaar_number.slice(-4)}`,
          verificationReferenceId: body.reference_id,
          consentGrantedAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        })
        .eq('id', kycData.id);

      if (updateError) {
        throw updateError;
      }

      await supabase
        .from('KYCAuditLog')
        .insert({
          kycVerificationId: kycData.id,
          action: 'VERIFICATION_COMPLETED',
          actorRole: 'SYSTEM',
          details: { provider: 'SETU' },
        });
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200 }
    );

  } catch (error) {
    console.error('Webhook error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    );
  }
});
```

### 4. Deploy Functions

```bash
# Set environment variables
supabase secrets set DIGILOCKER_WEBHOOK_SECRET="your-secret"
supabase secrets set SETU_WEBHOOK_SECRET="your-secret"

# Deploy functions
supabase functions deploy kyc-webhook-digilocker
supabase functions deploy kyc-webhook-setu
supabase functions deploy kyc-webhook-signzy
supabase functions deploy kyc-webhook-hyperverge

# List deployed functions
supabase functions list
```

### 5. Get Function URLs

```bash
# Get function URL
supabase functions list

# Output:
# kyc-webhook-digilocker  https://your-project.supabase.co/functions/v1/kyc-webhook-digilocker
# kyc-webhook-setu         https://your-project.supabase.co/functions/v1/kyc-webhook-setu
```

### 6. Configure Provider Webhooks

Update provider settings with Supabase function URLs:

**DigiLocker**: 
```
https://your-project.supabase.co/functions/v1/kyc-webhook-digilocker?signature={signature}&timestamp={timestamp}
```

**Setu**:
```
https://your-project.supabase.co/functions/v1/kyc-webhook-setu
```

## Testing Supabase Functions

### Local Testing

```bash
# Start Supabase locally
supabase start

# Test function locally
supabase functions serve

# In another terminal, test with curl
curl -X POST http://localhost:54321/functions/v1/kyc-webhook-digilocker \
  -H "Content-Type: application/json" \
  -d '{"state":"test","status":"success","name":"Test User"}' \
  -G -d "signature=test" -d "timestamp=$(date +%s)000"
```

### View Logs

```bash
# View function logs
supabase functions logs kyc-webhook-digilocker

# Follow logs in real-time
supabase functions logs kyc-webhook-digilocker --follow
```

## Hybrid Approach

Use both backend endpoints and Supabase functions:

```typescript
// In backend app.module.ts
@Module({
  imports: [
    // Direct backend webhooks for primary handling
    KYCModule,
    // Supabase for async/backup processing
    SupabaseModule,
  ],
})
export class AppModule {}
```

## Monitoring

### Set Up Alerts

```bash
# Check function invocations
supabase functions stats kyc-webhook-digilocker

# Set up alerts in Supabase dashboard for:
# - High error rates
# - Long execution times
# - Rate limit exceeded
```

### Performance Optimization

```typescript
// Add caching for repeated lookups
const cacheKey = `kyc_${kycSessionId}`;
const cached = await redis.get(cacheKey);

if (!cached) {
  const { data } = await supabase
    .from('KYCVerification')
    .select('*')
    .eq('providerTransactionId', kycSessionId)
    .single();
  
  await redis.setex(cacheKey, 3600, JSON.stringify(data));
}
```

## Database Functions (PostgreSQL)

Alternative: Use PostgreSQL functions for webhook processing:

```sql
CREATE OR REPLACE FUNCTION process_kyc_webhook(
  p_provider VARCHAR,
  p_session_id VARCHAR,
  p_payload JSONB
)
RETURNS JSONB AS $$
BEGIN
  -- Update KYC verification
  UPDATE "KYCVerification"
  SET
    status = CASE 
      WHEN p_payload->>'status' = 'success' THEN 'VERIFIED'
      ELSE 'REJECTED'
    END,
    "verifiedFullName" = p_payload->>'name',
    "verificationReferenceId" = p_payload->>'reference_id',
    "updatedAt" = NOW()
  WHERE "providerTransactionId" = p_session_id;

  -- Log audit entry
  INSERT INTO "KYCAuditLog" (
    "kycVerificationId",
    action,
    "actorRole",
    details
  )
  SELECT
    id,
    'VERIFICATION_COMPLETED',
    'SYSTEM',
    jsonb_build_object('provider', p_provider)
  FROM "KYCVerification"
  WHERE "providerTransactionId" = p_session_id;

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql;
```

Call from webhook:

```typescript
const { data } = await supabase.rpc('process_kyc_webhook', {
  p_provider: 'DIGILOCKER',
  p_session_id: body.state,
  p_payload: body,
});
```

## Advantages of Supabase Functions

✅ No infrastructure management
✅ Auto-scaling
✅ Integrated with PostgreSQL
✅ Built-in environment secrets management
✅ Real-time logs and monitoring
✅ Low latency (geographically distributed)
✅ TypeScript/Deno support
✅ Simple deployment

## Disadvantages

❌ Limited customization compared to full NestJS
❌ Cold start latency
❌ Harder to test locally
❌ Less mature ecosystem than Node.js
