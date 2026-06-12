-- Atomic default-address switch for profile/address management.

CREATE OR REPLACE FUNCTION public.set_default_address(p_address_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT user_id
  INTO v_user_id
  FROM public.addresses
  WHERE id = p_address_id
  FOR UPDATE;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Address was not found';
  END IF;

  IF auth.uid() IS NULL OR auth.uid() <> v_user_id THEN
    RAISE EXCEPTION 'Unauthorized address update';
  END IF;

  UPDATE public.addresses
  SET
    is_default = CASE WHEN id = p_address_id THEN TRUE ELSE FALSE END,
    updated_at = NOW()
  WHERE user_id = v_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.set_default_address(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_default_address(UUID) TO authenticated;
