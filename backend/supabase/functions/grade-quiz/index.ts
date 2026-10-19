// Supabase Edge Function: grade-quiz
// Grades a quiz attempt entirely server-side: the client sends only its
// selected options, never a score. This function fetches the real
// correct_option values with the service_role key (which bypasses RLS,
// so it can read what quiz_questions_select_admin_only hides from the
// client), computes the score, writes the quiz_attempts row, and — if the
// user passed — marks the lesson complete in lesson_progress.
//
// Deploy: supabase functions deploy grade-quiz

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "");
    if (!jwt) return json({ error: "unauthorized" }, 401);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) return json({ error: "unauthorized" }, 401);
    const userId = userData.user.id;

    const body = await req.json().catch(() => null);
    const lessonId: string | undefined = body?.lesson_id;
    const answers: Record<string, string> | undefined = body?.answers; // { question_id: option_id }
    if (!lessonId || !answers || typeof answers !== "object") {
      return json({ error: "missing_fields" }, 400);
    }

    const { data: lesson, error: lessonErr } = await admin
      .from("lessons")
      .select("id, pass_score, is_published")
      .eq("id", lessonId)
      .maybeSingle();
    if (lessonErr || !lesson || !lesson.is_published) {
      return json({ error: "lesson_not_found" }, 404);
    }

    const { data: questions, error: qErr } = await admin
      .from("quiz_questions")
      .select("id, correct_option, explanation")
      .eq("lesson_id", lessonId)
      .eq("is_published", true);
    if (qErr || !questions || questions.length === 0) {
      return json({ error: "no_questions" }, 404);
    }

    let correctCount = 0;
    const perQuestion = questions.map((q: any) => {
      const selected = answers[q.id];
      const isCorrect = selected != null && selected === q.correct_option;
      if (isCorrect) correctCount++;
      return {
        question_id: q.id,
        correct: isCorrect,
        correct_option: q.correct_option,
        explanation: q.explanation ?? null,
      };
    });

    const score = Math.round((correctCount / questions.length) * 100);
    const passed = score >= (lesson.pass_score ?? 70);

    await admin.from("quiz_attempts").insert({
      user_id: userId,
      lesson_id: lessonId,
      answers,
      score,
      passed,
    });

    if (passed) {
      await admin.from("lesson_progress").upsert(
        {
          user_id: userId,
          lesson_id: lessonId,
          is_completed: true,
          score,
          completed_at: new Date().toISOString(),
        },
        { onConflict: "user_id,lesson_id" },
      );
    }

    return json({ score, passed, pass_score: lesson.pass_score, results: perQuestion });
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
