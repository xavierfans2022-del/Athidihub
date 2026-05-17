WhatsApp Notifications (Twilio) — Production Guide

Overview
- The notifications system uses Twilio for WhatsApp messages via `TwilioWhatsAppProvider`.
- Business-initiated freeform messages are restricted by WhatsApp to a 24-hour session window. Outside that window Twilio returns error 63016 ("Outside messaging window").
- Reminder runs can optionally place a Twilio voice call after the WhatsApp notification by enabling `REMINDER_VOICE_CALLS_ENABLED=true` or passing `voiceCall: true` to the reminder endpoint.

What we implemented
- Detect Twilio 63016 errors in `NotificationsService.sendNotificationDirectly`.
- If a `template` payload is present, attempt to send a WhatsApp Message Template via `TwilioWhatsAppProvider.sendTemplate` (uses Twilio `content` payload).
- If template send fails or no template is provided, the notification is marked failed with a clear error message instructing operators to use approved templates.

Required environment variables
- `TWILIO_ACCOUNT_SID` — Twilio account SID
- `TWILIO_AUTH_TOKEN` — Twilio auth token
- `TWILIO_WHATSAPP_FROM` — WhatsApp-enabled Twilio number (e.g., +1415...)
- `TWILIO_MESSAGING_SERVICE_SID` (optional) — Messaging service SID
- `WHATSAPP_DEFAULT_COUNTRY_CODE` (optional, default: +91) — used to normalize 10-digit numbers
- `WHATSAPP_ALLOW_MOCK` (optional) — set to 'true' for local dev to avoid Twilio calls
- `TWILIO_VOICE_FROM` — verified Twilio voice-enabled number for reminder calls
- `TWILIO_VOICE_ALLOW_MOCK` (optional) — set to 'true' for local dev to simulate voice calls
- `REMINDER_VOICE_CALLS_ENABLED` (optional) — set to 'true' to place reminder calls by default

Production checklist
1. Register and verify your WhatsApp Business Profile with Meta.
2. Set up templates in Meta Business Manager and submit them for approval.
3. Configure templates in the application payloads (`notificationLog.payload.template`) so the system can attempt template sends.
4. Ensure the following in production:
   - `TWILIO_ACCOUNT_SID` and `TWILIO_AUTH_TOKEN` are set.
   - `TWILIO_WHATSAPP_FROM` or `TWILIO_MESSAGING_SERVICE_SID` is set.
5. Provision a way to log inbound messages (webhook) and persist the last inbound timestamp per user. That enables session-window checks before sending (future improvement).
6. Run `npm run build` and deploy the compiled `dist` artifacts.

Failover and monitoring
- When template send fails, the notification is marked failed and the error is recorded in `NotificationLog.error`.
- Consider adding a fallback channel (SMS/email) for critical alerts.
- Add monitoring/alerts for repeated 63016 errors to track missing templates or messaging-window issues.
- Voice reminder calls use Twilio's `calls.create` with an inline TwiML payload; if you need richer call flows later, move the TwiML to a hosted endpoint.

Developer notes
- `TwilioWhatsAppProvider.sendTemplate` attempts to call Twilio's `messages.create` with a `content` array. Depending on Twilio SDK versions this may require adjustment.
- For a fully production-grade implementation we recommend:
  - Persist inbound messages via a webhook endpoint and a new `InboundMessage` model.
  - Pre-check the last inbound timestamp and choose session vs template automatically.
  - Maintain a template mapping config (notification type -> template name + parameter map) and a minor admin UI to manage template IDs.

If you want, I can:
- Add an `InboundMessage` Prisma model and webhook endpoint to persist inbound messages.
- Add a template mapping config and wire notification types to templates.
- Implement SMS/email fallback providers.
