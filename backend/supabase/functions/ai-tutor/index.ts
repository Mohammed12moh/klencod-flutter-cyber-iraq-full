// Supabase Edge Function: ai-tutor
// Keeps the AI provider's API key server-side only.
// Deploy: supabase functions deploy ai-tutor
// Secrets: supabase secrets set AI_API_KEY=sk-...
//
// Enforces: auth required, per-user daily message cap, max message length.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const AI_API_KEY = Deno.env.get("AI_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const MAX_MESSAGE_LENGTH = 1500;
const DAILY_MESSAGE_LIMIT = 50;

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "");
    if (!jwt) return json({ error: "unauthorized" }, 401);

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data: userData, error: userErr } = await supabase.auth.getUser(jwt);
    if (userErr || !userData?.user) return json({ error: "unauthorized" }, 401);
    const userId = userData.user.id;

    const body = await req.json().catch(() => null);
    const message: string | undefined = body?.message;
    if (!message || typeof message !== "string") {
      return json({ error: "missing_message" }, 400);
    }
    if (message.length > MAX_MESSAGE_LENGTH) {
      return json({ error: "message_too_long", max: MAX_MESSAGE_LENGTH }, 400);
    }

    // rate-limit: count today's usage rows for this user
    const since = new Date();
    since.setHours(0, 0, 0, 0);
    const { count } = await supabase
      .from("ai_usage_logs")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .gte("created_at", since.toISOString());

    if ((count ?? 0) >= DAILY_MESSAGE_LIMIT) {
      return json({ error: "daily_limit_reached", limit: DAILY_MESSAGE_LIMIT }, 429);
    }

    // check feature flag in app_settings
    const { data: flag } = await supabase
      .from("app_settings")
      .select("value")
      .eq("key", "ai_tutor_enabled")
      .maybeSingle();
    if (flag && flag.value === false) {
      return json({ error: "feature_disabled" }, 403);
    }

    const systemPrompt =
      "أنت مدرّس ذكاء اصطناعي عراقي متخصص بالأمن السيبراني. اشرح باللهجة العراقية البسيطة، " +
      "التزم بالاستخدام الأخلاقي والقانوني فقط، ولا تقدّم أي مساعدة بأنشطة غير مصرح بها على أنظمة لا يملكها المستخدم.";

    const aiResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": AI_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 800,
        system: systemPrompt,
        messages: [{ role: "user", content: message }],
      }),
    });

    if (!aiResponse.ok) {
      return json({ error: "ai_provider_error" }, 502);
    }
    const aiJson = await aiResponse.json();
    const textBlock = (aiJson.content ?? []).find((b: any) => b.type === "text");
    const replyText: string = textBlock?.text ?? "";

    // log usage (message length only, no content stored)
    await supabase.from("ai_usage_logs").insert({
      user_id: userId,
      message_length: message.length,
    });

    return json({ reply: replyText });
  } catch (e) {
    return json({ error: "internal_error" }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}
