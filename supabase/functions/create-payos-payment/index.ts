import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const encoder = new TextEncoder();

async function hmacSha256Hex(key: string, data: string): Promise<string> {
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode(key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    cryptoKey,
    encoder.encode(data),
  );
  return [...new Uint8Array(signature)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function getEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing ${name}`);
  return value;
}

function createPaymentSignature(
  checksumKey: string,
  payload: Record<string, string | number>,
): Promise<string> {
  const signData = Object.keys(payload)
    .sort()
    .map((key) => `${key}=${payload[key]}`)
    .join("&");
  return hmacSha256Hex(checksumKey, signData);
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = getEnv("SUPABASE_URL");
    const supabaseAnonKey = getEnv("SUPABASE_ANON_KEY");
    const supabaseServiceRoleKey = getEnv("SUPABASE_SERVICE_ROLE_KEY");
    const payosClientId = getEnv("PAYOS_CLIENT_ID");
    const payosApiKey = getEnv("PAYOS_API_KEY");
    const payosChecksumKey = getEnv("PAYOS_CHECKSUM_KEY");
    const returnUrl =
      Deno.env.get("PAYOS_RETURN_URL") ?? "https://gymfit.app/payment-return";
    const cancelUrl =
      Deno.env.get("PAYOS_CANCEL_URL") ?? "https://gymfit.app/payment-cancel";

    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const serviceClient = createClient(supabaseUrl, supabaseServiceRoleKey);

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const { payment_id: paymentId, order_id: orderId } = await req.json();
    if (!paymentId && !orderId) {
      return jsonResponse({ error: "payment_id or order_id is required" }, 400);
    }

    let query = serviceClient
      .from("payments")
      .select("id, order_id, user_id, method, status, amount, gateway_response")
      .limit(1);

    query = paymentId ? query.eq("id", paymentId) : query.eq("order_id", orderId);

    let { data: payments, error: paymentError } = await query;

    if ((!payments || payments.length === 0) && paymentId && orderId) {
      const fallback = await serviceClient
        .from("payments")
        .select("id, order_id, user_id, method, status, amount, gateway_response")
        .eq("order_id", orderId)
        .limit(1);
      payments = fallback.data;
      paymentError = fallback.error;
    }

    const payment = payments?.[0];

    if (paymentError || !payment) {
      return jsonResponse(
        {
          error: "Payment not found",
          payment_id: paymentId ?? null,
          order_id: orderId ?? null,
          details: paymentError?.message ?? null,
        },
        404,
      );
    }
    if (payment.user_id !== user.id) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }
    if (payment.method !== "payos") {
      return jsonResponse({ error: "Payment method is not payOS" }, 400);
    }

    const existing = payment.gateway_response ?? {};
    if (existing.qrCode && existing.paymentLinkId) {
      return jsonResponse({ data: existing });
    }

    const orderCode = Number(`${Date.now()}${Math.floor(Math.random() * 90) + 10}`);
    const amount = Math.round(Number(payment.amount));
    const description = `GF${String(orderCode).slice(-7)}`;
    const signature = await createPaymentSignature(payosChecksumKey, {
      amount,
      cancelUrl,
      description,
      orderCode,
      returnUrl,
    });

    const payosResponse = await fetch(
      "https://api-merchant.payos.vn/v2/payment-requests",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-client-id": payosClientId,
          "x-api-key": payosApiKey,
        },
        body: JSON.stringify({
          orderCode,
          amount,
          description,
          cancelUrl,
          returnUrl,
          signature,
        }),
      },
    );

    const payosJson = await payosResponse.json();
    if (!payosResponse.ok || payosJson.code !== "00") {
      return jsonResponse(
        {
          error: payosJson.desc ?? "Could not create payOS payment",
          payos: payosJson,
        },
        400,
      );
    }

    const gatewayResponse = {
      provider: "payos",
      orderCode,
      ...payosJson.data,
    };

    await serviceClient
      .from("payments")
      .update({
        gateway: "payos",
        gateway_response: gatewayResponse,
        updated_at: new Date().toISOString(),
      })
      .eq("id", payment.id);

    return jsonResponse({ data: gatewayResponse });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
