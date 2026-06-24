CREATE OR REPLACE FUNCTION public.chat_create_or_get_direct_conversation(
  p_target_user_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID := auth.uid();
  current_name TEXT;
  current_email TEXT;
  current_avatar_url TEXT;
  current_role TEXT;
  target_name TEXT;
  target_email TEXT;
  target_avatar_url TEXT;
  target_role TEXT;
  v_conversation_id UUID;
  direct_key_value TEXT;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.chat_can_user_contact(current_user_id, p_target_user_id) THEN
    RAISE EXCEPTION 'You are not allowed to chat with this user';
  END IF;

  direct_key_value := LEAST(current_user_id::TEXT, p_target_user_id::TEXT)
    || ':'
    || GREATEST(current_user_id::TEXT, p_target_user_id::TEXT);

  INSERT INTO public.chat_conversations (conversation_type, direct_key)
  VALUES ('direct', direct_key_value)
  ON CONFLICT (direct_key) DO UPDATE
    SET direct_key = EXCLUDED.direct_key
  RETURNING id INTO v_conversation_id;

  SELECT
    COALESCE(full_name, email),
    email,
    avatar_url,
    CASE
      WHEN role = 'storeowner' OR seller_status = 'approved' THEN 'storeowner'
      ELSE role
    END
  INTO current_name, current_email, current_avatar_url, current_role
  FROM public.profiles
  WHERE id = current_user_id;

  SELECT
    COALESCE(full_name, email),
    email,
    avatar_url,
    CASE
      WHEN role = 'storeowner' OR seller_status = 'approved' THEN 'storeowner'
      ELSE role
    END
  INTO target_name, target_email, target_avatar_url, target_role
  FROM public.profiles
  WHERE id = p_target_user_id;

  INSERT INTO public.chat_participants (
    conversation_id,
    user_id,
    peer_user_id,
    peer_name,
    peer_email,
    peer_avatar_url,
    peer_role
  )
  VALUES (
    v_conversation_id,
    current_user_id,
    p_target_user_id,
    target_name,
    target_email,
    target_avatar_url,
    target_role
  )
  ON CONFLICT (conversation_id, user_id) DO UPDATE
  SET peer_user_id = EXCLUDED.peer_user_id,
      peer_name = EXCLUDED.peer_name,
      peer_email = EXCLUDED.peer_email,
      peer_avatar_url = EXCLUDED.peer_avatar_url,
      peer_role = EXCLUDED.peer_role,
      updated_at = NOW();

  INSERT INTO public.chat_participants (
    conversation_id,
    user_id,
    peer_user_id,
    peer_name,
    peer_email,
    peer_avatar_url,
    peer_role
  )
  VALUES (
    v_conversation_id,
    p_target_user_id,
    current_user_id,
    current_name,
    current_email,
    current_avatar_url,
    current_role
  )
  ON CONFLICT (conversation_id, user_id) DO UPDATE
  SET peer_user_id = EXCLUDED.peer_user_id,
      peer_name = EXCLUDED.peer_name,
      peer_email = EXCLUDED.peer_email,
      peer_avatar_url = EXCLUDED.peer_avatar_url,
      peer_role = EXCLUDED.peer_role,
      updated_at = NOW();

  RETURN v_conversation_id;
END;
$$;
