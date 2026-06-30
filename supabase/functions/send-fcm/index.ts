import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { GoogleAuth } from 'npm:google-auth-library';

// 1. Lấy thông tin Service Account từ biến môi trường (Không bao giờ hardcode secret lên Git)
const FIREBASE_SERVICE_ACCOUNT = JSON.parse(
  Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}'
);

async function getAccessToken() {
  const auth = new GoogleAuth({
    credentials: {
      client_email: FIREBASE_SERVICE_ACCOUNT.client_email,
      private_key: FIREBASE_SERVICE_ACCOUNT.private_key,
    },
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token;
}

serve(async (req) => {
  try {
    const payload = await req.json();
    console.log('Webhook payload:', payload);

    // Bỏ qua nếu là hành động DELETE
    if (payload.type === 'DELETE') {
      return new Response('Ignored DELETE', { status: 200 });
    }

    const table = payload.table;
    const record = payload.record;
    
    let targetUserId = null;
    let title = 'GymFit';
    let body = 'Bạn có thông báo mới';

    // 2. Tùy chỉnh thông báo dựa vào bảng
    if (table === 'chat_messages') {
      targetUserId = record.receiver_id;
      title = 'Tin nhắn mới';
      body = `Bạn có 1 tin nhắn mới từ khách hàng`;
    } else if (table === 'orders') {
      // Khi toàn bộ đơn hàng cập nhật (thường dùng báo cho người mua)
      targetUserId = record.user_id; 
      title = 'Trạng thái đơn hàng';
      body = `Đơn hàng của bạn đã cập nhật trạng thái mới.`;
    } else if (table === 'order_items') {
      // Khi có 1 sản phẩm bán được (báo cho chủ Shop)
      targetUserId = record.seller_id;
      title = 'Đơn hàng mới!';
      body = `Shop của bạn vừa có một đơn hàng mới. Vui lòng kiểm tra!`;
    } else if (table === 'payout_requests') {
      targetUserId = record.seller_id;
      title = 'Yêu cầu rút tiền';
      body = `Yêu cầu rút tiền của bạn đã cập nhật trạng thái mới.`;
    } else {
      return new Response('Table ignored', { status: 200 });
    }

    if (!targetUserId) {
      return new Response('No target user', { status: 200 });
    }

    // 3. Khởi tạo Supabase client để lấy FCM Token của targetUserId
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { data: tokens, error } = await supabaseClient
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', targetUserId);

    if (error || !tokens || tokens.length === 0) {
      console.log('No FCM tokens found for user', targetUserId);
      return new Response('No tokens', { status: 200 });
    }

    // 4. Lấy Access Token từ Google
    const accessToken = await getAccessToken();

    // 5. Gửi Push Notification qua FCM HTTP v1 API
    const promises = tokens.map(async (t) => {
      const fcmPayload = {
        message: {
          token: t.token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            table: table,
            record_id: record.id,
          }
        }
      };

      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${FIREBASE_SERVICE_ACCOUNT.project_id}/messages:send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify(fcmPayload),
      });

      return res.json();
    });

    const results = await Promise.all(promises);
    console.log('FCM Send Results:', results);

    return new Response(JSON.stringify(results), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
