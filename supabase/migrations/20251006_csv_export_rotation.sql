BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE OR REPLACE FUNCTION analytics.prune_expired_export_jobs()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_deleted integer := 0;
BEGIN
  DELETE FROM public.export_jobs
  WHERE status IN ('completed', 'failed')
    AND logged_at < now() - INTERVAL '7 days';

  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

DELETE FROM cron.job WHERE jobname = 'analytics_prune_export_jobs';

SELECT cron.schedule(
  'analytics_prune_export_jobs',
  '30 18 * * *',
  $$SELECT analytics.prune_expired_export_jobs();$$
);

COMMIT;
