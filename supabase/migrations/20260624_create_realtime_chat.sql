CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.chat_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_type TEXT NOT NULL DEFAULT 'direct' CHECK (conversation_type IN ('direct')),
  direct_key TEXT NOT NULL UNIQUE,
  last_message_preview TEXT,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.chat_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.chat_conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  peer_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  peer_name TEXT,
  peer_email TEXT,
  peer_avatar_url TEXT,
  peer_role TEXT,
  last_message_preview TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count INT NOT NULL DEFAULT 0 CHECK (unread_count >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (conversation_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.chat_conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(trim(content)) > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_participants_user_last_message
  ON public.chat_participants(user_id, last_message_at DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_created
  ON public.chat_messages(conversation_id, created_at ASC);

ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Chat members can view conversations" ON public.chat_conversations;
CREATE POLICY "Chat members can view conversations"
  ON public.chat_conversations
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.chat_participants cp
      WHERE cp.conversation_id = chat_conversations.id
        AND cp.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can view own chat participants" ON public.chat_participants;
CREATE POLICY "Users can view own chat participants"
  ON public.chat_participants
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Chat members can view messages" ON public.chat_messages;
CREATE POLICY "Chat members can view messages"
  ON public.chat_messages
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.chat_participants cp
      WHERE cp.conversation_id = chat_messages.conversation_id
        AND cp.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Chat members can send messages" ON public.chat_messages;
CREATE POLICY "Chat members can send messages"
  ON public.chat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.chat_participants cp
      WHERE cp.conversation_id = chat_messages.conversation_id
        AND cp.user_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.chat_can_user_contact(
  requester_id UUID,
  target_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requester_role TEXT;
  requester_seller_status TEXT;
  requester_banned BOOLEAN;
  target_role TEXT;
  target_seller_status TEXT;
  target_banned BOOLEAN;
BEGIN
  IF requester_id IS NULL OR target_id IS NULL OR requester_id = target_id THEN
    RETURN FALSE;
  END IF;

  SELECT role, seller_status, COALESCE(is_banned, FALSE)
  INTO requester_role, requester_seller_status, requester_banned
  FROM public.profiles
  WHERE id = requester_id;

  SELECT role, seller_status, COALESCE(is_banned, FALSE)
  INTO target_role, target_seller_status, target_banned
  FROM public.profiles
  WHERE id = target_id;

  IF requester_role IS NULL OR target_role IS NULL THEN
    RETURN FALSE;
  END IF;

  IF requester_banned OR target_banned THEN
    RETURN FALSE;
  END IF;

  IF requester_role = 'admin' THEN
    RETURN TRUE;
  END IF;

  IF requester_role = 'storeowner' OR requester_seller_status = 'approved' THEN
    RETURN target_role = 'admin' OR target_role = 'customer';
  END IF;

  RETURN target_role = 'admin'
    OR target_role = 'storeowner'
    OR target_seller_status = 'approved';
END;
$$;

CREATE OR REPLACE FUNCTION public.chat_sync_after_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  preview_text TEXT;
BEGIN
  preview_text := LEFT(TRIM(NEW.content), 120);

  UPDATE public.chat_conversations
  SET last_message_preview = preview_text,
      last_message_at = NEW.created_at,
      updated_at = NEW.created_at
  WHERE id = NEW.conversation_id;

  UPDATE public.chat_participants
  SET last_message_preview = preview_text,
      last_message_at = NEW.created_at,
      unread_count = CASE
        WHEN user_id = NEW.sender_id THEN 0
        ELSE unread_count + 1
      END,
      updated_at = NEW.created_at
  WHERE conversation_id = NEW.conversation_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_chat_sync_after_message ON public.chat_messages;
CREATE TRIGGER trg_chat_sync_after_message
AFTER INSERT ON public.chat_messages
FOR EACH ROW
EXECUTE FUNCTION public.chat_sync_after_message();

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

CREATE OR REPLACE FUNCTION public.chat_mark_conversation_read(
  p_conversation_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  UPDATE public.chat_participants
  SET unread_count = 0,
      updated_at = NOW()
  WHERE conversation_id = p_conversation_id
    AND user_id = auth.uid();
END;
$$;

CREATE OR REPLACE FUNCTION public.chat_list_contacts(
  search_text TEXT DEFAULT NULL,
  role_filter TEXT DEFAULT NULL,
  page_num INT DEFAULT 1,
  page_size INT DEFAULT 20
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID := auth.uid();
  current_role TEXT;
  current_seller_status TEXT;
  result JSON;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT role, seller_status
  INTO current_role, current_seller_status
  FROM public.profiles
  WHERE id = current_user_id;

  WITH allowed AS (
    SELECT
      p.id,
      COALESCE(p.full_name, p.email) AS full_name,
      p.email,
      p.avatar_url,
      CASE
        WHEN p.role = 'storeowner' OR p.seller_status = 'approved' THEN 'storeowner'
        ELSE p.role
      END AS role
    FROM public.profiles p
    WHERE p.id <> current_user_id
      AND COALESCE(p.is_banned, FALSE) = FALSE
      AND (
        (current_role = 'admin')
        OR (
          (current_role = 'storeowner' OR current_seller_status = 'approved')
          AND p.role IN ('admin', 'customer')
        )
        OR (
          current_role <> 'admin'
          AND current_role <> 'storeowner'
          AND current_seller_status <> 'approved'
          AND (
            p.role = 'admin'
            OR p.role = 'storeowner'
            OR p.seller_status = 'approved'
          )
        )
      )
      AND (
        role_filter IS NULL
        OR (
          role_filter = 'storeowner'
          AND (p.role = 'storeowner' OR p.seller_status = 'approved')
        )
        OR (
          role_filter <> 'storeowner'
          AND p.role = role_filter
        )
      )
      AND (
        search_text IS NULL
        OR COALESCE(p.full_name, '') ILIKE '%' || search_text || '%'
        OR p.email ILIKE '%' || search_text || '%'
      )
  ),
  counted AS (
    SELECT COUNT(*) AS total_count FROM allowed
  ),
  paged AS (
    SELECT *
    FROM allowed
    ORDER BY full_name ASC, email ASC
    LIMIT page_size
    OFFSET GREATEST(page_num - 1, 0) * page_size
  )
  SELECT json_build_object(
    'items',
    COALESCE((SELECT json_agg(row_to_json(paged.*)) FROM paged), '[]'::json),
    'totalCount',
    COALESCE((SELECT total_count FROM counted), 0)
  ) INTO result;

  RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.chat_can_user_contact(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_create_or_get_direct_conversation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_mark_conversation_read(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_list_contacts(TEXT, TEXT, INT, INT) TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'chat_participants'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_participants;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'chat_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
  END IF;
END
$$;
