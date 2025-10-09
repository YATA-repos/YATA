BEGIN;

DO $$
DECLARE
  v_expected text := '2025-03-15T10:30:15+09:00';
  v_actual text;
BEGIN
  v_actual := analytics.format_timestamp_tz('2025-03-15 01:30:15+00'::timestamptz, 'Asia/Tokyo');
  IF v_actual <> v_expected THEN
    RAISE EXCEPTION 'analytics.format_timestamp_tz returned %, expected %', v_actual, v_expected;
  END IF;
END;
$$;

DO $$
DECLARE
  v_missing text[];
BEGIN
  SELECT array_agg(proname ORDER BY proname)
  INTO v_missing
  FROM (
    SELECT p.proname
    FROM pg_proc p
    WHERE p.pronamespace = 'analytics'::regnamespace
      AND p.proname IN (
        'generate_sales_line_items_csv',
        'generate_purchases_line_items_csv',
        'generate_inventory_movements_csv',
        'generate_waste_log_csv',
        'generate_menu_engineering_daily_csv'
      )
      AND position('analytics.format_timestamp_tz' IN pg_get_functiondef(p.oid)) = 0
  ) AS missing;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'CSV generator missing format_timestamp_tz usage: %', v_missing;
  END IF;
END;
$$;

DO $$
DECLARE
  v_result jsonb;
  v_required boolean;
BEGIN
  v_result := analytics.detect_pii_patterns('order_id,email\n1,test@example.com\n');
  v_required := COALESCE((v_result->>'encryption_required')::boolean, false);
  IF NOT v_required THEN
    RAISE EXCEPTION 'detect_pii_patterns should require encryption for email sample: %', v_result;
  END IF;

  IF COALESCE(jsonb_array_length(v_result->'detected_rules'), 0) = 0 THEN
    RAISE EXCEPTION 'detect_pii_patterns should record detected_rules for email sample';
  END IF;
END;
$$;

COMMIT;
