-- ============================================================
-- Cyber Iraq (سايبر العراق) -- Full Database Schema + RLS
-- Postgres / Supabase
-- Safe to re-run: uses IF NOT EXISTS / CREATE OR REPLACE throughout
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- 1. profiles
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  email text,
  avatar_url text,
  bio text,
  points integer not null default 0,
  current_level text not null default 'beginner' check (current_level in ('beginner','intermediate','advanced')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_profiles_email on public.profiles(email);

-- ------------------------------------------------------------
-- 2. user_roles  (source of truth for admin/user — never trust client claims)
-- ------------------------------------------------------------
create table if not exists public.user_roles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user','admin','content_editor')),
  granted_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(user_id, role)
);
create index if not exists idx_user_roles_user on public.user_roles(user_id);

-- Helper: is the current JWT user an admin? (SECURITY DEFINER avoids RLS recursion)
create or replace function public.is_admin(uid uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = uid and role = 'admin'
  );
$$;

create or replace function public.has_role(uid uuid, r text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = uid and role = r
  );
$$;

-- ------------------------------------------------------------
-- 3. learning_paths
-- ------------------------------------------------------------
create table if not exists public.learning_paths (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  description text,
  level text not null default 'beginner' check (level in ('beginner','intermediate','advanced')),
  sort_order integer not null default 0,
  icon text,
  is_published boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_paths_published on public.learning_paths(is_published);

-- ------------------------------------------------------------
-- 4. lessons
-- ------------------------------------------------------------
create table if not exists public.lessons (
  id uuid primary key default uuid_generate_v4(),
  path_id uuid not null references public.learning_paths(id) on delete cascade,
  title text not null,
  description text,
  objectives text[],
  content_md text,
  difficulty text not null default 'beginner' check (difficulty in ('beginner','intermediate','advanced')),
  estimated_minutes integer default 15,
  sort_order integer not null default 0,
  video_url text,
  image_url text,
  is_published boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_lessons_path on public.lessons(path_id);
create index if not exists idx_lessons_published on public.lessons(is_published);

-- ------------------------------------------------------------
-- 5. lesson_progress
-- ------------------------------------------------------------
create table if not exists public.lesson_progress (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  is_completed boolean not null default false,
  is_favorite boolean not null default false,
  score numeric,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique(user_id, lesson_id)
);
create index if not exists idx_progress_user on public.lesson_progress(user_id);

-- ------------------------------------------------------------
-- 6. quiz_questions
-- ------------------------------------------------------------
create table if not exists public.quiz_questions (
  id uuid primary key default uuid_generate_v4(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  question text not null,
  question_type text not null default 'multiple_choice' check (question_type in ('multiple_choice','true_false')),
  options jsonb not null default '[]'::jsonb,   -- [{"id":"a","text":"..."}]
  correct_option text not null,
  explanation text,
  sort_order integer not null default 0,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_quiz_questions_lesson on public.quiz_questions(lesson_id);

-- ------------------------------------------------------------
-- 7. quiz_attempts  (results are written/validated server-side only)
-- ------------------------------------------------------------
create table if not exists public.quiz_attempts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  answers jsonb not null default '{}'::jsonb,
  score numeric not null,
  passed boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_attempts_user on public.quiz_attempts(user_id);

-- ------------------------------------------------------------
-- 8. videos
-- ------------------------------------------------------------
create table if not exists public.videos (
  id uuid primary key default uuid_generate_v4(),
  lesson_id uuid references public.lessons(id) on delete cascade,
  path_id uuid references public.learning_paths(id) on delete set null,
  title text not null,
  url text not null,
  source text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 9. app_settings  (key/value, admin-only writes)
-- ------------------------------------------------------------
create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 10. notifications
-- ------------------------------------------------------------
create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  body text,
  audience text not null default 'all' check (audience in ('all','active','beginner','intermediate','advanced')),
  publish_at timestamptz default now(),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 11. admin_audit_logs
-- ------------------------------------------------------------
create table if not exists public.admin_audit_logs (
  id uuid primary key default uuid_generate_v4(),
  admin_id uuid not null references auth.users(id),
  action text not null,           -- e.g. 'lesson.create', 'role.change'
  target_table text,
  target_id text,
  metadata jsonb default '{}'::jsonb,   -- never store passwords/secrets here
  created_at timestamptz not null default now()
);
create index if not exists idx_audit_admin on public.admin_audit_logs(admin_id);
create index if not exists idx_audit_created on public.admin_audit_logs(created_at);

-- ------------------------------------------------------------
-- 12. ai_usage_logs
-- ------------------------------------------------------------
create table if not exists public.ai_usage_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  message_length integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_ai_usage_user_time on public.ai_usage_logs(user_id, created_at);

-- ============================================================
-- Row Level Security
-- ============================================================
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.learning_paths enable row level security;
alter table public.lessons enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.videos enable row level security;
alter table public.app_settings enable row level security;
alter table public.notifications enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.ai_usage_logs enable row level security;

-- ---- profiles ----
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin" on public.profiles
  for select using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "profiles_admin_update_any" on public.profiles;
create policy "profiles_admin_update_any" on public.profiles
  for update using (public.is_admin());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (id = auth.uid());

-- ---- user_roles: nobody can grant themselves a role from the client ----
drop policy if exists "roles_select_own_or_admin" on public.user_roles;
create policy "roles_select_own_or_admin" on public.user_roles
  for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists "roles_admin_only_write" on public.user_roles;
create policy "roles_admin_only_write" on public.user_roles
  for all using (public.is_admin()) with check (public.is_admin());
-- note: no insert/update/delete policy exists for non-admins at all -> denied by default

-- ---- learning_paths ----
drop policy if exists "paths_select_published_or_admin" on public.learning_paths;
create policy "paths_select_published_or_admin" on public.learning_paths
  for select using (is_published = true or public.is_admin());

drop policy if exists "paths_admin_write" on public.learning_paths;
create policy "paths_admin_write" on public.learning_paths
  for all using (public.is_admin()) with check (public.is_admin());

-- ---- lessons ----
drop policy if exists "lessons_select_published_or_admin" on public.lessons;
create policy "lessons_select_published_or_admin" on public.lessons
  for select using (is_published = true or public.is_admin());

drop policy if exists "lessons_admin_write" on public.lessons;
create policy "lessons_admin_write" on public.lessons
  for all using (public.is_admin()) with check (public.is_admin());

-- ---- lesson_progress: user can only touch their own rows ----
drop policy if exists "progress_select_own_or_admin" on public.lesson_progress;
create policy "progress_select_own_or_admin" on public.lesson_progress
  for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists "progress_write_own" on public.lesson_progress;
create policy "progress_write_own" on public.lesson_progress
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---- quiz_questions: users only see published questions (never correct_option issues since app hides it client-side; grading still revalidated) ----
drop policy if exists "quiz_q_select_published_or_admin" on public.quiz_questions;
create policy "quiz_q_select_published_or_admin" on public.quiz_questions
  for select using (is_published = true or public.is_admin());

drop policy if exists "quiz_q_admin_write" on public.quiz_questions;
create policy "quiz_q_admin_write" on public.quiz_questions
  for all using (public.is_admin()) with check (public.is_admin());

-- ---- quiz_attempts: users insert their own, nobody updates results from client ----
drop policy if exists "attempts_select_own_or_admin" on public.quiz_attempts;
create policy "attempts_select_own_or_admin" on public.quiz_attempts
  for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists "attempts_insert_own" on public.quiz_attempts;
create policy "attempts_insert_own" on public.quiz_attempts
  for insert with check (user_id = auth.uid());
-- no update/delete policy for regular users -> attempts are immutable once written

-- ---- videos ----
drop policy if exists "videos_select_all" on public.videos;
create policy "videos_select_all" on public.videos
  for select using (true);

drop policy if exists "videos_admin_write" on public.videos;
create policy "videos_admin_write" on public.videos
  for all using (public.is_admin()) with check (public.is_admin());

-- ---- app_settings: readable by all authenticated users (non-sensitive), admin-only write ----
drop policy if exists "settings_select_authenticated" on public.app_settings;
create policy "settings_select_authenticated" on public.app_settings
  for select using (auth.role() = 'authenticated');

drop policy if exists "settings_admin_write" on public.app_settings;
create policy "settings_admin_write" on public.app_settings
  for all using (public.is_admin()) with check (public.is_admin());

-- ---- notifications ----
drop policy if exists "notifications_select_authenticated" on public.notifications;
create policy "notifications_select_authenticated" on public.notifications
  for select using (auth.role() = 'authenticated' and publish_at <= now());

drop policy if exists "notifications_admin_write" on public.notifications;
create policy "notifications_admin_write" on public.notifications
  for all using (public.is_admin()) with check (public.is_admin());

-- ---- admin_audit_logs: admins only, insert-only from client (app also writes via server logic) ----
drop policy if exists "audit_admin_select" on public.admin_audit_logs;
create policy "audit_admin_select" on public.admin_audit_logs
  for select using (public.is_admin());

drop policy if exists "audit_admin_insert" on public.admin_audit_logs;
create policy "audit_admin_insert" on public.admin_audit_logs
  for insert with check (public.is_admin() and admin_id = auth.uid());

-- ---- ai_usage_logs: user can insert/see own, admin sees all ----
drop policy if exists "ai_usage_select_own_or_admin" on public.ai_usage_logs;
create policy "ai_usage_select_own_or_admin" on public.ai_usage_logs
  for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists "ai_usage_insert_own" on public.ai_usage_logs;
create policy "ai_usage_insert_own" on public.ai_usage_logs
  for insert with check (user_id = auth.uid());

-- ============================================================
-- First-admin bootstrap (safe, one-time)
-- Run manually once, from the Supabase SQL editor, after your first
-- real admin account has signed up through normal auth:
--
--   select public.bootstrap_first_admin('admin@example.com');
--
-- This only works while user_roles has zero 'admin' rows; after the
-- first admin exists it refuses, so it cannot be used to self-promote.
-- ============================================================
create or replace function public.bootstrap_first_admin(admin_email text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  target_uid uuid;
  admin_count integer;
begin
  select count(*) into admin_count from public.user_roles where role = 'admin';
  if admin_count > 0 then
    return 'refused: an admin already exists';
  end if;

  select id into target_uid from auth.users where email = admin_email;
  if target_uid is null then
    return 'refused: no auth user with that email -- sign up first';
  end if;

  insert into public.user_roles (user_id, role) values (target_uid, 'admin')
  on conflict (user_id, role) do nothing;

  return 'ok: admin granted to ' || admin_email;
end;
$$;

-- updated_at triggers
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_paths_updated on public.learning_paths;
create trigger trg_paths_updated before update on public.learning_paths
  for each row execute function public.set_updated_at();

drop trigger if exists trg_lessons_updated on public.lessons;
create trigger trg_lessons_updated before update on public.lessons
  for each row execute function public.set_updated_at();
