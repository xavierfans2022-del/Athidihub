import { Injectable } from '@nestjs/common';
import * as crypto from 'crypto';

@Injectable()
export class CryptoService {
  private algorithm = 'aes-256-cbc';
  private encryptionKey: Buffer;
  private iv: Buffer;

  constructor() {
    // In production, load encryption key from secure vault (e.g., AWS Secrets Manager, Vault)
    const key = process.env.ENCRYPTION_KEY || 'default-256-bit-key-change-in-production-environment-12345';
    const ivStr = process.env.ENCRYPTION_IV || 'default-16-byte-iv-1234';

    // Ensure key is 32 bytes for AES-256
    this.encryptionKey = crypto
      .createHash('sha256')
      .update(key)
      .digest();

    // Ensure IV is 16 bytes
    this.iv = Buffer.from(ivStr.substring(0, 16).padEnd(16, '0'));
  }

  encrypt(text: string): string {
    if (!text) return '';

    try {
      const cipher = crypto.createCipheriv(this.algorithm, this.encryptionKey, this.iv);
      let encrypted = cipher.update(text, 'utf8', 'hex');
      encrypted += cipher.final('hex');

      return encrypted;
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      throw new Error(`Encryption failed: ${message}`);
    }
  }

  decrypt(encryptedText: string): string {
    if (!encryptedText) return '';

    try {
      const decipher = crypto.createDecipheriv(this.algorithm, this.encryptionKey, this.iv);
      let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      return decrypted;
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      throw new Error(`Decryption failed: ${message}`);
    }
  }

  hashPassword(password: string): string {
    return crypto.createHash('sha256').update(password).digest('hex');
  }

  generateRandomToken(length = 32): string {
    return crypto.randomBytes(length).toString('hex');
  }

  generateHMAC(message: string, secret: string): string {
    return crypto.createHmac('sha256', secret).update(message).digest('hex');
  }
}
