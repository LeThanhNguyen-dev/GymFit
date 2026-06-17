-- Thêm storeowner vào role check constraint của profiles table

ALTER TABLE public.profiles 
DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
ADD CONSTRAINT profiles_role_check 
CHECK (role = ANY (ARRAY['customer'::text, 'admin'::text, 'storeowner'::text]));

-- Cập nhật approve_shop_registration RPC để cập nhật role
CREATE OR REPLACE FUNCTION public.approve_shop_registration(p_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
      AND (raw_app_meta_data ->> 'role' = 'admin'
        OR raw_user_meta_data ->> 'is_admin' = 'true')
  ) THEN
    RAISE EXCEPTION 'Only admins can approve registrations';
  END IF;

  -- Lấy user_id từ registration
  SELECT user_id INTO v_user_id FROM public.shop_registrations WHERE id = p_id;

  -- Update trạng thái registration
  UPDATE public.shop_registrations
  SET status = 'approved', reviewed_at = NOW(), updated_at = NOW()
  WHERE id = p_id;

  -- Update role + seller_status trong profiles
  UPDATE public.profiles
  SET role = 'storeowner', seller_status = 'approved', updated_at = NOW()
  WHERE id = v_user_id;
END;
$$;
