import { Logger } from '@nestjs/common';
import Twilio from 'twilio';

export class TwilioVoiceProvider {
  private readonly logger = new Logger(TwilioVoiceProvider.name);
  private readonly isProduction = process.env.NODE_ENV === 'production';
  private readonly accountSid = process.env.TWILIO_ACCOUNT_SID;
  private readonly authToken = process.env.TWILIO_AUTH_TOKEN;
  private readonly defaultCountryCode = process.env.TWILIO_DEFAULT_COUNTRY_CODE || '+91';
  private readonly fromNumber = process.env.TWILIO_VOICE_FROM;
  private readonly allowMock = process.env.TWILIO_VOICE_ALLOW_MOCK === 'true';

  private readonly isConfigured = Boolean(this.accountSid && this.authToken && this.fromNumber);

  private readonly client = this.accountSid && this.authToken ? Twilio(this.accountSid, this.authToken) : null;

  async sendCall(options: { phone: string; message: string; callerId?: string; voice?: string; language?: string }) {
    if (!this.isConfigured || !this.client) {
      if (this.isProduction && !this.allowMock) {
        throw new Error(
          'Twilio voice provider is not configured. Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN and TWILIO_VOICE_FROM.',
        );
      }

      this.logger.warn('Twilio voice is not configured. Returning a simulated call id in non-configured environment.');
      return { sid: `dev-call-${Date.now()}` };
    }

    const to = this.normalizePhoneNumber(options.phone);
    const from = this.normalizePhoneNumber(options.callerId ?? this.fromNumber!);
    const twiml = this.buildTwiml(options.message, options.voice, options.language);

    const call = await this.client.calls.create({
      to,
      from,
      twiml,
    });

    return {
      id: call.sid,
      sid: call.sid,
      status: call.status,
      to: call.to,
      from: call.from,
    };
  }

  private normalizePhoneNumber(phone: string): string {
    const raw = phone.trim();
    const normalized = raw.replace(/[^\d+]/g, '');

    let e164: string;
    if (normalized.startsWith('+')) {
      e164 = normalized;
    } else if (normalized.startsWith('00')) {
      e164 = `+${normalized.slice(2)}`;
    } else if (/^\d{10}$/.test(normalized)) {
      e164 = `${this.defaultCountryCode}${normalized}`;
      this.logger.warn(`Phone number "${phone}" had no country code. Using ${this.defaultCountryCode}.`);
    } else {
      e164 = `+${normalized}`;
    }

    if (!/^\+\d{8,15}$/.test(e164)) {
      throw new Error(`Invalid phone format: "${phone}". Expected E.164 like +919030070678.`);
    }

    return e164;
  }

  private buildTwiml(message: string, voice?: string, language?: string) {
    const escaped = this.escapeXml(message || 'You have a new reminder from Athidihub.');
    const selectedVoice = this.escapeXml(voice || 'alice');
    const selectedLanguage = this.escapeXml(language || 'en-IN');

    return `<?xml version="1.0" encoding="UTF-8"?><Response><Say voice="${selectedVoice}" language="${selectedLanguage}">${escaped}</Say></Response>`;
  }

  private escapeXml(text: string) {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }
}