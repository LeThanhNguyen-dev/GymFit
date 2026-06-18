-- SQL Migration: 20260618_update_products_and_add_seller.sql
-- Add seller_id and physical dimensions to products table

ALTER TABLE public.products ADD COLUMN IF NOT EXISTS seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS length_cm NUMERIC;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS width_cm NUMERIC;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS height_cm NUMERIC;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- Enable RLS on products table if not already enabled
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can select active/published products
DROP POLICY IF EXISTS "Anyone can view active products" ON public.products;
CREATE POLICY "Anyone can view active products"
  ON public.products
  FOR SELECT
  USING (status = 'active' OR seller_id = auth.uid());

-- Policy: Store owners can insert their own products
DROP POLICY IF EXISTS "Store owners can insert products" ON public.products;
CREATE POLICY "Store owners can insert products"
  ON public.products
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = seller_id);

-- Policy: Store owners can update their own products
DROP POLICY IF EXISTS "Store owners can update own products" ON public.products;
CREATE POLICY "Store owners can update own products"
  ON public.products
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = seller_id);

-- Policy: Store owners can delete their own products
DROP POLICY IF EXISTS "Store owners can delete own products" ON public.products;
CREATE POLICY "Store owners can delete own products"
  ON public.products
  FOR DELETE
  TO authenticated
  USING (auth.uid() = seller_id);

-- RPC to get orders matching a store owner's products
CREATE OR REPLACE FUNCTION public.get_store_orders(p_seller_id UUID)
RETURNS SETOF public.orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT o.*
  FROM public.orders o
  JOIN public.order_items oi ON o.id = oi.order_id
  JOIN public.products p ON oi.product_id = p.id
  WHERE p.seller_id = p_seller_id
  ORDER BY o.created_at DESC;
END;
$$;

-- RPC to get order items for a specific store owner's order
CREATE OR REPLACE FUNCTION public.get_store_order_items(p_order_id UUID, p_seller_id UUID)
RETURNS SETOF public.order_items
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT oi.*
  FROM public.order_items oi
  JOIN public.products p ON oi.product_id = p.id
  WHERE oi.order_id = p_order_id AND p.seller_id = p_seller_id;
END;
$$;

-- RPC to update order item status (for individual item fullfillment if needed) or just get stats
CREATE OR REPLACE FUNCTION public.get_store_stats(p_seller_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_revenue NUMERIC := 0;
  v_order_count INT := 0;
  v_product_count INT := 0;
  v_out_of_stock_count INT := 0;
BEGIN
  -- Count total products
  SELECT COUNT(*) INTO v_product_count FROM public.products WHERE seller_id = p_seller_id;
  
  -- Count out of stock products (checking variants)
  SELECT COUNT(DISTINCT p.id) INTO v_out_of_stock_count 
  FROM public.products p
  LEFT JOIN public.product_variants pv ON p.id = pv.product_id
  WHERE p.seller_id = p_seller_id AND (pv.quantity <= 0 OR pv.quantity IS NULL);

  -- Count total orders containing seller's products
  SELECT COUNT(DISTINCT o.id) INTO v_order_count
  FROM public.orders o
  JOIN public.order_items oi ON o.id = oi.order_id
  JOIN public.products p ON oi.product_id = p.id
  WHERE p.seller_id = p_seller_id AND o.status != 'cancelled';

  -- Sum revenue of seller's products from completed orders
  SELECT COALESCE(SUM(oi.total_price), 0) INTO v_revenue
  FROM public.order_items oi
  JOIN public.orders o ON oi.order_id = o.id
  JOIN public.products p ON oi.product_id = p.id
  WHERE p.seller_id = p_seller_id AND o.status = 'delivered';

  RETURN jsonb_build_object(
    'revenue', v_revenue,
    'order_count', v_order_count,
    'product_count', v_product_count,
    'out_of_stock_count', v_out_of_stock_count
  );
END;
$$;

-- Storage bucket for product images
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Policy to allow uploads to product-images
DROP POLICY IF EXISTS "Authenticated users can upload product images" ON storage.objects;
CREATE POLICY "Authenticated users can upload product images"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Anyone can view product images" ON storage.objects;
CREATE POLICY "Anyone can view product images"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'product-images');
