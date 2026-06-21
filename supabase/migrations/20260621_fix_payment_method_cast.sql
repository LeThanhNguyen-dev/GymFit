-- Fix payment method cast in create_checkout_order

CREATE OR REPLACE FUNCTION public.create_checkout_order(
  p_user_id UUID,
  p_address JSONB,
  p_items JSONB,
  p_voucher_id UUID DEFAULT NULL,
  p_voucher_code TEXT DEFAULT NULL,
  p_subtotal NUMERIC DEFAULT 0,
  p_discount_amount NUMERIC DEFAULT 0,
  p_shipping_fee NUMERIC DEFAULT 0,
  p_total_amount NUMERIC DEFAULT 0,
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
  v_product_id UUID;
  v_quantity INT;
  v_unit_price NUMERIC;
  v_current_stock INT;
BEGIN
  IF v_auth_uid IS NULL OR v_auth_uid <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized checkout request';
  END IF;

  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Checkout items cannot be empty';
  END IF;

  INSERT INTO orders (
    order_number,
    user_id,
    status,
    shipping_full_name,
    shipping_phone,
    shipping_address1,
    shipping_address2,
    shipping_ward,
    shipping_district,
    shipping_city,
    shipping_province,
    shipping_country,
    shipping_postal_code,
    subtotal,
    discount_amount,
    shipping_fee,
    tax_amount,
    total_amount,
    voucher_id,
    voucher_code,
    customer_note
  )
  VALUES (
    v_order_number,
    p_user_id,
    'pending',
    p_address->>'full_name',
    p_address->>'phone',
    p_address->>'address_line1',
    p_address->>'address_line2',
    p_address->>'ward',
    p_address->>'district',
    p_address->>'city',
    p_address->>'province',
    COALESCE(p_address->>'country', 'VN'),
    p_address->>'postal_code',
    p_subtotal,
    p_discount_amount,
    p_shipping_fee,
    0,
    p_total_amount,
    p_voucher_id,
    p_voucher_code,
    p_note
  )
  RETURNING id INTO v_order_id;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    v_variant_id := (v_item->>'variant_id')::UUID;
    v_product_id := (v_item->>'product_id')::UUID;
    v_quantity := COALESCE((v_item->>'quantity')::INT, 1);
    v_unit_price := COALESCE((v_item->>'unit_price')::NUMERIC, 0);

    SELECT COALESCE(stock, quantity, 0)
    INTO v_current_stock
    FROM product_variants
    WHERE id = v_variant_id
    FOR UPDATE;

    IF v_current_stock IS NULL THEN
      RAISE EXCEPTION 'Product variant % was not found', v_variant_id;
    END IF;

    IF v_current_stock < v_quantity THEN
      RAISE EXCEPTION 'Product variant % does not have enough stock', v_variant_id;
    END IF;

    INSERT INTO order_items (
      order_id,
      product_id,
      variant_id,
      product_name,
      variant_name,
      sku,
      image_url,
      unit_price,
      quantity,
      discount_amount,
      total_price
    )
    VALUES (
      v_order_id,
      v_product_id,
      v_variant_id,
      COALESCE(v_item->>'product_name', 'San pham'),
      v_item->>'variant_name',
      v_item->>'sku',
      v_item->>'image_url',
      v_unit_price,
      v_quantity,
      0,
      v_unit_price * v_quantity
    );

    UPDATE product_variants
    SET
      stock = v_current_stock - v_quantity,
      quantity = v_current_stock - v_quantity,
      updated_at = NOW()
    WHERE id = v_variant_id;
  END LOOP;

  INSERT INTO order_status_history (
    order_id,
    from_status,
    to_status,
    changed_by,
    note
  )
  VALUES (
    v_order_id,
    NULL,
    'pending',
    p_user_id,
    'Tao don hang'
  );

  INSERT INTO payments (
    order_id,
    user_id,
    method,
    status,
    amount,
    currency,
    gateway
  )
  VALUES (
    v_order_id,
    p_user_id,
    p_payment_method::payment_method_type,
    'pending',
    p_total_amount,
    'VND',
    CASE WHEN p_payment_method = 'cod' THEN NULL ELSE p_payment_method END
  )
  RETURNING id INTO v_payment_id;

  IF p_voucher_id IS NOT NULL THEN
    UPDATE vouchers
    SET
      used_count = COALESCE(used_count, 0) + 1,
      updated_at = NOW()
    WHERE id = p_voucher_id;
  END IF;

  DELETE FROM cart_items
  WHERE user_id = p_user_id;

  RETURN jsonb_build_object(
    'order_id', v_order_id,
    'order_number', v_order_number,
    'payment_id', v_payment_id,
    'payment_method', p_payment_method,
    'total_amount', p_total_amount
  );
END;
$$;
