-- Switch default payment method to PayPay and update existing data.
-- Generated 2025-10-09 based on order payment method migration plan.

BEGIN;

-- 1. Update existing order records that still use the legacy "card" value.
UPDATE public.orders
SET payment_method = 'paypay'
WHERE payment_method = 'card';

-- 2. Refresh the check constraint so that only the new set of allowed values remains.
ALTER TABLE public.orders
  DROP CONSTRAINT IF EXISTS orders_payment_method_check,
  ADD CONSTRAINT orders_payment_method_check
    CHECK (payment_method IN ('cash', 'paypay', 'other'));

COMMIT;

-- Down Migration -----------------------------------------------------------
-- To revert this change, execute the following statements manually:
--
-- BEGIN;
-- UPDATE public.orders
-- SET payment_method = 'card'
-- WHERE payment_method = 'paypay';
--
-- ALTER TABLE public.orders
--   DROP CONSTRAINT IF EXISTS orders_payment_method_check,
--   ADD CONSTRAINT orders_payment_method_check
--     CHECK (payment_method IN ('cash', 'card', 'other'));
-- COMMIT;
