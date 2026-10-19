-- ============================================================
-- Quiz security hardening
-- Problem fixed: the original RLS let any authenticated user SELECT the
-- full quiz_questions row (including correct_option) directly from the
-- client, and let them INSERT their own quiz_attempts with any score they
-- liked. This migration closes both holes:
--   1. quiz_questions is now admin-only to SELECT directly; regular users
--      only ever see questions through get_published_quiz_questions(),
--      which omits correct_option and explanation.
--   2. quiz_attempts can no longer be inserted by the client at all —
--      only the grade-quiz Edge Function (using the service_role key,
--      which bypasses RLS) can write a result, after grading server-side.
-- ============================================================

alter table public.lessons add column if not exists pass_score integer not null default 70;

-- ---- quiz_questions: remove the public select, admin-only from here on ----
drop policy if exists "quiz_q_select_published_or_admin" on public.quiz_questions;
drop policy if exists "quiz_q_select_admin_only" on public.quiz_questions;
create policy "quiz_q_select_admin_only" on public.quiz_questions
  for select using (public.is_admin());
-- quiz_q_admin_write policy (insert/update/delete, admin-only) is unchanged.

-- Safe, answer-free question list for the quiz screen.
create or replace function public.get_published_quiz_questions(p_lesson_id uuid)
returns table (
  id uuid,
  question text,
  question_type text,
  options jsonb,
  sort_order integer
)
language sql
security definer
set search_path = public
stable
as $$
  select q.id, q.question, q.question_type, q.options, q.sort_order
  from public.quiz_questions q
  join public.lessons l on l.id = q.lesson_id
  where q.lesson_id = p_lesson_id
    and q.is_published = true
    and l.is_published = true
  order by q.sort_order;
$$;

grant execute on function public.get_published_quiz_questions(uuid) to authenticated;

-- ---- quiz_attempts: no client-side inserts anymore ----
drop policy if exists "attempts_insert_own" on public.quiz_attempts;
-- No insert policy remains for regular users: writes only happen via the
-- grade-quiz Edge Function using the service_role key, which bypasses RLS.
-- "attempts_select_own_or_admin" (read-only, own rows or admin) is unchanged.
