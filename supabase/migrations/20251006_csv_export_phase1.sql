-- CSV Export Phase 1 foundational schema
-- Generated 2025-10-06 to implement analytics views, export RPC, and export job log table.

BEGIN;

CREATE SCHEMA IF NOT EXISTS analytics;
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

COMMENT ON SCHEMA analytics IS 'Analytics and export-facing views for CSV export';

-- Ensure base transactional tables expose the columns required by analytics views.
ALTER TABLE IF EXISTS public.orders
  ADD COLUMN IF NOT EXISTS org_id uuid,
  ADD COLUMN IF NOT EXISTS location_id uuid,
  ADD COLUMN IF NOT EXISTS channel text,
  ADD COLUMN IF NOT EXISTS table_number text,
  ADD COLUMN IF NOT EXISTS cancel_reason text;

ALTER TABLE IF EXISTS public.order_items
  ADD COLUMN IF NOT EXISTS selected_options jsonb,
  ADD COLUMN IF NOT EXISTS special_request text;

ALTER TABLE IF EXISTS public.menu_items
  ADD COLUMN IF NOT EXISTS external_code text,
  ADD COLUMN IF NOT EXISTS tax_rate numeric(5, 2);

ALTER TABLE IF EXISTS public.purchases
  ADD COLUMN IF NOT EXISTS org_id uuid,
  ADD COLUMN IF NOT EXISTS location_id uuid,
  ADD COLUMN IF NOT EXISTS supplier_id uuid,
  ADD COLUMN IF NOT EXISTS po_number text,
  ADD COLUMN IF NOT EXISTS tax_rate numeric(5, 2),
  ADD COLUMN IF NOT EXISTS currency text DEFAULT 'JPY',
  ADD COLUMN IF NOT EXISTS received_by uuid;

ALTER TABLE IF EXISTS public.purchase_items
  ADD COLUMN IF NOT EXISTS unit_cost numeric(12, 2),
  ADD COLUMN IF NOT EXISTS tax_amount numeric(12, 2),
  ADD COLUMN IF NOT EXISTS batch_no text,
  ADD COLUMN IF NOT EXISTS expiry_date date,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS conversion_ratio numeric(12, 3);

ALTER TABLE IF EXISTS public.materials
  ADD COLUMN IF NOT EXISTS external_code text,
  ADD COLUMN IF NOT EXISTS last_purchase_unit_cost numeric(12, 2),
  ADD COLUMN IF NOT EXISTS tare_weight numeric(12, 3);

ALTER TABLE IF EXISTS public.recipes
  ADD COLUMN IF NOT EXISTS yield_rate numeric(5, 2) DEFAULT 1;

ALTER TABLE IF EXISTS public.stock_transactions
  ADD COLUMN IF NOT EXISTS org_id uuid,
  ADD COLUMN IF NOT EXISTS location_id uuid,
  ADD COLUMN IF NOT EXISTS reason text,
  ADD COLUMN IF NOT EXISTS lot_no text;

-- Export job audit table shared by RPC and service layer.
CREATE TABLE IF NOT EXISTS public.export_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  location_id uuid,
  dataset_id text NOT NULL,
  status text NOT NULL CHECK (status IN ('queued', 'running', 'completed', 'failed')),
  requested_by uuid,
  requested_at timestamptz NOT NULL DEFAULT now(),
  period_from timestamptz NOT NULL,
  period_to timestamptz NOT NULL,
  logged_at timestamptz NOT NULL DEFAULT now(),
  row_count integer,
  duration_ms integer,
  error_details text,
  metadata jsonb,
  file_name text,
  storage_path text,
  source_view_version text,
  generated_by_app_version text
);

CREATE INDEX IF NOT EXISTS export_jobs_org_idx
  ON public.export_jobs (org_id, dataset_id, requested_at DESC);
CREATE INDEX IF NOT EXISTS export_jobs_status_idx
  ON public.export_jobs (status);
CREATE INDEX IF NOT EXISTS export_jobs_period_idx
  ON public.export_jobs (period_from, period_to);

-- Helper utility functions --------------------------------------------------

CREATE OR REPLACE FUNCTION analytics.format_timestamp_tz(
  p_value timestamptz,
  p_timezone text DEFAULT 'Asia/Tokyo'
) RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  v_local timestamp;
  v_offset_seconds integer;
  v_hours integer;
  v_minutes integer;
  v_sign text;
BEGIN
  IF p_value IS NULL THEN
    RETURN '';
  END IF;

  v_local := timezone(p_timezone, p_value);
  v_offset_seconds := EXTRACT(EPOCH FROM (timezone(p_timezone, p_value) - timezone('UTC', p_value)));
  v_sign := CASE WHEN v_offset_seconds < 0 THEN '-' ELSE '+' END;
  v_hours := abs(v_offset_seconds) / 3600;
  v_minutes := (abs(v_offset_seconds) % 3600) / 60;

  RETURN to_char(v_local, 'YYYY-MM-DD"T"HH24:MI:SS')
      || format('%s%02d:%02d', v_sign, v_hours, v_minutes);
END;
$$;

CREATE OR REPLACE FUNCTION analytics.format_numeric(
  p_value numeric,
  p_scale integer DEFAULT 2
) RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  v_format text;
BEGIN
  IF p_value IS NULL THEN
    RETURN '';
  END IF;

  IF p_scale <= 0 THEN
    RETURN to_char(p_value, 'FM9999999990');
  END IF;

  v_format := 'FM9999999990.' || repeat('0', p_scale);
  RETURN to_char(p_value, v_format);
END;
$$;

CREATE OR REPLACE FUNCTION analytics.detect_pii_patterns(
  p_csv text
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_rules jsonb := '[]'::jsonb;
  v_required boolean := false;
  v_email_count integer;
  v_email_samples jsonb;
  v_phone_count integer;
  v_phone_samples jsonb;
BEGIN
  IF p_csv IS NULL OR btrim(p_csv) = '' THEN
    RETURN jsonb_build_object(
      'encryption_required', false,
      'detected_rules', '[]'::jsonb
    );
  END IF;

  SELECT
    COUNT(*),
    COALESCE(jsonb_agg(value) FILTER (WHERE idx <= 3), '[]'::jsonb)
  INTO v_email_count, v_email_samples
  FROM (
    SELECT DISTINCT match[1] AS value,
           row_number() OVER (ORDER BY match[1]) AS idx
    FROM regexp_matches(
      p_csv,
      '([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})',
      'g'
    ) AS match
  ) AS email_matches;

  IF v_email_count > 0 THEN
    v_required := true;
    v_rules := v_rules || jsonb_build_array(
      jsonb_build_object(
        'rule_id', 'email_address',
        'match_count', v_email_count,
        'sample_values', v_email_samples
      )
    );
  END IF;

  SELECT
    COUNT(*),
    COALESCE(jsonb_agg(value) FILTER (WHERE idx <= 3), '[]'::jsonb)
  INTO v_phone_count, v_phone_samples
  FROM (
    SELECT DISTINCT match[1] AS value,
           row_number() OVER (ORDER BY match[1]) AS idx
    FROM regexp_matches(
      p_csv,
      '((?:\+81[- ]?)?0\d{1,4}[- ]?\d{1,4}[- ]?\d{3,4})',
      'g'
    ) AS match
  ) AS phone_matches;

  IF v_phone_count > 0 THEN
    v_required := true;
    v_rules := v_rules || jsonb_build_array(
      jsonb_build_object(
        'rule_id', 'jp_phone_number',
        'match_count', v_phone_count,
        'sample_values', v_phone_samples
      )
    );
  END IF;

  RETURN jsonb_build_object(
    'encryption_required', v_required,
    'detected_rules', CASE
      WHEN v_rules = '[]'::jsonb THEN '[]'::jsonb
      ELSE v_rules
    END
  );
END;
$$;

CREATE OR REPLACE FUNCTION analytics.csv_escape(p_value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_value IS NULL OR p_value = '' THEN ''
    WHEN p_value ~ '[,\n\r"]' THEN '"' || replace(p_value, '"', '""') || '"'
    ELSE p_value
  END;
$$;

CREATE OR REPLACE FUNCTION analytics.csv_line(p_values text[])
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT string_agg(analytics.csv_escape(val), ',' ORDER BY ord)
  FROM unnest(p_values) WITH ORDINALITY AS u(val, ord);
$$;

-- Analytics views ----------------------------------------------------------

CREATE OR REPLACE VIEW analytics.sales_line_items_view AS
WITH line_base AS (
  SELECT
    o.org_id,
    o.location_id,
    (timezone('Asia/Tokyo', o.ordered_at))::date AS business_date,
    o.id AS order_id,
    oi.id AS line_id,
    ROW_NUMBER() OVER (
      PARTITION BY o.id
      ORDER BY COALESCE(oi.created_at, o.ordered_at), oi.id
    ) AS line_sequence,
    o.order_number,
    o.status AS order_status,
    COALESCE(o.channel, 'in_store') AS channel,
    o.table_number AS table_no,
    oi.menu_item_id,
    mi.external_code AS menu_item_code,
    mi.name AS menu_item_name,
    mi.category_id AS menu_category_id,
    mc.name AS menu_category_name,
    oi.quantity::numeric(12, 3) AS qty,
    oi.unit_price::numeric(12, 2) AS unit_price,
    oi.subtotal::numeric(12, 2) AS line_subtotal,
    SUM(oi.subtotal::numeric(12, 2)) OVER (PARTITION BY o.id) AS order_line_subtotal,
    COALESCE(o.discount_amount, 0)::numeric(12, 2) AS order_discount_amount,
    COALESCE(mi.tax_rate, 0)::numeric(5, 2) AS tax_rate,
    o.ordered_at,
    o.completed_at AS served_at,
    o.user_id AS ordered_by,
    oi.special_request,
    oi.selected_options AS options_json
  FROM public.orders o
  JOIN public.order_items oi ON oi.order_id = o.id
  LEFT JOIN public.menu_items mi ON mi.id = oi.menu_item_id
  LEFT JOIN public.menu_categories mc ON mc.id = mi.category_id
  WHERE COALESCE(o.is_cart, false) = false
)
SELECT
  lb.org_id,
  lb.location_id,
  lb.business_date,
  lb.order_id,
  lb.line_id,
  lb.line_sequence,
  lb.order_number,
  lb.order_status,
  lb.channel,
  lb.table_no,
  lb.menu_item_id,
  lb.menu_item_code,
  lb.menu_item_name,
  lb.menu_category_id,
  lb.menu_category_name,
  lb.qty,
  lb.unit_price,
  lb.line_subtotal,
  disc.discount_amount,
  lb.tax_rate,
  CASE
    WHEN lb.tax_rate = 0 THEN 0::numeric(12, 2)
    ELSE ROUND(disc.taxable_amount * (lb.tax_rate / 100.0), 2)
  END AS tax_amount,
  disc.taxable_amount
    + CASE
        WHEN lb.tax_rate = 0 THEN 0::numeric(12, 2)
        ELSE ROUND(disc.taxable_amount * (lb.tax_rate / 100.0), 2)
      END AS line_total,
  lb.ordered_at,
  lb.served_at,
  (lb.order_status = 'cancelled') AS canceled_flag,
  NULL::text AS void_reason,
  lb.special_request,
  lb.options_json,
  lb.ordered_by,
  NULL::timestamptz AS exported_at,
  NULL::uuid AS export_job_id
FROM line_base lb
CROSS JOIN LATERAL (
  SELECT
    CASE
      WHEN lb.order_line_subtotal IS NULL OR lb.order_line_subtotal = 0 THEN 0::numeric(12, 2)
      ELSE ROUND((lb.line_subtotal / lb.order_line_subtotal) * lb.order_discount_amount, 2)
    END AS discount_amount,
    lb.line_subtotal
      - CASE
          WHEN lb.order_line_subtotal IS NULL OR lb.order_line_subtotal = 0 THEN 0::numeric(12, 2)
          ELSE ROUND((lb.line_subtotal / lb.order_line_subtotal) * lb.order_discount_amount, 2)
        END AS taxable_amount
) AS disc;

CREATE OR REPLACE VIEW analytics.purchases_line_items_view AS
WITH item_base AS (
  SELECT
    p.org_id,
    p.location_id,
    p.id AS purchase_id,
    pi.id AS line_id,
    ROW_NUMBER() OVER (
      PARTITION BY p.id
      ORDER BY COALESCE(pi.created_at, p.purchase_date), pi.id
    ) AS line_sequence,
    p.purchase_date,
    p.supplier_id,
    s.name AS supplier_name,
    p.po_number,
    pi.material_id AS sku_id,
    mat.external_code AS sku_code,
    mat.name AS sku_name,
    mat.unit_type AS unit_of_measure,
    COALESCE(pi.conversion_ratio, 1)::numeric(12, 3) AS conversion_ratio,
    pi.quantity::numeric(12, 3) AS qty,
    (COALESCE(pi.quantity, 0)::numeric(12, 3) * COALESCE(pi.conversion_ratio, 1)::numeric(12, 3)) AS stock_qty,
    pi.unit_cost::numeric(12, 2) AS unit_cost,
    ROUND(COALESCE(pi.quantity::numeric(12, 3), 0) * COALESCE(pi.unit_cost::numeric(12, 2), 0), 2) AS ext_cost,
    COALESCE(pi.tax_amount, 0)::numeric(12, 2) AS tax_amount,
    COALESCE(p.tax_rate, 0)::numeric(5, 2) AS tax_rate,
    COALESCE(p.currency, 'JPY') AS currency,
    pi.batch_no,
    pi.expiry_date,
    p.received_by,
    pi.notes AS line_notes
  FROM public.purchases p
  JOIN public.purchase_items pi ON pi.purchase_id = p.id
  LEFT JOIN public.suppliers s ON s.id = p.supplier_id
  LEFT JOIN public.materials mat ON mat.id = pi.material_id
)
SELECT
  ib.org_id,
  ib.location_id,
  ib.purchase_id,
  ib.line_id,
  ib.line_sequence,
  ib.purchase_date,
  ib.supplier_id,
  ib.supplier_name,
  ib.po_number,
  ib.sku_id,
  ib.sku_code,
  ib.sku_name,
  ib.unit_of_measure,
  ib.conversion_ratio,
  ib.qty,
  ib.stock_qty,
  ib.unit_cost,
  ib.ext_cost,
  ib.tax_amount,
  ib.tax_rate,
  ib.currency,
  ib.batch_no,
  ib.expiry_date,
  ib.received_by,
  ib.line_notes AS notes,
  NULL::timestamptz AS exported_at,
  NULL::uuid AS export_job_id
FROM item_base ib;

CREATE OR REPLACE VIEW analytics.inventory_movements_view AS
SELECT
  st.org_id,
  st.location_id,
  st.id AS tx_id,
  st.created_at AS tx_time,
  (timezone('Asia/Tokyo', st.created_at))::date AS business_date,
  st.transaction_type AS tx_type,
  st.reference_type AS ref_type,
  st.reference_id AS ref_id,
  st.material_id AS sku_id,
  mat.name AS sku_name,
  mat.unit_type AS unit_of_measure,
  st.change_amount::numeric(12, 3) AS quantity_delta,
  SUM(st.change_amount::numeric(12, 3)) OVER (
    PARTITION BY st.org_id, st.location_id, st.material_id
    ORDER BY st.created_at, st.id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS quantity_after,
  st.reason AS reason_code,
  st.notes,
  st.user_id AS performed_by,
  st.lot_no,
  NULL::timestamptz AS exported_at,
  NULL::uuid AS export_job_id
FROM public.stock_transactions st
LEFT JOIN public.materials mat ON mat.id = st.material_id;

CREATE OR REPLACE VIEW analytics.waste_log_view AS
SELECT
  st.org_id,
  st.location_id,
  st.id AS waste_id,
  st.created_at AS waste_time,
  (timezone('Asia/Tokyo', st.created_at))::date AS business_date,
  st.material_id AS sku_id,
  mat.name AS sku_name,
  mat.unit_type AS unit_of_measure,
  abs(st.change_amount)::numeric(12, 3) AS qty,
  COALESCE(mat.last_purchase_unit_cost, 0)::numeric(12, 2) AS unit_cost,
  ROUND(abs(st.change_amount::numeric(12, 3)) * COALESCE(mat.last_purchase_unit_cost::numeric(12, 2), 0), 2) AS waste_cost,
  st.reason AS reason,
  st.lot_no,
  st.user_id AS recorded_by,
  st.notes,
  NULL::uuid AS linked_order_id,
  NULL::timestamptz AS exported_at,
  NULL::uuid AS export_job_id
FROM public.stock_transactions st
LEFT JOIN public.materials mat ON mat.id = st.material_id
WHERE st.transaction_type = 'waste';

CREATE OR REPLACE VIEW analytics.menu_engineering_daily_view AS
WITH sales AS (
  SELECT
    s.org_id,
    s.location_id,
    s.business_date,
    s.menu_item_id,
    s.menu_item_code,
    s.menu_item_name,
    s.menu_category_id,
    s.menu_category_name,
    SUM(s.qty)::numeric(12, 3) AS sales_qty,
    SUM(s.line_total)::numeric(12, 2) AS sales_amount
  FROM analytics.sales_line_items_view s
  GROUP BY s.org_id, s.location_id, s.business_date, s.menu_item_id,
           s.menu_item_code, s.menu_item_name, s.menu_category_id, s.menu_category_name
),
recipe_cost AS (
  SELECT
    r.menu_item_id,
    SUM(
      COALESCE(mat.last_purchase_unit_cost, 0)::numeric(12, 4)
      * COALESCE(r.required_amount, 0)::numeric(12, 4)
      / NULLIF(COALESCE(r.yield_rate, 1)::numeric(12, 4), 0)
    ) AS recipe_unit_cost
  FROM public.recipes r
  LEFT JOIN public.materials mat ON mat.id = r.material_id
  GROUP BY r.menu_item_id
),
merged AS (
  SELECT
    sa.*,
    COALESCE(rc.recipe_unit_cost, 0)::numeric(12, 4) AS recipe_unit_cost
  FROM sales sa
  LEFT JOIN recipe_cost rc ON rc.menu_item_id = sa.menu_item_id
),
totals AS (
  SELECT
    org_id,
    location_id,
    business_date,
    SUM(sales_qty)::numeric(12, 3) AS total_qty
  FROM merged
  GROUP BY org_id, location_id, business_date
)
SELECT
  m.org_id,
  m.location_id,
  m.business_date,
  m.menu_item_id,
  m.menu_item_code,
  m.menu_item_name,
  m.menu_category_id,
  m.menu_category_name,
  m.sales_qty,
  m.sales_amount,
  CASE
    WHEN m.sales_qty = 0 THEN NULL
    ELSE ROUND(m.sales_amount / m.sales_qty, 2)
  END AS avg_price,
  ROUND(m.recipe_unit_cost * m.sales_qty, 2) AS food_cost,
  ROUND(m.recipe_unit_cost, 4) AS recipe_unit_cost,
  ROUND(m.sales_amount - (m.recipe_unit_cost * m.sales_qty), 2) AS contribution_margin,
  CASE
    WHEN m.sales_amount = 0 THEN NULL
    ELSE ROUND((m.sales_amount - (m.recipe_unit_cost * m.sales_qty)) / m.sales_amount, 4)
  END AS cm_rate,
  CASE
    WHEN t.total_qty = 0 THEN NULL
    ELSE ROUND(m.sales_qty / t.total_qty, 4)
  END AS share_qty,
  CASE
    WHEN t.total_qty = 0 OR m.sales_amount = 0 THEN 'questionable'
    WHEN (m.sales_qty / t.total_qty) >= 0.05
         AND (m.sales_amount - (m.recipe_unit_cost * m.sales_qty)) / NULLIF(m.sales_amount, 0) >= 0.7 THEN 'star'
    WHEN (m.sales_qty / t.total_qty) >= 0.05 THEN 'plowhorse'
    WHEN (m.sales_amount - (m.recipe_unit_cost * m.sales_qty)) / NULLIF(m.sales_amount, 0) >= 0.7 THEN 'puzzle'
    ELSE 'dog'
  END AS popularity_quadrant,
  NULL::numeric(12, 3) AS waste_qty,
  NULL::timestamptz AS exported_at,
  NULL::uuid AS export_job_id
FROM merged m
JOIN totals t
  ON t.org_id = m.org_id
 AND t.location_id = m.location_id
 AND t.business_date = m.business_date;

-- Dataset-specific CSV generators ------------------------------------------

CREATE OR REPLACE FUNCTION analytics.generate_sales_line_items_csv(
  p_org_id uuid,
  p_location_id uuid,
  p_date_from date,
  p_date_to date,
  p_include_headers boolean,
  p_time_zone text
) RETURNS TABLE (
  csv text,
  row_count integer,
  default_file_name text,
  metadata jsonb
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_header text := analytics.csv_line(ARRAY[
    'org_id','location_id','business_date','order_id','line_id','line_sequence','order_number','order_status',
    'channel','table_no','menu_item_id','menu_item_code','menu_item_name','menu_category_id','menu_category_name',
    'qty','unit_price','line_subtotal','discount_amount','tax_rate','tax_amount','line_total','ordered_at',
    'served_at','canceled_flag','void_reason','special_request','options_json','ordered_by','exported_at','export_job_id'
  ]);
  v_body text;
  v_pii jsonb;
BEGIN
  SELECT
    COALESCE(
      string_agg(
        analytics.csv_line(ARRAY[
          COALESCE(org_id::text, ''),
          COALESCE(location_id::text, ''),
          to_char(business_date, 'YYYY-MM-DD'),
          COALESCE(order_id::text, ''),
          COALESCE(line_id::text, ''),
          COALESCE(line_sequence::text, ''),
          COALESCE(order_number, ''),
          COALESCE(order_status, ''),
          COALESCE(channel, ''),
          COALESCE(table_no, ''),
          COALESCE(menu_item_id::text, ''),
          COALESCE(menu_item_code, ''),
          COALESCE(menu_item_name, ''),
          COALESCE(menu_category_id::text, ''),
          COALESCE(menu_category_name, ''),
          analytics.format_numeric(qty, 3),
          analytics.format_numeric(unit_price, 2),
          analytics.format_numeric(line_subtotal, 2),
          analytics.format_numeric(discount_amount, 2),
          analytics.format_numeric(tax_rate, 2),
          analytics.format_numeric(tax_amount, 2),
          analytics.format_numeric(line_total, 2),
          analytics.format_timestamp_tz(ordered_at, p_time_zone),
          analytics.format_timestamp_tz(served_at, p_time_zone),
          CASE WHEN canceled_flag THEN 'true' ELSE 'false' END,
          COALESCE(void_reason, ''),
          COALESCE(special_request, ''),
          COALESCE(options_json::text, ''),
          COALESCE(ordered_by::text, ''),
          analytics.format_timestamp_tz(exported_at, p_time_zone),
          COALESCE(export_job_id::text, '')
        ]),
        E'\n'
        ORDER BY business_date, ordered_at, line_sequence
      ),
      ''
    ),
    COUNT(*)
  INTO v_body, row_count
  FROM analytics.sales_line_items_view
  WHERE business_date BETWEEN p_date_from AND p_date_to
    AND (p_org_id IS NULL OR org_id = p_org_id)
    AND (p_location_id IS NULL OR location_id = p_location_id);

  IF p_include_headers THEN
    csv := v_header || CASE WHEN v_body = '' THEN '' ELSE E'\n' || v_body END;
  ELSE
    csv := v_body;
  END IF;

  v_pii := analytics.detect_pii_patterns(v_body);

  default_file_name := format(
    'sales_line_items_%s_%s%s.csv',
    to_char(p_date_from, 'YYYYMMDD'),
    to_char(p_date_to, 'YYYYMMDD'),
    CASE WHEN p_location_id IS NULL THEN '_all_locations' ELSE '_' || p_location_id::text END
  );

  metadata := jsonb_build_object(
    'dataset_id', 'sales_line_items',
    'date_from', p_date_from,
    'date_to', p_date_to,
    'location_id', p_location_id,
    'time_zone', p_time_zone
  ) || jsonb_build_object(
    'encryption_required', COALESCE((v_pii->>'encryption_required')::boolean, false),
    'encryption_reasons', COALESCE(v_pii->'detected_rules', '[]'::jsonb),
    'pii_scan', v_pii
  );

  RETURN NEXT;
END;
$$;

CREATE OR REPLACE FUNCTION analytics.generate_purchases_line_items_csv(
  p_org_id uuid,
  p_location_id uuid,
  p_date_from date,
  p_date_to date,
  p_include_headers boolean,
  p_time_zone text
) RETURNS TABLE (
  csv text,
  row_count integer,
  default_file_name text,
  metadata jsonb
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_header text := analytics.csv_line(ARRAY[
    'org_id','location_id','purchase_id','line_id','line_sequence','purchase_date','supplier_id','supplier_name',
    'po_number','sku_id','sku_code','sku_name','unit_of_measure','conversion_ratio','qty','stock_qty',
    'unit_cost','ext_cost','tax_amount','tax_rate','currency','batch_no','expiry_date','received_by','notes',
    'exported_at','export_job_id'
  ]);
  v_body text;
  v_pii jsonb;
BEGIN
  SELECT
    COALESCE(
      string_agg(
        analytics.csv_line(ARRAY[
          COALESCE(org_id::text, ''),
          COALESCE(location_id::text, ''),
          COALESCE(purchase_id::text, ''),
          COALESCE(line_id::text, ''),
          COALESCE(line_sequence::text, ''),
          to_char(purchase_date, 'YYYY-MM-DD'),
          COALESCE(supplier_id::text, ''),
          COALESCE(supplier_name, ''),
          COALESCE(po_number, ''),
          COALESCE(sku_id::text, ''),
          COALESCE(sku_code, ''),
          COALESCE(sku_name, ''),
          COALESCE(unit_of_measure, ''),
          analytics.format_numeric(conversion_ratio, 3),
          analytics.format_numeric(qty, 3),
          analytics.format_numeric(stock_qty, 3),
          analytics.format_numeric(unit_cost, 2),
          analytics.format_numeric(ext_cost, 2),
          analytics.format_numeric(tax_amount, 2),
          analytics.format_numeric(tax_rate, 2),
          COALESCE(currency, ''),
          COALESCE(batch_no, ''),
          COALESCE(to_char(expiry_date, 'YYYY-MM-DD'), ''),
          COALESCE(received_by::text, ''),
          COALESCE(notes, ''),
          analytics.format_timestamp_tz(exported_at, p_time_zone),
          COALESCE(export_job_id::text, '')
        ]),
        E'\n'
        ORDER BY purchase_date, purchase_id, line_sequence
      ),
      ''
    ),
    COUNT(*)
  INTO v_body, row_count
  FROM analytics.purchases_line_items_view
  WHERE purchase_date BETWEEN p_date_from AND p_date_to
    AND (p_org_id IS NULL OR org_id = p_org_id)
    AND (p_location_id IS NULL OR location_id = p_location_id);

  IF p_include_headers THEN
    csv := v_header || CASE WHEN v_body = '' THEN '' ELSE E'\n' || v_body END;
  ELSE
    csv := v_body;
  END IF;

  v_pii := analytics.detect_pii_patterns(v_body);

  default_file_name := format(
    'purchases_line_items_%s_%s%s.csv',
    to_char(p_date_from, 'YYYYMMDD'),
    to_char(p_date_to, 'YYYYMMDD'),
    CASE WHEN p_location_id IS NULL THEN '_all_locations' ELSE '_' || p_location_id::text END
  );

  metadata := jsonb_build_object(
    'dataset_id', 'purchases_line_items',
    'date_from', p_date_from,
    'date_to', p_date_to,
    'location_id', p_location_id,
    'time_zone', p_time_zone
  ) || jsonb_build_object(
    'encryption_required', COALESCE((v_pii->>'encryption_required')::boolean, false),
    'encryption_reasons', COALESCE(v_pii->'detected_rules', '[]'::jsonb),
    'pii_scan', v_pii
  );

  RETURN NEXT;
END;
$$;

CREATE OR REPLACE FUNCTION analytics.generate_inventory_movements_csv(
  p_org_id uuid,
  p_location_id uuid,
  p_date_from date,
  p_date_to date,
  p_include_headers boolean,
  p_time_zone text
) RETURNS TABLE (
  csv text,
  row_count integer,
  default_file_name text,
  metadata jsonb
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_header text := analytics.csv_line(ARRAY[
    'org_id','location_id','tx_id','tx_time','business_date','tx_type','ref_type','ref_id','sku_id','sku_name',
    'unit_of_measure','quantity_delta','quantity_after','reason_code','notes','performed_by','lot_no',
    'exported_at','export_job_id'
  ]);
  v_body text;
  v_pii jsonb;
BEGIN
  SELECT
    COALESCE(
      string_agg(
        analytics.csv_line(ARRAY[
          COALESCE(org_id::text, ''),
          COALESCE(location_id::text, ''),
          COALESCE(tx_id::text, ''),
          analytics.format_timestamp_tz(tx_time, p_time_zone),
          to_char(business_date, 'YYYY-MM-DD'),
          COALESCE(tx_type, ''),
          COALESCE(ref_type, ''),
          COALESCE(ref_id::text, ''),
          COALESCE(sku_id::text, ''),
          COALESCE(sku_name, ''),
          COALESCE(unit_of_measure, ''),
          analytics.format_numeric(quantity_delta, 3),
          analytics.format_numeric(quantity_after, 3),
          COALESCE(reason_code, ''),
          COALESCE(notes, ''),
          COALESCE(performed_by::text, ''),
          COALESCE(lot_no, ''),
          analytics.format_timestamp_tz(exported_at, p_time_zone),
          COALESCE(export_job_id::text, '')
        ]),
        E'\n'
        ORDER BY tx_time, tx_id
      ),
      ''
    ),
    COUNT(*)
  INTO v_body, row_count
  FROM analytics.inventory_movements_view
  WHERE business_date BETWEEN p_date_from AND p_date_to
    AND (p_org_id IS NULL OR org_id = p_org_id)
    AND (p_location_id IS NULL OR location_id = p_location_id);

  IF p_include_headers THEN
    csv := v_header || CASE WHEN v_body = '' THEN '' ELSE E'\n' || v_body END;
  ELSE
    csv := v_body;
  END IF;

  v_pii := analytics.detect_pii_patterns(v_body);

  default_file_name := format(
    'inventory_transactions_%s_%s%s.csv',
    to_char(p_date_from, 'YYYYMMDD'),
    to_char(p_date_to, 'YYYYMMDD'),
    CASE WHEN p_location_id IS NULL THEN '_all_locations' ELSE '_' || p_location_id::text END
  );

  metadata := jsonb_build_object(
    'dataset_id', 'inventory_transactions',
    'date_from', p_date_from,
    'date_to', p_date_to,
    'location_id', p_location_id,
    'time_zone', p_time_zone
  ) || jsonb_build_object(
    'encryption_required', COALESCE((v_pii->>'encryption_required')::boolean, false),
    'encryption_reasons', COALESCE(v_pii->'detected_rules', '[]'::jsonb),
    'pii_scan', v_pii
  );

  RETURN NEXT;
END;
$$;

CREATE OR REPLACE FUNCTION analytics.generate_waste_log_csv(
  p_org_id uuid,
  p_location_id uuid,
  p_date_from date,
  p_date_to date,
  p_include_headers boolean,
  p_time_zone text
) RETURNS TABLE (
  csv text,
  row_count integer,
  default_file_name text,
  metadata jsonb
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_header text := analytics.csv_line(ARRAY[
    'org_id','location_id','waste_id','waste_time','business_date','sku_id','sku_name','unit_of_measure','qty',
    'unit_cost','waste_cost','reason','lot_no','recorded_by','notes','linked_order_id','exported_at','export_job_id'
  ]);
  v_body text;
  v_pii jsonb;
BEGIN
  SELECT
    COALESCE(
      string_agg(
        analytics.csv_line(ARRAY[
          COALESCE(org_id::text, ''),
          COALESCE(location_id::text, ''),
          COALESCE(waste_id::text, ''),
          analytics.format_timestamp_tz(waste_time, p_time_zone),
          to_char(business_date, 'YYYY-MM-DD'),
          COALESCE(sku_id::text, ''),
          COALESCE(sku_name, ''),
          COALESCE(unit_of_measure, ''),
          analytics.format_numeric(qty, 3),
          analytics.format_numeric(unit_cost, 2),
          analytics.format_numeric(waste_cost, 2),
          COALESCE(reason, ''),
          COALESCE(lot_no, ''),
          COALESCE(recorded_by::text, ''),
          COALESCE(notes, ''),
          COALESCE(linked_order_id::text, ''),
          analytics.format_timestamp_tz(exported_at, p_time_zone),
          COALESCE(export_job_id::text, '')
        ]),
        E'\n'
        ORDER BY waste_time, waste_id
      ),
      ''
    ),
    COUNT(*)
  INTO v_body, row_count
  FROM analytics.waste_log_view
  WHERE business_date BETWEEN p_date_from AND p_date_to
    AND (p_org_id IS NULL OR org_id = p_org_id)
    AND (p_location_id IS NULL OR location_id = p_location_id);

  IF p_include_headers THEN
    csv := v_header || CASE WHEN v_body = '' THEN '' ELSE E'\n' || v_body END;
  ELSE
    csv := v_body;
  END IF;

  v_pii := analytics.detect_pii_patterns(v_body);

  default_file_name := format(
    'waste_log_%s_%s%s.csv',
    to_char(p_date_from, 'YYYYMMDD'),
    to_char(p_date_to, 'YYYYMMDD'),
    CASE WHEN p_location_id IS NULL THEN '_all_locations' ELSE '_' || p_location_id::text END
  );

  metadata := jsonb_build_object(
    'dataset_id', 'waste_log',
    'date_from', p_date_from,
    'date_to', p_date_to,
    'location_id', p_location_id,
    'time_zone', p_time_zone
  ) || jsonb_build_object(
    'encryption_required', COALESCE((v_pii->>'encryption_required')::boolean, false),
    'encryption_reasons', COALESCE(v_pii->'detected_rules', '[]'::jsonb),
    'pii_scan', v_pii
  );

  RETURN NEXT;
END;
$$;

CREATE OR REPLACE FUNCTION analytics.generate_menu_engineering_daily_csv(
  p_org_id uuid,
  p_location_id uuid,
  p_date_from date,
  p_date_to date,
  p_include_headers boolean,
  p_time_zone text
) RETURNS TABLE (
  csv text,
  row_count integer,
  default_file_name text,
  metadata jsonb
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_header text := analytics.csv_line(ARRAY[
    'org_id','location_id','business_date','menu_item_id','menu_item_code','menu_item_name','menu_category_id',
    'menu_category_name','sales_qty','sales_amount','avg_price','food_cost','recipe_unit_cost','contribution_margin',
    'cm_rate','share_qty','popularity_quadrant','waste_qty','exported_at','export_job_id'
  ]);
  v_body text;
  v_pii jsonb;
BEGIN
  SELECT
    COALESCE(
      string_agg(
        analytics.csv_line(ARRAY[
          COALESCE(org_id::text, ''),
          COALESCE(location_id::text, ''),
          to_char(business_date, 'YYYY-MM-DD'),
          COALESCE(menu_item_id::text, ''),
          COALESCE(menu_item_code, ''),
          COALESCE(menu_item_name, ''),
          COALESCE(menu_category_id::text, ''),
          COALESCE(menu_category_name, ''),
          analytics.format_numeric(sales_qty, 3),
          analytics.format_numeric(sales_amount, 2),
          analytics.format_numeric(avg_price, 2),
          analytics.format_numeric(food_cost, 2),
          analytics.format_numeric(recipe_unit_cost, 4),
          analytics.format_numeric(contribution_margin, 2),
          analytics.format_numeric(cm_rate, 4),
          analytics.format_numeric(share_qty, 4),
          COALESCE(popularity_quadrant, ''),
          analytics.format_numeric(waste_qty, 3),
          analytics.format_timestamp_tz(exported_at, p_time_zone),
          COALESCE(export_job_id::text, '')
        ]),
        E'\n'
        ORDER BY business_date, menu_item_name
      ),
      ''
    ),
    COUNT(*)
  INTO v_body, row_count
  FROM analytics.menu_engineering_daily_view
  WHERE business_date BETWEEN p_date_from AND p_date_to
    AND (p_org_id IS NULL OR org_id = p_org_id)
    AND (p_location_id IS NULL OR location_id = p_location_id);

  IF p_include_headers THEN
    csv := v_header || CASE WHEN v_body = '' THEN '' ELSE E'\n' || v_body END;
  ELSE
    csv := v_body;
  END IF;

  v_pii := analytics.detect_pii_patterns(v_body);

  default_file_name := format(
    'menu_engineering_daily_%s_%s%s.csv',
    to_char(p_date_from, 'YYYYMMDD'),
    to_char(p_date_to, 'YYYYMMDD'),
    CASE WHEN p_location_id IS NULL THEN '_all_locations' ELSE '_' || p_location_id::text END
  );

  metadata := jsonb_build_object(
    'dataset_id', 'menu_engineering_daily',
    'date_from', p_date_from,
    'date_to', p_date_to,
    'location_id', p_location_id,
    'time_zone', p_time_zone
  ) || jsonb_build_object(
    'encryption_required', COALESCE((v_pii->>'encryption_required')::boolean, false),
    'encryption_reasons', COALESCE(v_pii->'detected_rules', '[]'::jsonb),
    'pii_scan', v_pii
  );

  RETURN NEXT;
END;
$$;

-- RPC entry point ----------------------------------------------------------

CREATE OR REPLACE FUNCTION analytics.fn_export_csv(
  p_dataset_id text,
  p_params jsonb
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_dataset text := lower(trim(p_dataset_id));
  v_date_from date := (p_params->>'date_from')::date;
  v_date_to date := (p_params->>'date_to')::date;
  v_include_headers boolean := COALESCE((p_params->>'include_headers')::boolean, true);
  v_time_zone text := COALESCE(p_params->>'time_zone', 'Asia/Tokyo');
  v_org_id uuid := NULLIF(p_params->>'org_id', '')::uuid;
  v_location_id uuid := NULLIF(p_params->>'location_id', '')::uuid;
  v_requested_by uuid := NULLIF(p_params->>'requested_by', '')::uuid;
  v_result record;
  v_job_id uuid;
  v_duration_ms integer;
  v_started_at timestamptz := clock_timestamp();
  v_metadata jsonb;
  v_encryption_required boolean;
  v_encryption_reasons jsonb;
BEGIN
  IF v_date_from IS NULL OR v_date_to IS NULL THEN
    RAISE EXCEPTION 'date_from and date_to are required' USING ERRCODE = '22023';
  END IF;

  IF v_date_to < v_date_from THEN
    RAISE EXCEPTION 'date_to must be greater than or equal to date_from' USING ERRCODE = '22023';
  END IF;

  IF (v_date_to - v_date_from) > 31 THEN
    RAISE EXCEPTION 'date range must be 31 days or less' USING ERRCODE = '22023';
  END IF;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'org_id is required for export' USING ERRCODE = '28000';
  END IF;

  CASE v_dataset
    WHEN 'sales_line_items' THEN
      SELECT * INTO v_result
      FROM analytics.generate_sales_line_items_csv(
        v_org_id, v_location_id, v_date_from, v_date_to, v_include_headers, v_time_zone
      );
    WHEN 'purchases_line_items' THEN
      SELECT * INTO v_result
      FROM analytics.generate_purchases_line_items_csv(
        v_org_id, v_location_id, v_date_from, v_date_to, v_include_headers, v_time_zone
      );
    WHEN 'inventory_transactions', 'inventory_movements' THEN
      SELECT * INTO v_result
      FROM analytics.generate_inventory_movements_csv(
        v_org_id, v_location_id, v_date_from, v_date_to, v_include_headers, v_time_zone
      );
    WHEN 'waste_log' THEN
      SELECT * INTO v_result
      FROM analytics.generate_waste_log_csv(
        v_org_id, v_location_id, v_date_from, v_date_to, v_include_headers, v_time_zone
      );
    WHEN 'menu_engineering_daily', 'menu_sales_daily' THEN
      SELECT * INTO v_result
      FROM analytics.generate_menu_engineering_daily_csv(
        v_org_id, v_location_id, v_date_from, v_date_to, v_include_headers, v_time_zone
      );
    ELSE
      RAISE EXCEPTION 'dataset % is not supported', p_dataset_id USING ERRCODE = '22023';
  END CASE;

  v_duration_ms := (EXTRACT(EPOCH FROM clock_timestamp() - v_started_at) * 1000)::integer;

  INSERT INTO public.export_jobs (
    org_id,
    location_id,
    dataset_id,
    status,
    requested_by,
    period_from,
    period_to,
    row_count,
    duration_ms,
    metadata,
    file_name,
    logged_at
  )
  VALUES (
    v_org_id,
    v_location_id,
    v_dataset,
    'completed',
    v_requested_by,
    v_date_from::timestamptz,
    v_date_to::timestamptz,
    v_result.row_count,
    v_duration_ms,
    v_result.metadata,
    v_result.default_file_name,
    clock_timestamp()
  )
  RETURNING id INTO v_job_id;

  v_metadata := COALESCE(v_result.metadata, '{}'::jsonb)
    || jsonb_build_object('duration_ms', v_duration_ms, 'export_job_id', v_job_id);

  v_encryption_required := COALESCE((v_metadata->>'encryption_required')::boolean, false);
  v_encryption_reasons := COALESCE(v_metadata->'encryption_reasons', '[]'::jsonb);

  -- Prepend the Unicode BOM (Byte Order Mark) to the CSV output to ensure UTF-8 encoding is recognized
  -- by applications such as Microsoft Excel, which may otherwise misinterpret the file encoding.
  RETURN jsonb_build_object(
    'csv', E'\uFEFF' || COALESCE(v_result.csv, ''),
    'file_name', v_result.default_file_name,
    'content_type', 'text/csv; charset=UTF-8',
    'row_count', v_result.row_count,
    'export_job_id', v_job_id,
    'metadata', v_metadata,
    'encryption_required', v_encryption_required,
    'encryption_reasons', v_encryption_reasons
  );
END;
$$;

COMMIT;
