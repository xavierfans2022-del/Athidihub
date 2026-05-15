Deployment steps — Supabase cron job (payment reminders)

Overview
- The SQL to register a scheduled job is available at `supabase/cron/tenant_payment_reminders.sql`.
- The job calls your backend endpoint `POST /notifications/reminders/cron` with header `x-cron-secret`.

Preflight (required)
1. Set a secret for Supabase to call your backend. Pick a strong value and save it somewhere safe.
   - In Supabase Dashboard: Project → Settings → API → Add a config var `SUPABASE_CRON_SECRET` (or use Project Secrets depending on your plan).
   - OR with Supabase CLI if available: `supabase secrets set SUPABASE_CRON_SECRET=your_secret_here`.

2. Replace placeholders in the SQL:
   - `YOUR-BACKEND-DOMAIN` → your production backend URL (e.g. `https://api.example.com`).
   - `YOUR_SUPABASE_CRON_SECRET` → the secret you set above.

Deploying the job (two options)

Option A — Supabase SQL editor (Dashboard)
1. Open Supabase project → SQL → New query.
2. Paste the contents of `supabase/cron/tenant_payment_reminders.sql` (after replacing placeholders).
3. Run the query. It will call `cron.schedule(...)` and create the recurring job.

Option B — psql (command-line)
1. Get your database connection string from Supabase Dashboard → Settings → Database → Connection string.
2. Run locally:

```bash
PGCONN="postgresql://<user>:<password>@<host>:5432/postgres"
psql "$PGCONN" -f supabase/cron/tenant_payment_reminders.sql
```

(Ensure the SQL file has placeholders already replaced.)

Verify the job

- In SQL editor run:

```sql
select * from cron.job order by jobid desc limit 50;
```

- You should see an entry for `athidihub-payment-reminders` and the schedule expression.

Test the endpoint manually

- Use curl to simulate Supabase calling your endpoint:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "x-cron-secret: YOUR_SUPABASE_CRON_SECRET" \
  -d '{"daysAhead":3, "includeOverdue":true}' \
  https://YOUR-BACKEND-DOMAIN/notifications/reminders/cron
```

- The endpoint should return JSON with a run summary. Check your backend logs and the `notificationLog` rows created.

Notes and production considerations
- Ensure your backend is reachable from Supabase (public HTTPS with valid TLS).
- Protect the cron endpoint with a strong `SUPABASE_CRON_SECRET` and rotate it if compromised.
- The SQL uses `pg_cron` and `pg_net` extensions — Supabase projects support `pg_cron` in managed databases; if your project does not, contact Supabase support or run scheduled jobs in an external scheduler (GitHub Actions, Cloud Scheduler) that calls the same endpoint.
- The SQL provided schedules at `0 9 * * *` (09:00 UTC). Adjust the cron expression to your timezone needs.

If you want, I can:
- Replace placeholders with your real backend URL and secret (if you provide them),
- Run the SQL via the Supabase CLI here (if you provide access/credentials), or
- Produce an automated deployment script using the Supabase CLI/psql.
