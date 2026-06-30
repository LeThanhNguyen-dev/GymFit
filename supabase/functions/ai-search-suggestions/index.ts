import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type CatalogProduct = {
  name?: string;
  tags?: unknown;
  category?: { name?: string } | null;
  brand?: { name?: string } | null;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function normalizeQuery(value: unknown): string {
  return String(value ?? "")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 80);
}

function cleanSuggestion(value: unknown): string {
  return String(value ?? "")
    .replace(/^[\s"'`*\-\d.)]+/, "")
    .replace(/[\s"'`]+$/, "")
    .replace(/\s+/g, " ")
    .trim();
}

function uniqueSuggestions(values: unknown[], limit = 6): string[] {
  const seen = new Set<string>();
  const suggestions: string[] = [];

  for (const value of values) {
    const suggestion = cleanSuggestion(value);
    const key = suggestion.toLowerCase();
    if (!suggestion || suggestion.length > 60 || seen.has(key)) continue;

    seen.add(key);
    suggestions.push(suggestion);
    if (suggestions.length >= limit) break;
  }

  return suggestions;
}

function parseGroqSuggestions(content: string): string[] {
  try {
    const parsed = JSON.parse(content);
    if (Array.isArray(parsed)) return uniqueSuggestions(parsed);
    if (Array.isArray(parsed?.suggestions)) {
      return uniqueSuggestions(parsed.suggestions);
    }
  } catch (_) {
    const match = content.match(/\[[\s\S]*\]/);
    if (match) {
      try {
        const parsed = JSON.parse(match[0]);
        if (Array.isArray(parsed)) return uniqueSuggestions(parsed);
      } catch (_) {
        // Continue with line parsing below.
      }
    }
  }

  return uniqueSuggestions(content.split(/\r?\n/));
}

function buildFallbackSuggestions(query: string): string[] {
  return uniqueSuggestions([
    query,
    `${query} gym`,
    `${query} nam`,
    `${query} nữ`,
    `${query} giá tốt`,
    `${query} chính hãng`,
  ]);
}

function formatCatalogContext(products: CatalogProduct[]): string {
  if (products.length === 0) return "Không có dữ liệu catalog liên quan.";

  return products
    .map((product) => {
      const tags = Array.isArray(product.tags)
        ? product.tags.filter(Boolean).join(", ")
        : "";
      return [
        product.name,
        product.category?.name,
        product.brand?.name,
        tags,
      ]
        .filter(Boolean)
        .join(" | ");
    })
    .join("\n");
}

async function getCatalogContext(query: string): Promise<CatalogProduct[]> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) return [];

  const client = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const select =
    "name, tags, category:categories(name), brand:brands(name)";
  const keyword = query.replace(/[%_]/g, " ").trim();

  const matching = await client
    .from("products")
    .select(select)
    .in("status", ["active", "out_of_stock"])
    .ilike("name", `%${keyword}%`)
    .order("total_sold", { ascending: false })
    .limit(12);

  if (matching.data && matching.data.length > 0) {
    return matching.data as CatalogProduct[];
  }

  const popular = await client
    .from("products")
    .select(select)
    .in("status", ["active", "out_of_stock"])
    .order("total_sold", { ascending: false })
    .limit(12);

  return (popular.data ?? []) as CatalogProduct[];
}

async function createGroqSuggestions(
  query: string,
  recentSearches: string[],
  catalogContext: CatalogProduct[],
): Promise<string[]> {
  const groqApiKey = Deno.env.get("GROQ_API_KEY");
  if (!groqApiKey) throw new Error("Missing GROQ_API_KEY");

  const model = Deno.env.get("GROQ_MODEL") ?? "llama-3.1-8b-instant";
  const response = await fetch(
    "https://api.groq.com/openai/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${groqApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0.35,
        max_tokens: 160,
        messages: [
          {
            role: "system",
            content:
              "Bạn là trợ lý tìm kiếm cho app thương mại điện tử GymFit tại Việt Nam. Chỉ tạo gợi ý tìm kiếm ngắn, tự nhiên, liên quan gym/fitness và catalog. Trả về đúng JSON array gồm 6 string, không markdown, không giải thích.",
          },
          {
            role: "user",
            content: [
              `Query hiện tại: ${query}`,
              `Tìm kiếm gần đây: ${recentSearches.join(", ") || "không có"}`,
              "Catalog liên quan:",
              formatCatalogContext(catalogContext),
              "Yêu cầu: gợi ý tiếng Việt, 2-7 từ/gợi ý, tránh trùng lặp, không bịa thương hiệu nếu catalog không có.",
            ].join("\n"),
          },
        ],
      }),
    },
  );

  const data = await response.json();
  if (!response.ok) {
    throw new Error(data?.error?.message ?? "Groq request failed");
  }

  const content = data?.choices?.[0]?.message?.content;
  if (typeof content !== "string") {
    throw new Error("Groq response is missing content");
  }

  return parseGroqSuggestions(content);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await req.json().catch(() => ({}));
    const query = normalizeQuery(body.query);
    const recentSearches = Array.isArray(body.recent_searches)
      ? uniqueSuggestions(body.recent_searches, 5)
      : [];

    if (query.length < 2) return jsonResponse([]);

    const catalogContext = await getCatalogContext(query);
    const suggestions = await createGroqSuggestions(
      query,
      recentSearches,
      catalogContext,
    );

    return jsonResponse(
      suggestions.length > 0 ? suggestions : buildFallbackSuggestions(query),
    );
  } catch (error) {
    console.error("ai-search-suggestions error:", errorMessage(error));
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
