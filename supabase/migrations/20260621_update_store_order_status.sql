-- RPC for store owners to update order status

CREATE OR REPLACE FUNCTION public.update_store_order_status(
  p_order_id UUID,
  p_seller_id UUID,
  p_status TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_has_access BOOLEAN;
BEGIN
  -- Verify the seller has items in this order
  SELECT EXISTS (
    SELECT 1
    FROM public.order_items oi
    JOIN public.products p ON oi.product_id = p.id
    WHERE oi.order_id = p_order_id AND p.seller_id = p_seller_id
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    RAISE EXCEPTION 'Unauthorized to update this order';
  END IF;

  -- Update order status
  UPDATE public.orders
  SET status = p_status::order_status_type, updated_at = NOW()
  WHERE id = p_order_id;

  -- Insert history
  INSERT INTO public.order_status_history (
    order_id,
    from_status,
    to_status,
    changed_by,
    note
  )
  VALUES (
    p_order_id,
    (SELECT status FROM public.orders WHERE id = p_order_id),
    p_status::order_status_type,
    p_seller_id,
    'Store owner updated status'
  );
END;
$$;
