-- GymFit shop registration table + storage bucket.

CREATE TABLE IF NOT EXISTS public.shop_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shop_name TEXT NOT NULL,
  shop_description TEXT,
  phone_number TEXT NOT NULL,
  address TEXT NOT NULL,
  cccd_front_url TEXT,
  cccd_back_url TEXT,
  full_name TEXT NOT NULL,
  cccd_number TEXT NOT NULL,
  date_of_birth TIMESTAMPTZ NOT NULL,
  issued_date TIMESTAMPTZ NOT NULL,
  issued_place TEXT NOT NULL,
  business_license_url TEXT,
  tax_code TEXT,
  business_type TEXT NOT NULL DEFAULT 'individual',
  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS shop_name TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS shop_description TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS cccd_front_url TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS cccd_back_url TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS cccd_number TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS date_of_birth TIMESTAMPTZ;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS issued_date TIMESTAMPTZ;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS issued_place TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS business_license_url TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS tax_code TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS business_type TEXT DEFAULT 'individual';
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ;
ALTER TABLE public.shop_registrations ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_shop_registrations_user_id ON public.shop_registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_shop_registrations_status ON public.shop_registrations(status);

ALTER TABLE public.shop_registrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own registrations"
  ON public.shop_registrations
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own registrations"
  ON public.shop_registrations
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Admin RPCs (bypass RLS via SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.get_all_shop_registrations(p_status TEXT DEFAULT NULL)
RETURNS SETOF public.shop_registrations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
      AND (raw_app_meta_data ->> 'role' = 'admin'
        OR raw_user_meta_data ->> 'is_admin' = 'true')
  ) THEN
    RETURN QUERY SELECT * FROM public.shop_registrations
      WHERE user_id = auth.uid()
      ORDER BY submitted_at DESC;
    RETURN;
  END IF;

  IF p_status IS NOT NULL AND p_status != 'all' THEN
    RETURN QUERY SELECT * FROM public.shop_registrations
      WHERE status = p_status
      ORDER BY submitted_at DESC;
  ELSE
    RETURN QUERY SELECT * FROM public.shop_registrations
      ORDER BY submitted_at DESC;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.approve_shop_registration(p_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
      AND (raw_app_meta_data ->> 'role' = 'admin'
        OR raw_user_meta_data ->> 'is_admin' = 'true')
  ) THEN
    RAISE EXCEPTION 'Only admins can approve registrations';
  END IF;

  UPDATE public.shop_registrations
  SET status = 'approved', reviewed_at = NOW(), updated_at = NOW()
  WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_shop_registration(p_id UUID, p_reason TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
      AND (raw_app_meta_data ->> 'role' = 'admin'
        OR raw_user_meta_data ->> 'is_admin' = 'true')
  ) THEN
    RAISE EXCEPTION 'Only admins can reject registrations';
  END IF;

  UPDATE public.shop_registrations
  SET status = 'rejected', rejection_reason = p_reason, reviewed_at = NOW(), updated_at = NOW()
  WHERE id = p_id;
END;
$$;

DROP TRIGGER IF EXISTS trg_shop_registrations_updated_at ON public.shop_registrations;
CREATE TRIGGER trg_shop_registrations_updated_at
  BEFORE UPDATE ON public.shop_registrations
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Storage bucket for shop documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('shop-documents', 'shop-documents', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Authenticated users can upload shop documents"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'shop-documents');

CREATE POLICY "Anyone can view shop documents"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'shop-documents');
