-- ============================================================
-- Migration: Enhance chat_messages with media, reactions, replies
-- Add chat-media storage bucket
-- Add chat_delete_conversation RPC
-- ============================================================

-- 1. Add new columns to chat_messages
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS message_type TEXT NOT NULL DEFAULT 'text'
    CHECK (message_type IN ('text', 'image', 'file'));

ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS media_url TEXT;

ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS media_thumb TEXT;

ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS media_width INTEGER;

ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS media_height INTEGER;

ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS file_name TEXT;

ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS file_size INTEGER;

ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS reactions JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.chat_messages(id) ON DELETE SET NULL;

-- Index for reactions lookups
CREATE INDEX IF NOT EXISTS idx_chat_messages_type
  ON public.chat_messages(conversation_id, message_type);

-- 2. Update the sync trigger to also set updated_at on messages
DROP TRIGGER IF EXISTS trg_chat_sync_after_message ON public.chat_messages;
DROP FUNCTION IF EXISTS public.chat_sync_after_message();

CREATE OR REPLACE FUNCTION public.chat_sync_after_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  preview_text TEXT;
BEGIN
  preview_text := LEFT(TRIM(COALESCE(NEW.content, '')), 120);

  IF TRIM(preview_text) = '' AND NEW.message_type = 'image' THEN
    preview_text := '[Hình ảnh]';
  ELSIF TRIM(preview_text) = '' AND NEW.message_type = 'file' THEN
    preview_text := '[Tập tin]';
  END IF;

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

CREATE TRIGGER trg_chat_sync_after_message
AFTER INSERT ON public.chat_messages
FOR EACH ROW
EXECUTE FUNCTION public.chat_sync_after_message();

-- 3. Add RLS for new columns (messages already have RLS, ensure updates work)
DROP POLICY IF EXISTS "Chat members can update messages" ON public.chat_messages;
CREATE POLICY "Chat members can update messages"
  ON public.chat_messages
  FOR UPDATE
  TO authenticated
  USING (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.chat_participants cp
      WHERE cp.conversation_id = chat_messages.conversation_id
        AND cp.user_id = auth.uid()
    )
  );

-- 4. Function to delete a conversation (cascading)
CREATE OR REPLACE FUNCTION public.chat_delete_conversation(
  p_conversation_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID := auth.uid();
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.chat_participants
    WHERE conversation_id = p_conversation_id AND user_id = current_user_id
  ) THEN
    RAISE EXCEPTION 'Not a participant of this conversation';
  END IF;

  DELETE FROM public.chat_messages
  WHERE conversation_id = p_conversation_id;

  DELETE FROM public.chat_participants
  WHERE conversation_id = p_conversation_id;

  DELETE FROM public.chat_conversations
  WHERE id = p_conversation_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.chat_delete_conversation(UUID) TO authenticated;

-- 5. Create chat-media storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-media',
  'chat-media',
  true,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Storage policies for chat-media
DROP POLICY IF EXISTS "Chat media is publicly viewable" ON storage.objects;
CREATE POLICY "Chat media is publicly viewable"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'chat-media');

DROP POLICY IF EXISTS "Authenticated users can upload chat media" ON storage.objects;
CREATE POLICY "Authenticated users can upload chat media"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'chat-media'
    AND (storage.foldername(name))[1] = 'chat'
  );

DROP POLICY IF EXISTS "Users can update own chat media" ON storage.objects;
CREATE POLICY "Users can update own chat media"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'chat-media' AND owner = auth.uid());

DROP POLICY IF EXISTS "Users can delete own chat media" ON storage.objects;
CREATE POLICY "Users can delete own chat media"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'chat-media' AND owner = auth.uid());

-- 6. Add chat_messages to realtime publication
DO $$
BEGIN
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
