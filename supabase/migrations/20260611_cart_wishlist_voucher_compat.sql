-- GymFit cart/wishlist/voucher compatibility migration.
-- Run before checkout RPC if the remote schema is missing person-3 tables.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS public.cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  variant_id UUID NOT NULL REFERENCES public.product_variants(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, variant_id)
);

ALTER TABLE public.cart_items ADD COLUMN IF NOT EXISTS product_id UUID;
ALTER TABLE public.cart_items ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.cart_items ADD COLUMN IF NOT EXISTS variant_id UUID;
ALTER TABLE public.cart_items ADD COLUMN IF NOT EXISTS quantity INT NOT NULL DEFAULT 1;
ALTER TABLE public.cart_items ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.cart_items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'cart_items_quantity_check'
      AND conrelid = 'public.cart_items'::regclass
  ) THEN
    ALTER TABLE public.cart_items
      ADD CONSTRAINT cart_items_quantity_check CHECK (quantity > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'cart_items_user_id_variant_id_key'
      AND conrelid = 'public.cart_items'::regclass
  ) THEN
    ALTER TABLE public.cart_items
      ADD CONSTRAINT cart_items_user_id_variant_id_key UNIQUE(user_id, variant_id);
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_cart_items_user_id
  ON public.cart_items(user_id);

CREATE INDEX IF NOT EXISTS idx_cart_items_variant_id
  ON public.cart_items(variant_id);

DROP TRIGGER IF EXISTS set_cart_items_updated_at ON public.cart_items;
CREATE TRIGGER set_cart_items_updated_at
  BEFORE UPDATE ON public.cart_items
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own cart" ON public.cart_items;
CREATE POLICY "Users manage own cart"
  ON public.cart_items FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.wishlist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE public.wishlist_items ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.wishlist_items ADD COLUMN IF NOT EXISTS product_id UUID;
ALTER TABLE public.wishlist_items ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'wishlist_items_user_id_product_id_key'
      AND conrelid = 'public.wishlist_items'::regclass
  ) THEN
    ALTER TABLE public.wishlist_items
      ADD CONSTRAINT wishlist_items_user_id_product_id_key UNIQUE(user_id, product_id);
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_wishlist_items_user_id
  ON public.wishlist_items(user_id);

CREATE INDEX IF NOT EXISTS idx_wishlist_items_product_id
  ON public.wishlist_items(product_id);

ALTER TABLE public.wishlist_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own wishlist" ON public.wishlist_items;
CREATE POLICY "Users manage own wishlist"
  ON public.wishlist_items FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.vouchers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  description TEXT,
  discount_type TEXT NOT NULL DEFAULT 'fixed'
    CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value NUMERIC(12, 2) NOT NULL,
  min_order_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  max_discount_amount NUMERIC(12, 2),
  usage_limit INT,
  used_count INT NOT NULL DEFAULT 0,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS code TEXT;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS discount_type TEXT NOT NULL DEFAULT 'fixed';
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS discount_value NUMERIC(12, 2) NOT NULL DEFAULT 0;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS min_order_amount NUMERIC(12, 2) NOT NULL DEFAULT 0;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS max_discount_amount NUMERIC(12, 2);
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS usage_limit INT;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS used_count INT NOT NULL DEFAULT 0;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days');
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'vouchers_discount_type_check'
      AND conrelid = 'public.vouchers'::regclass
  ) THEN
    ALTER TABLE public.vouchers
      ADD CONSTRAINT vouchers_discount_type_check
      CHECK (discount_type IN ('percentage', 'fixed'));
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_vouchers_active_window
  ON public.vouchers(is_active, start_date, end_date);

CREATE UNIQUE INDEX IF NOT EXISTS idx_vouchers_code_lower
  ON public.vouchers(LOWER(code));

DROP TRIGGER IF EXISTS set_vouchers_updated_at ON public.vouchers;
CREATE TRIGGER set_vouchers_updated_at
  BEFORE UPDATE ON public.vouchers
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active vouchers" ON public.vouchers;
CREATE POLICY "Anyone can view active vouchers"
  ON public.vouchers FOR SELECT
  USING (
    is_active = TRUE
    AND start_date <= NOW()
    AND end_date >= NOW()
    AND (usage_limit IS NULL OR used_count < usage_limit)
  );

DROP POLICY IF EXISTS "Admins manage vouchers" ON public.vouchers;
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name = 'role'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Admins manage vouchers"
        ON public.vouchers FOR ALL
        USING (
          EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role = 'admin'
          )
        )
        WITH CHECK (
          EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role = 'admin'
          )
        )
    $policy$;
  END IF;
END;
$$;
