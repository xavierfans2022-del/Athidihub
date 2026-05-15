-- Supabase cron job for production payment reminders.
-- Run this once after replacing the placeholders below.

create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.schedule(
  'athidihub-payment-reminders',
  '0 9 * * *',
  $$
    select net.http_post(
      url := 'https://unishelf.in/notifications/reminders/cron',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-cron-secret', 'sb_publishable_6qaMW4Wj_UJrq7TIcGGX4g_vCdWT8kN'
      ),
      body := jsonb_build_object(
        'daysAhead', 3,
        'includeOverdue', true
      )
    );
  $$
);