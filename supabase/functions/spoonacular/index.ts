const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Expose-Headers": "X-API-Quota-Request, X-API-Quota-Used, X-API-Quota-Left",
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const apiKey = Deno.env.get("SPOONACULAR_API_KEY");
  if (!apiKey) return json({ error: "Recipe service is not configured" }, 503);

  try {
    const body = await request.json();
    const action = body?.action;
    let endpoint: URL;
    if (action === "search" && typeof body.query === "string" && body.query.length <= 100) {
      endpoint = new URL(body.query.trim()
        ? "https://api.spoonacular.com/recipes/complexSearch"
        : "https://api.spoonacular.com/recipes/random");
      endpoint.searchParams.set("number", "20");
      endpoint.searchParams.set("addRecipeInformation", "true");
      endpoint.searchParams.set("addRecipeNutrition", "true");
      endpoint.searchParams.set("instructionsRequired", "true");
      if (body.query.trim()) endpoint.searchParams.set("query", body.query.trim());
    } else if (action === "information" && /^\d{1,20}$/.test(String(body.id ?? ""))) {
      endpoint = new URL(`https://api.spoonacular.com/recipes/${body.id}/information`);
      endpoint.searchParams.set("includeNutrition", "true");
    } else {
      return json({ error: "Invalid request" }, 400);
    }
    endpoint.searchParams.set("apiKey", apiKey);
    const upstream = await fetch(endpoint);
    const quotaHeaders: Record<string, string> = {};
    for (const name of ["X-API-Quota-Request", "X-API-Quota-Used", "X-API-Quota-Left"]) {
      const value = upstream.headers.get(name);
      if (value !== null) quotaHeaders[name] = value;
    }
    if (!upstream.ok) {
      console.error("Spoonacular request failed", {
        status: upstream.status,
        body: await upstream.text(),
      });
      return json(
        { error: "Recipe provider request failed", upstreamStatus: upstream.status },
        upstream.status,
        quotaHeaders,
      );
    }
    const result = await upstream.json();
    if (action === "search" && !body.query.trim()) {
      return json({ results: Array.isArray(result.recipes) ? result.recipes : [] }, 200, quotaHeaders);
    }
    return json(result, 200, quotaHeaders);
  } catch {
    return json({ error: "Invalid request or unavailable recipe provider" }, 400);
  }
});

function json(value: unknown, status = 200, extraHeaders: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(value), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json", ...extraHeaders },
  });
}
