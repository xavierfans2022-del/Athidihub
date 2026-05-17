# Competitive One‑Pager: Our App vs Rentok

## Executive Summary
- Our product: `athidihub` — Flutter mobile app + NestJS backend for PG/Co‑living/property management.
- Strengths: enterprise-grade KYC (DigiLocker + fallbacks), phone-first auth + MPIN, Twilio voice + WhatsApp communications, Prisma-backed data model and admin workflows.
- Rentok: established, full-stack property super‑app (rent collection, leads, property websites, marketplace/insurance), large customer base and partnerships.
- Strategy: win by focusing on KYC/compliance, measurable collection uplift (voice+WhatsApp), transparent pricing, rapid SMB onboarding, and tactical partnerships.

---

## Feature Comparison (high level)
- KYC & Compliance
  - Us: DigiLocker primary, fallback uploads, AES-encrypted storage, audit trails, admin review.
  - Rentok: Digital KYC + police verification; built for scale and integrated into tenant flows.
- Auth & Security
  - Us: Supabase phone OTP + server MPIN (PBKDF2), lockout policy.
  - Rentok: Standard auth (public details limited); mature mobile-first flows.
- Communications
  - Us: WhatsApp/SMS + Twilio voice call reminders, bulk-calling for invoices.
  - Rentok: Polished WhatsApp reminders, payment links, one-click recovery workflows.
- Payments & Guarantees
  - Us: Rent billing + reminders; payment gateway integrations available.
  - Rentok: Zero-deposit/guarantee, insurance bundles, token/reserve payment flows.
- Leads & Marketing
  - Us: Not yet shipped: property websites / lead marketplace.
  - Rentok: Property microsites, lead capture, reserve/booking flows, marketing tools.
- Reporting & Accounting
  - Both: Accounting, reports; Rentok packages and markets this heavily.

---

## Pricing & Commercial Positioning
- Rentok: Sales-driven; Gold/Silver tiers and enterprise deals (pricing via sales, value-add products like guarantees and insurance).
- Suggested approach for us:
  - Transparent per‑bed pricing: e.g., `₹99/month` (Basic), `₹199/month` (Growth), enterprise seat pricing for >200 beds.
  - Free tier: up to 5 beds free to lower acquisition friction for SMBs.
  - Add-ons: Voice reminders, zero-deposit guarantee integration, custom onboarding/concierge.

---

## How We Beat Rentok — Tactical Playbook
1. Product
   - Promote KYC + auditability (legal/compliance selling point for large owners).
   - Differentiate with MPIN + phone-first UX and optional voice-reminders (higher recovery rate).
   - Rapidly ship a minimum property website + "reserve bed" flow (MVP within 2–4 weeks).
2. Pricing & Offer
   - Transparent, low‑friction pricing + trial to get SMB adoption; referral discounts for rapid scaling.
3. GTM & Sales
   - Target niche segments (college clusters, tier‑2 cities) with local partnerships and pilots.
   - Run 3–5 case study pilots and publish ROI (days-to-collect, occupancy lift).
4. Partnerships
   - Integrate with a deposit‑replacement/insurance partner; revenue‑share or referral.
5. Support & Ops
   - Offer concierge onboarding and CSV imports for early customers; local WhatsApp support.

---

## 30‑Day Pilot Checklist (fast rollout)
**Goal:** Validate that our stack improves rent collection and onboarding for SMB owners.

### Week 1 — Prep
- [ ] Select 3 pilot properties (20–150 beds total) with willing owners.
- [ ] Create project plan + success metrics (baseline collection %, avg days-to-collect).
- [ ] Enable full KYC flow and MPIN for owners; ensure Twilio/WhatsApp configured.

### Week 2 — Onboard
- [ ] Import property data (beds, tenants, rents) or perform assisted manual entry.
- [ ] Launch tenant check-in + KYC flows; enable automated reminders.
- [ ] Train owner(s) on dashboard and lead/reservation flows.

### Week 3 — Measure
- [ ] Run automated rent collection + bulk reminders (WhatsApp + voice) for upcoming dues.
- [ ] Track metrics: payment click-through, paid % within 5 days, failed payment reasons.
- [ ] Collect qualitative feedback from owners and tenants.

### Week 4 — Iterate & Publish
- [ ] Tweak messaging, reminder cadence, and voice scripts; retest.
- [ ] Produce a 1‑page case study with KPIs and testimonial.
- [ ] Offer special pilot pricing and conversion path to paid tier.

---

## Quick Next Steps (what I can do now)
- Create a 1‑slide PDF or Google Slide from this page for sales.
- Implement the lightweight property website MVP (React/Flutter) or wire a template generator.
- Run the first pilot onboarding with scripted voice message and measurement dashboard.


---

*Generated: May 17, 2026 — `athidihub` repository.*
