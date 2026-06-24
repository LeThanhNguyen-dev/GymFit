-- Hotfix: Recreate functions with proper order_status_type casts
-- Tắt RLS trên các table e-commerce để dev
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.vouchers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipping_tracking DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_registrations DISABLE ROW LEVEL SECURITY;

-- Fix 1: create_checkout_order_v2 — thêm ::order_status_type cho order_status_history INSERT
CREATE OR REPLACE FUNCTION public.create_checkout_order_v2(
  p_user_id UUID,
  p_address JSONB,
  p_items JSONB,
  p_admin_voucher_id UUID DEFAULT NULL,
  p_shop_voucher_id UUID DEFAULT NULL,
  p_shipping_fee NUMERIC DEFAULT 0,
  p_payment_method TEXT DEFAULT 'cod',
  p_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_uid UUID := auth.uid();
  v_order_id UUID;
  v_payment_id UUID;
  v_order_number TEXT := 'GF' || RIGHT((EXTRACT(EPOCH FROM clock_timestamp()) * 1000)::BIGINT::TEXT, 10);
  v_item JSONB;
  v_variant_id UUID;
  v_cart_item_id UUID;
  v_product_id UUID;
  v_seller_id UUID;
  v_quantity INT;
  v_unit_price NUMERIC;
  v_current_stock INT;
  v_product_name TEXT;
  v_variant_name TEXT;
  v_sku TEXT;
  v_image_url TEXT;
  v_line_total NUMERIC;
  v_subtotal NUMERIC := 0;
  v_admin_discount NUMERIC := 0;
  v_shop_discount NUMERIC := 0;
  v_discount_amount NUMERIC := 0;
  v_shipping_fee NUMERIC := 0;
  v_total_amount NUMERIC := 0;
  v_admin_voucher public.vouchers%ROWTYPE;
  v_shop_voucher public.vouchers%ROWTYPE;
  v_shop_subtotal NUMERIC := 0;
  v_cart_item_ids UUID[] := ARRAY[]::UUID[];
BEGIN
  IF v_auth_uid IS NULL OR v_auth_uid <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized checkout request';
  END IF;
  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Checkout items cannot be empty';
  END IF;
  IF p_payment_method NOT IN ('cod', 'momo', 'payos') THEN
    RAISE EXCEPTION 'Unsupported payment method %', p_payment_method;
  END IF;
  IF p_admin_voucher_id IS NOT NULL THEN
    SELECT * INTO v_admin_voucher FROM public.vouchers WHERE id = p_admin_voucher_id FOR UPDATE;
    IF v_admin_voucher.id IS NULL OR v_admin_voucher.scope <> 'admin' OR NOT v_admin_voucher.is_active
      OR NOW() < v_admin_voucher.start_date OR NOW() > v_admin_voucher.end_date
      OR (v_admin_voucher.usage_limit IS NOT NULL AND v_admin_voucher.used_count >= v_admin_voucher.usage_limit)
    THEN RAISE EXCEPTION 'Admin voucher is not available'; END IF;
  END IF;
  IF p_shop_voucher_id IS NOT NULL THEN
    SELECT * INTO v_shop_voucher FROM public.vouchers WHERE id = p_shop_voucher_id FOR UPDATE;
    IF v_shop_voucher.id IS NULL OR v_shop_voucher.scope <> 'shop' OR v_shop_voucher.seller_id IS NULL
      OR NOT v_shop_voucher.is_active OR NOW() < v_shop_voucher.start_date OR NOW() > v_shop_voucher.end_date
      OR (v_shop_voucher.usage_limit IS NOT NULL AND v_shop_voucher.used_count >= v_shop_voucher.usage_limit)
    THEN RAISE EXCEPTION 'Shop voucher is not available'; END IF;
  END IF;
  CREATE TEMP TABLE tmp_checkout_items (product_id UUID,variant_id UUID,seller_id UUID,product_name TEXT,variant_name TEXT,sku TEXT,image_url TEXT,unit_price NUMERIC,quantity INT,total_price NUMERIC) ON COMMIT DROP;
  FOR v_item IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    v_variant_id := (v_item->>'variant_id')::UUID;
    v_quantity := COALESCE((v_item->>'quantity')::INT, 1);
    IF v_quantity <= 0 THEN RAISE EXCEPTION 'Checkout quantity must be greater than 0'; END IF;
    SELECT pv.product_id, p.seller_id, COALESCE(pv.price, p.base_price, 0), COALESCE(pv.stock, pv.quantity, 0), p.name,
      COALESCE(NULLIF(pv.name, ''), NULLIF(pv.sku, '')), pv.sku,
      COALESCE(pv.image_url, (SELECT pi.url FROM public.product_images pi WHERE pi.product_id = p.id ORDER BY pi.is_primary DESC, pi.sort_order ASC, pi.created_at ASC LIMIT 1))
    INTO v_product_id, v_seller_id, v_unit_price, v_current_stock, v_product_name, v_variant_name, v_sku, v_image_url
    FROM public.product_variants pv JOIN public.products p ON p.id = pv.product_id
    WHERE pv.id = v_variant_id AND COALESCE(p.status::TEXT, 'active') IN ('active', 'out_of_stock') FOR UPDATE OF pv;
    IF v_product_id IS NULL THEN RAISE EXCEPTION 'Product variant % was not found', v_variant_id; END IF;
    IF v_current_stock < v_quantity THEN RAISE EXCEPTION 'Product % does not have enough stock', v_product_name; END IF;
    v_line_total := v_unit_price * v_quantity;
    v_subtotal := v_subtotal + v_line_total;
    IF v_shop_voucher.id IS NOT NULL AND v_shop_voucher.seller_id = v_seller_id THEN v_shop_subtotal := v_shop_subtotal + v_line_total; END IF;
    INSERT INTO tmp_checkout_items (product_id,variant_id,seller_id,product_name,variant_name,sku,image_url,unit_price,quantity,total_price)
    VALUES (v_product_id, v_variant_id, v_seller_id, COALESCE(v_product_name, 'San pham'), v_variant_name, v_sku, v_image_url, v_unit_price, v_quantity, v_line_total);
    UPDATE public.product_variants SET stock = v_current_stock - v_quantity, quantity = v_current_stock - v_quantity, updated_at = NOW() WHERE id = v_variant_id;
    v_cart_item_id := NULLIF(v_item->>'cart_item_id', '')::UUID;
    IF v_cart_item_id IS NOT NULL THEN v_cart_item_ids := array_append(v_cart_item_ids, v_cart_item_id); END IF;
  END LOOP;
  IF v_admin_voucher.id IS NOT NULL THEN
    IF v_subtotal < COALESCE(v_admin_voucher.min_order_amount, 0) THEN RAISE EXCEPTION 'Order amount does not meet admin voucher minimum'; END IF;
    v_admin_discount := CASE WHEN v_admin_voucher.discount_type = 'percentage' THEN v_subtotal * (v_admin_voucher.discount_value / 100) ELSE v_admin_voucher.discount_value END;
    IF v_admin_voucher.max_discount_amount IS NOT NULL THEN v_admin_discount := LEAST(v_admin_discount, v_admin_voucher.max_discount_amount); END IF;
  END IF;
  IF v_shop_voucher.id IS NOT NULL THEN
    IF v_shop_subtotal <= 0 THEN RAISE EXCEPTION 'Shop voucher does not match any checkout item'; END IF;
    IF v_shop_subtotal < COALESCE(v_shop_voucher.min_order_amount, 0) THEN RAISE EXCEPTION 'Shop amount does not meet voucher minimum'; END IF;
    v_shop_discount := CASE WHEN v_shop_voucher.discount_type = 'percentage' THEN v_shop_subtotal * (v_shop_voucher.discount_value / 100) ELSE v_shop_voucher.discount_value END;
    IF v_shop_voucher.max_discount_amount IS NOT NULL THEN v_shop_discount := LEAST(v_shop_discount, v_shop_voucher.max_discount_amount); END IF;
  END IF;
  v_discount_amount := LEAST(v_admin_discount + v_shop_discount, v_subtotal);
  v_shipping_fee := CASE WHEN LOWER(COALESCE(p_address->>'city', p_address->>'province', '')) LIKE '%ho chi minh%' OR LOWER(COALESCE(p_address->>'city', p_address->>'province', '')) LIKE '%hcm%' THEN 20000 ELSE 30000 END;
  v_total_amount := GREATEST(v_subtotal - v_discount_amount + v_shipping_fee, 0);
  INSERT INTO public.orders (order_number,user_id,status,shipping_full_name,shipping_phone,shipping_address1,shipping_address2,shipping_ward,shipping_district,shipping_city,shipping_province,shipping_country,shipping_postal_code,subtotal,discount_amount,shipping_fee,tax_amount,total_amount,voucher_id,voucher_code,customer_note)
  VALUES (v_order_number, p_user_id, 'pending'::order_status_type, p_address->>'full_name', p_address->>'phone', p_address->>'address_line1', p_address->>'address_line2', p_address->>'ward', p_address->>'district', p_address->>'city', p_address->>'province', COALESCE(p_address->>'country', 'VN'), p_address->>'postal_code', v_subtotal, v_discount_amount, v_shipping_fee, 0, v_total_amount, p_admin_voucher_id, v_admin_voucher.code, p_note)
  RETURNING id INTO v_order_id;
  INSERT INTO public.order_items (order_id,product_id,variant_id,seller_id,store_status,product_name,variant_name,sku,image_url,unit_price,quantity,discount_amount,total_price)
  SELECT v_order_id, product_id, variant_id, seller_id, 'pending', product_name, variant_name, sku, image_url, unit_price, quantity, 0, total_price FROM tmp_checkout_items;
  INSERT INTO public.order_status_history (order_id, from_status, to_status, changed_by, note)
  VALUES (v_order_id, NULL::order_status_type, 'pending'::order_status_type, p_user_id, 'Tao don hang');
  INSERT INTO public.payments (order_id, user_id, method, status, amount, currency, gateway)
  VALUES (v_order_id, p_user_id, p_payment_method::payment_method_type, 'pending'::payment_status_type, v_total_amount, 'VND', CASE WHEN p_payment_method = 'cod' THEN NULL ELSE p_payment_method END)
  RETURNING id INTO v_payment_id;
  IF v_admin_voucher.id IS NOT NULL THEN UPDATE public.vouchers SET used_count = COALESCE(used_count, 0) + 1, updated_at = NOW() WHERE id = v_admin_voucher.id; END IF;
  IF v_shop_voucher.id IS NOT NULL THEN UPDATE public.vouchers SET used_count = COALESCE(used_count, 0) + 1, updated_at = NOW() WHERE id = v_shop_voucher.id; END IF;
  IF array_length(v_cart_item_ids, 1) IS NOT NULL THEN DELETE FROM public.cart_items WHERE user_id = p_user_id AND id = ANY(v_cart_item_ids); END IF;
  RETURN jsonb_build_object('order_id', v_order_id, 'order_number', v_order_number, 'payment_id', v_payment_id, 'payment_method', p_payment_method, 'subtotal', v_subtotal, 'discount_amount', v_discount_amount, 'shipping_fee', v_shipping_fee, 'total_amount', v_total_amount);
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_checkout_order_v2(UUID,JSONB,JSONB,UUID,UUID,NUMERIC,TEXT,TEXT) TO authenticated;

-- Fix 2: update_store_order_status — thêm ::order_status_type cho order_status_history INSERT
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
  v_from_status TEXT;
  v_parent_status TEXT;
BEGIN
  IF p_status NOT IN ('confirmed', 'processing', 'shipped', 'delivered', 'cancelled') THEN
    RAISE EXCEPTION 'Unsupported store order status %', p_status;
  END IF;
  SELECT CASE
    WHEN BOOL_AND(store_status = 'delivered') THEN 'delivered'
    WHEN BOOL_OR(store_status = 'shipped') THEN 'shipped'
    WHEN BOOL_OR(store_status IN ('confirmed', 'processing')) THEN 'processing'
    WHEN BOOL_AND(store_status = 'cancelled') THEN 'cancelled'
    ELSE 'pending'
  END INTO v_from_status
  FROM public.order_items WHERE order_id = p_order_id AND seller_id = p_seller_id;
  IF v_from_status IS NULL THEN RAISE EXCEPTION 'Unauthorized to update this order'; END IF;
  UPDATE public.order_items SET store_status = p_status, store_status_updated_at = NOW()
  WHERE order_id = p_order_id AND seller_id = p_seller_id;
  INSERT INTO public.order_status_history (order_id, from_status, to_status, changed_by, note)
  VALUES (p_order_id, v_from_status::order_status_type, p_status::order_status_type, p_seller_id, 'Store owner updated their items');
  SELECT CASE
    WHEN BOOL_AND(store_status = 'delivered') THEN 'delivered'
    WHEN BOOL_OR(store_status = 'shipped') THEN 'shipped'
    WHEN BOOL_OR(store_status IN ('confirmed', 'processing')) THEN 'processing'
    WHEN BOOL_AND(store_status = 'cancelled') THEN 'cancelled'
    ELSE 'pending'
  END INTO v_parent_status
  FROM public.order_items WHERE order_id = p_order_id;
  UPDATE public.orders
  SET status = v_parent_status::order_status_type, updated_at = NOW(),
      confirmed_at = CASE WHEN v_parent_status IN ('processing', 'shipped', 'delivered') THEN COALESCE(confirmed_at, NOW()) ELSE confirmed_at END,
      shipped_at = CASE WHEN v_parent_status IN ('shipped', 'delivered') THEN COALESCE(shipped_at, NOW()) ELSE shipped_at END,
      delivered_at = CASE WHEN v_parent_status = 'delivered' THEN COALESCE(delivered_at, NOW()) ELSE delivered_at END,
      cancelled_at = CASE WHEN v_parent_status = 'cancelled' THEN COALESCE(cancelled_at, NOW()) ELSE cancelled_at END
  WHERE id = p_order_id;
END;
$$;

-- Fix 3: RPC cho customer xác nhận đã nhận hàng (bypass RLS order_items policy)
CREATE OR REPLACE FUNCTION public.customer_confirm_delivery(
  p_order_id UUID,
  p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_now TIMESTAMPTZ := NOW();
BEGIN
  IF auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE public.orders
  SET status = 'delivered'::order_status_type,
      delivered_at = v_now,
      updated_at = v_now
  WHERE id = p_order_id AND user_id = p_user_id;

  UPDATE public.order_items
  SET store_status = 'delivered',
      store_status_updated_at = v_now
  WHERE order_id = p_order_id;

  INSERT INTO public.order_status_history (order_id, from_status, to_status, changed_by, note)
  VALUES (p_order_id, 'shipped'::order_status_type, 'delivered'::order_status_type, p_user_id, 'Khach hang da nhan hang');

  UPDATE public.shipping_tracking
  SET status = 'delivered',
      events = COALESCE(events, '[]'::jsonb) || jsonb_build_array(jsonb_build_object('status', 'delivered', 'note', 'Don hang da giao thanh cong', 'created_at', v_now)),
      actual_delivery = v_now,
      last_event_at = v_now
  WHERE order_id = p_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.customer_confirm_delivery(UUID, UUID) TO authenticated;

-- Fix 4: get_store_orders — dùng giá trị thật thay vì hardcode 0
DROP FUNCTION IF EXISTS public.get_store_orders(UUID);
CREATE FUNCTION public.get_store_orders(p_seller_id UUID)
RETURNS TABLE (
  id UUID,
  order_number TEXT,
  user_id UUID,
  status TEXT,
  shipping_full_name TEXT,
  shipping_phone TEXT,
  shipping_address1 TEXT,
  shipping_address2 TEXT,
  shipping_ward TEXT,
  shipping_district TEXT,
  shipping_city TEXT,
  shipping_province TEXT,
  shipping_country TEXT,
  shipping_postal_code TEXT,
  subtotal NUMERIC,
  discount_amount NUMERIC,
  shipping_fee NUMERIC,
  tax_amount NUMERIC,
  total_amount NUMERIC,
  voucher_id UUID,
  voucher_code TEXT,
  customer_note TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    o.id,
    o.order_number,
    o.user_id,
    o.status::TEXT AS status,
    o.shipping_full_name,
    o.shipping_phone,
    o.shipping_address1,
    o.shipping_address2,
    o.shipping_ward,
    o.shipping_district,
    o.shipping_city,
    o.shipping_province,
    o.shipping_country,
    o.shipping_postal_code,
    SUM(oi.total_price) AS subtotal,
    o.discount_amount,
    o.shipping_fee,
    o.tax_amount,
    o.total_amount,
    o.voucher_id,
    o.voucher_code,
    o.customer_note,
    o.created_at,
    o.updated_at
  FROM public.orders o
  JOIN public.order_items oi ON oi.order_id = o.id
  WHERE oi.seller_id = p_seller_id
  GROUP BY o.id
  ORDER BY o.created_at DESC;
$$;
