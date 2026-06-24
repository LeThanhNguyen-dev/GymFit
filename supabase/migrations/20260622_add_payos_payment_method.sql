-- Add payOS as an online payment method.
-- This works for projects that use either TEXT columns or the payment_method_type enum.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'payment_method_type'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'payment_method_type'
      AND e.enumlabel = 'payos'
  ) THEN
    ALTER TYPE payment_method_type ADD VALUE 'payos';
  END IF;
END $$;
