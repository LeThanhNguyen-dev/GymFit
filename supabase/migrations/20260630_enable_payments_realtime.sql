-- Enable Supabase Realtime for high-value customer-facing updates.
-- - payments: auto-update payOS screens after webhook updates.
-- - product_variants: refresh stock/variant changes on product detail.
-- - reviews: refresh product reviews and rating summary.

CREATE OR REPLACE FUNCTION public.add_table_to_realtime_publication(
  p_table_name TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = p_table_name
  ) THEN
    EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', p_table_name);
  END IF;
END;
$$;

SELECT public.add_table_to_realtime_publication('payments');
SELECT public.add_table_to_realtime_publication('product_variants');
SELECT public.add_table_to_realtime_publication('reviews');

DROP FUNCTION public.add_table_to_realtime_publication(TEXT);
