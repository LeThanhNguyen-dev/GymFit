import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

function createWebhookSignData(data: Record<string, unknown>): string {
  return Object.keys(data)
    .filter((key) => data[key] !== null && data[key] !== undefined)
    .sort()
    .map((key) => `${key}=${data[key]}`)
    .join("&");
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

Deno.serve(async (req) => {
  try {
    const supabaseUrl = getEnv("SUPABASE_URL");
    const supabaseServiceRoleKey = getEnv("SUPABASE_SERVICE_ROLE_KEY");
    const payosChecksumKey = getEnv("PAYOS_CHECKSUM_KEY");
    const serviceClient = createClient(supabaseUrl, supabaseServiceRoleKey);

    const payload = await req.json();
    const data = payload.data as Record<string, unknown> | undefined;
    const signature = payload.signature as string | undefined;

    if (!data || !signature) {
      return jsonResponse({ error: "Invalid webhook payload" }, 400);
    }

    const expectedSignature = await hmacSha256Hex(
      payosChecksumKey,
      createWebhookSignData(data),
    );

    if (expectedSignature !== signature) {
      return jsonResponse({ error: "Invalid signature" }, 401);
    }

    const orderCode = data.orderCode?.toString();
    const paymentLinkId = data.paymentLinkId?.toString();

    let query = serviceClient.from("payments").select("*");
    if (orderCode) {
      query = query.filter("gateway_response->>orderCode", "eq", orderCode);
    } else if (paymentLinkId) {
      query = query.filter(
        "gateway_response->>paymentLinkId",
        "eq",
        paymentLinkId,
      );
    } else {
      return jsonResponse({ error: "Missing payment identifier" }, 400);
    }

    const { data: payment, error: paymentError } = await query.maybeSingle();
    if (paymentError || !payment) {
      return jsonResponse({ received: true });
    }

    const success = payload.success === true && data.code === "00";
    const gatewayResponse = payment.gateway_response ?? {};
    const updateData: Record<string, unknown> = {
      gateway_response: {
        ...gatewayResponse,
        webhook: data,
      },
      updated_at: new Date().toISOString(),
    };

    if (success) {
      updateData.status = "paid";
      updateData.paid_at = new Date().toISOString();
      updateData.gateway_transaction_id =
        data.reference?.toString() ?? paymentLinkId ?? orderCode;
    } else {
      updateData.status = "failed";
      updateData.failed_at = new Date().toISOString();
      updateData.failure_reason = data.desc?.toString() ?? "payOS failed";
    }

    await serviceClient.from("payments").update(updateData).eq("id", payment.id);

    return jsonResponse({ received: true });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
