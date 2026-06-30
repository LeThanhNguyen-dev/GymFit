-- Re-enable RLS on e-commerce tables (was disabled by hotfix for dev)
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipping_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_registrations ENABLE ROW LEVEL SECURITY;

-- Update voucher payment methods: remove momo (not used in UI anymore)
ALTER TABLE public.vouchers DROP CONSTRAINT IF EXISTS vouchers_payment_method_check;
ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_method_check;

-- Store orders RPC: add seller order items access
DROP POLICY IF EXISTS "Sellers can read order payments" ON public.payments;
CREATE POLICY "Sellers can read order payments"
  ON public.payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.order_items
      WHERE order_items.order_id = payments.order_id
        AND order_items.seller_id = auth.uid()
    )
  );

-- Ensure store owners can read shop_registrations for their own shop
DROP POLICY IF EXISTS "Store owners can view own registration" ON public.shop_registrations;
CREATE POLICY "Store owners can view own registration"
  ON public.shop_registrations FOR SELECT
  USING (user_id = auth.uid());

-- Add missing order_items policy for sellers (existing one might be incomplete)
DROP POLICY IF EXISTS "Sellers can read own order items" ON public.order_items;
CREATE POLICY "Sellers can read own order items"
  ON public.order_items FOR SELECT
  USING (seller_id = auth.uid());

DROP POLICY IF EXISTS "Sellers can update own order item status" ON public.order_items;
CREATE POLICY "Sellers can update own order item status"
  ON public.order_items FOR UPDATE
  USING (seller_id = auth.uid())
  WITH CHECK (seller_id = auth.uid());
