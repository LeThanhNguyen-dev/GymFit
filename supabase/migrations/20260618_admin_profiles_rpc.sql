-- Ensure columns exist before creating RPCs
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- RPC for admin to manage profiles bypassing RLS recursion

-- First, drop the broken policies
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;

-- Restore default: users can see their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- RPC: list all profiles (runs as superuser, bypasses RLS)
CREATE OR REPLACE FUNCTION public.admin_list_profiles(
  search_text TEXT DEFAULT NULL,
  role_filter TEXT DEFAULT NULL,
  seller_status_filter TEXT DEFAULT NULL,
  banned_filter BOOLEAN DEFAULT NULL,
  sort_col TEXT DEFAULT 'created_at',
  sort_asc BOOLEAN DEFAULT false,
  page_num INT DEFAULT 1,
  page_size INT DEFAULT 20
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSON;
BEGIN
  -- Verify caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  WITH filtered AS (
    SELECT *
    FROM public.profiles
    WHERE (search_text IS NULL OR full_name ILIKE '%' || search_text || '%' OR email ILIKE '%' || search_text || '%')
      AND (role_filter IS NULL OR role = role_filter)
      AND (seller_status_filter IS NULL OR seller_status = seller_status_filter)
      AND (banned_filter IS NULL OR is_banned = banned_filter)
  ),
  counted AS (
    SELECT COUNT(*) AS total FROM filtered
  ),
  paged AS (
    SELECT * FROM filtered
    ORDER BY
      CASE WHEN sort_col = 'email' AND sort_asc THEN email END ASC NULLS LAST,
      CASE WHEN sort_col = 'email' AND NOT sort_asc THEN email END DESC NULLS LAST,
      CASE WHEN sort_col = 'created_at' AND sort_asc THEN created_at END ASC NULLS LAST,
      CASE WHEN sort_col = 'created_at' AND NOT sort_asc THEN created_at END DESC NULLS LAST,
      created_at DESC
    LIMIT page_size
    OFFSET (page_num - 1) * page_size
  )
  SELECT json_build_object(
    'items', COALESCE((SELECT json_agg(row_to_json(paged.*)) FROM paged), '[]'::json),
    'totalCount', (SELECT total FROM counted)
  ) INTO result;

  RETURN result;
END;
$$;

-- RPC: update a user's role (bypasses RLS)
CREATE OR REPLACE FUNCTION public.admin_update_user_role(
  target_id UUID,
  new_role TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  UPDATE public.profiles
  SET role = new_role, updated_at = NOW()
  WHERE id = target_id;
END;
$$;

-- RPC: toggle ban (bypasses RLS)
DROP FUNCTION IF EXISTS public.admin_toggle_ban(uuid,boolean,text);
CREATE OR REPLACE FUNCTION public.admin_toggle_ban(
  target_id UUID,
  set_banned BOOLEAN,
  reason_text TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  IF set_banned THEN
    UPDATE public.profiles
    SET is_banned = TRUE, is_active = FALSE, ban_reason = reason_text, banned_at = NOW(), updated_at = NOW()
    WHERE id = target_id;
  ELSE
    UPDATE public.profiles
    SET is_banned = FALSE, is_active = TRUE, ban_reason = NULL, banned_at = NULL, updated_at = NOW()
    WHERE id = target_id;
  END IF;
END;
$$;

-- RPC: update seller status (bypasses RLS)
CREATE OR REPLACE FUNCTION public.admin_update_seller_status(
  target_id UUID,
  new_status TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  UPDATE public.profiles
  SET seller_status = new_status,
      role = CASE WHEN new_status IN ('approved', 'rejected') THEN 'storeowner' ELSE role END,
      updated_at = NOW()
  WHERE id = target_id;
END;
$$;
