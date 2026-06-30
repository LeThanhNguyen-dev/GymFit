-- Bảng lưu trữ FCM Token của các thiết bị để gửi Push Notification
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  device_info TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, token)
);

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user ON public.fcm_tokens(user_id);

ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- User có thể thêm và xem token của chính mình
DROP POLICY IF EXISTS "Users can manage own fcm tokens" ON public.fcm_tokens;
CREATE POLICY "Users can manage own fcm tokens"
  ON public.fcm_tokens FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Hàm lưu token vào database (upsert)
CREATE OR REPLACE FUNCTION public.upsert_fcm_token(
  p_token TEXT,
  p_device_info TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO public.fcm_tokens (user_id, token, device_info)
  VALUES (v_user_id, p_token, p_device_info)
  ON CONFLICT (user_id, token) 
  DO UPDATE SET updated_at = NOW(), device_info = p_device_info;
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_fcm_token(TEXT, TEXT) TO authenticated;
