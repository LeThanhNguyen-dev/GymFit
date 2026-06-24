import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function getEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing ${name}`);
  return value;
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
      .select("*")
      .limit(1);

    query = paymentId ? query.eq("id", paymentId) : query.eq("order_id", orderId);

    let { data: payments, error: paymentError } = await query;

    if ((!payments || payments.length === 0) && paymentId && orderId) {
      const fallback = await serviceClient
        .from("payments")
        .select("*")
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

    const gatewayResponse = payment.gateway_response ?? {};
    const orderCode = gatewayResponse.orderCode;
    if (!orderCode) {
      return jsonResponse({ error: "payOS orderCode not found" }, 400);
    }

    const payosResponse = await fetch(
      `https://api-merchant.payos.vn/v2/payment-requests/${orderCode}`,
      {
        headers: {
          "x-client-id": payosClientId,
          "x-api-key": payosApiKey,
        },
      },
    );
    const payosJson = await payosResponse.json();
    if (!payosResponse.ok || payosJson.code !== "00") {
      return jsonResponse(
        { error: payosJson.desc ?? "Could not sync payOS payment" },
        400,
      );
    }

    const payosStatus = String(payosJson.data?.status ?? "");
    const updateData: Record<string, unknown> = {
      gateway_response: {
        ...gatewayResponse,
        lastSync: payosJson.data,
      },
      updated_at: new Date().toISOString(),
    };

    if (payosStatus === "PAID") {
      updateData.status = "paid";
      updateData.paid_at = new Date().toISOString();
      updateData.gateway_transaction_id =
        gatewayResponse.paymentLinkId ?? String(orderCode);
    } else if (payosStatus === "CANCELLED") {
      updateData.status = "failed";
      updateData.failed_at = new Date().toISOString();
      updateData.failure_reason = "payOS payment was cancelled";
    }

    const { data: updatedPayment, error: updateError } = await serviceClient
      .from("payments")
      .update(updateData)
      .eq("id", payment.id)
      .select()
      .single();

    if (updateError) {
      return jsonResponse({ error: updateError.message }, 500);
    }

    return jsonResponse({ data: updatedPayment });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
