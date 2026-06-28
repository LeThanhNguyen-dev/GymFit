-- 1. Đảm bảo hàm trigger được tạo đúng
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

-- 2. Gắn lại trigger cho bảng chat_messages
DROP TRIGGER IF EXISTS trg_chat_sync_after_message ON public.chat_messages;
CREATE TRIGGER trg_chat_sync_after_message
AFTER INSERT ON public.chat_messages
FOR EACH ROW
EXECUTE FUNCTION public.chat_sync_after_message();

-- 3. Đồng bộ lại dữ liệu cũ (những tin nhắn đã gửi trước khi trigger hoạt động)
DO $$
DECLARE
  conv RECORD;
  last_msg RECORD;
BEGIN
  FOR conv IN SELECT id FROM public.chat_conversations LOOP
    -- Lấy tin nhắn mới nhất
    SELECT content, created_at INTO last_msg 
    FROM public.chat_messages 
    WHERE conversation_id = conv.id 
    ORDER BY created_at DESC 
    LIMIT 1;
    
    -- Cập nhật lại preview
    IF FOUND THEN
      UPDATE public.chat_conversations
      SET last_message_preview = LEFT(TRIM(last_msg.content), 120),
          last_message_at = last_msg.created_at
      WHERE id = conv.id;
      
      UPDATE public.chat_participants
      SET last_message_preview = LEFT(TRIM(last_msg.content), 120),
          last_message_at = last_msg.created_at
      WHERE conversation_id = conv.id;
    END IF;
  END LOOP;
END;
$$;
