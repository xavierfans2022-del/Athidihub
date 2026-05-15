import { Logger } from '@nestjs/common';
import Twilio from 'twilio';

type WhatsAppTemplate = {
  name: string;
  language: { code: string };
  components?: Array<Record<string, unknown>>;
};

export class TwilioWhatsAppProvider {
  private readonly logger = new Logger(TwilioWhatsAppProvider.name);
  private readonly isProduction = process.env.NODE_ENV === 'production';
  private readonly accountSid = process.env.TWILIO_ACCOUNT_SID;
  private readonly authToken = process.env.TWILIO_AUTH_TOKEN;
  private readonly defaultCountryCode = process.env.WHATSAPP_DEFAULT_COUNTRY_CODE || '+91';
  private readonly fromNumber = process.env.TWILIO_WHATSAPP_FROM;
  private readonly messagingServiceSid = process.env.TWILIO_MESSAGING_SERVICE_SID;
  private readonly allowMock = process.env.WHATSAPP_ALLOW_MOCK === 'true';

  private readonly isConfigured = Boolean(
    this.accountSid &&
      this.authToken &&
      (this.messagingServiceSid || this.fromNumber),
  );

  private readonly client =
    this.accountSid && this.authToken
      ? Twilio(this.accountSid, this.authToken)
      : null;

  async sendMessage(options: {
    phone: string;
    text?: string;
    mediaUrl?: string;
    template?: WhatsAppTemplate;
  }) {
    const { phone, text, mediaUrl, template } = options;

    if (!this.isConfigured || !this.client) {
      if (this.isProduction && !this.allowMock) {
        throw new Error(
          'Twilio WhatsApp provider is not configured. Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN and TWILIO_WHATSAPP_FROM or TWILIO_MESSAGING_SERVICE_SID.',
        );
      }

      this.logger.warn(
        'Twilio WhatsApp is not configured. Returning a simulated message id in non-configured environment.',
      );
      return { sid: `dev-${Date.now()}` };
    }

    const to = this.normalizeWhatsAppNumber(phone);
    const messageBody = this.buildMessageBody(text, template);
    const mediaUrlList = mediaUrl ? [mediaUrl] : undefined;

    const message = await this.client.messages.create({
      to,
      from: this.fromNumber ? this.normalizeWhatsAppNumber(this.fromNumber) : undefined,
      messagingServiceSid: this.messagingServiceSid,
      body: messageBody,
      mediaUrl: mediaUrlList,
    });

    return {
      id: message.sid,
      sid: message.sid,
      status: message.status,
      to: message.to,
      from: message.from,
    };
  }

  async sendTemplate(phone: string, template: WhatsAppTemplate) {
    if (!this.isConfigured || !this.client) {
      if (this.isProduction && !this.allowMock) {
        throw new Error('Twilio WhatsApp provider is not configured for template sending.');
      }

      this.logger.warn('Twilio WhatsApp is not configured. Returning a simulated template message id in non-configured environment.');
      return { sid: `dev-template-${Date.now()}` };
    }

    const to = this.normalizeWhatsAppNumber(phone);

    // Attempt to use Twilio's content/template API. The structure below follows Twilio's 'content' payload for WhatsApp templates.
    // Depending on your Twilio SDK version you may need to adapt fields. We use a permissive call to avoid strict typings here.
    try {
      const message = await this.client.messages.create(({
        to,
        from: this.fromNumber ? this.normalizeWhatsAppNumber(this.fromNumber) : undefined,
        messagingServiceSid: this.messagingServiceSid,
        // content array with template descriptor
        content: [
          {
            type: 'template',
            template: {
              name: template.name,
              language: { code: template.language?.code ?? 'en' },
              components: template.components ?? [],
            },
          },
        ],
      } as any));

      return { id: message.sid, sid: message.sid, status: message.status };
    } catch (err: any) {
      this.logger.error(`Template send failed: ${String(err?.message ?? err)}`);
      throw err;
    }
  }

  private normalizeWhatsAppNumber(phone: string): string {
    const raw = phone.trim();
    const withoutPrefix = raw.startsWith('whatsapp:')
      ? raw.slice('whatsapp:'.length)
      : raw;

    const normalized = withoutPrefix.replace(/[^\d+]/g, '');

    let e164: string;
    if (normalized.startsWith('+')) {
      e164 = normalized;
    } else if (normalized.startsWith('00')) {
      e164 = `+${normalized.slice(2)}`;
    } else if (/^\d{10}$/.test(normalized)) {
      // Treat bare 10-digit numbers as local and prepend the configured default country code.
      e164 = `${this.defaultCountryCode}${normalized}`;
      this.logger.warn(
        `Phone number "${phone}" had no country code. Using ${this.defaultCountryCode}.`,
      );
    } else {
      e164 = `+${normalized}`;
    }

    if (!/^\+\d{8,15}$/.test(e164)) {
      throw new Error(
        `Invalid WhatsApp phone format: "${phone}". Expected E.164 like +919030070678.`,
      );
    }

    return `whatsapp:${e164}`;
  }

  private buildMessageBody(text?: string, template?: WhatsAppTemplate): string {
    if (!template) {
      return text ?? '';
    }

    // Twilio content templates are account-specific; we serialize template metadata as fallback text.
    const templateData = {
      template: template.name,
      language: template.language?.code,
      components: template.components ?? [],
    };

    return text ?? `Template payload: ${JSON.stringify(templateData)}`;
  }
}