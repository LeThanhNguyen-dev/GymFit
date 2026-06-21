-- RPC to get daily revenue for the last 7 days for a store owner
CREATE OR REPLACE FUNCTION public.get_store_daily_revenue(p_seller_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  WITH dates AS (
    SELECT generate_series(
      date_trunc('day', NOW()) - INTERVAL '6 days',
      date_trunc('day', NOW()),
      INTERVAL '1 day'
    ) AS day
  ),
  daily_revenue AS (
    SELECT 
      date_trunc('day', o.created_at) AS day,
      COALESCE(SUM(oi.total_price), 0) AS revenue
    FROM public.orders o
    JOIN public.order_items oi ON o.id = oi.order_id
    JOIN public.products p ON oi.product_id = p.id
    WHERE p.seller_id = p_seller_id 
      AND o.status != 'cancelled'
      AND o.created_at >= date_trunc('day', NOW()) - INTERVAL '6 days'
    GROUP BY date_trunc('day', o.created_at)
  )
  SELECT COALESCE(jsonb_agg(COALESCE(dr.revenue, 0) ORDER BY d.day ASC), '[]'::jsonb) INTO v_result
  FROM dates d
  LEFT JOIN daily_revenue dr ON d.day = dr.day;

  RETURN v_result;
END;
$$;
