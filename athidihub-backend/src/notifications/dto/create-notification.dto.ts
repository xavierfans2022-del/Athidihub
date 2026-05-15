export class CreateNotificationDto {
  organizationId?: string;
  tenantId?: string;
  invoiceId?: string;
  type: string; // e.g. 'tenant_upload_link', 'invoice_sent', 'payment_reminder'
  payload?: any;
}
