-- ==========================================================
-- FitLog Pro - Supabase PostgreSQL Schema
-- Jalankan script ini di Supabase Dashboard -> SQL Editor
-- ==========================================================

-- 1. Tabel Profil Pengguna
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  email text not null,
  created_at timestamptz not null default now()
);

-- 2. Tabel Rencana Jadwal Mingguan (Workout Splits)
create table if not exists public.workout_plans (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text not null default '',
  days jsonb not null default '[]'::jsonb,
  is_active boolean not null default false,
  updated_at timestamptz not null default now()
);

-- 3. Tabel Riwayat Sesi Latihan Gym & Set Tercatat
create table if not exists public.workout_sessions (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  day_name text not null,
  session_date timestamptz not null default now(),
  duration_minutes int not null default 45,
  total_volume double precision not null default 0,
  sets jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

-- Index untuk query cepat per user
create index if not exists idx_workout_plans_user on public.workout_plans(user_id);
create index if not exists idx_workout_sessions_user_date on public.workout_sessions(user_id, session_date desc);

-- ==========================================================
-- Row Level Security (RLS) - Setiap user hanya akses datanya sendiri
-- ==========================================================
alter table public.profiles enable row level security;
alter table public.workout_plans enable row level security;
alter table public.workout_sessions enable row level security;

-- Policies: profiles
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users can upsert own profile" on public.profiles;
create policy "Users can upsert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Policies: workout_plans
drop policy if exists "Users manage own workout plans" on public.workout_plans;
create policy "Users manage own workout plans"
  on public.workout_plans for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Policies: workout_sessions
drop policy if exists "Users manage own workout sessions" on public.workout_sessions;
create policy "Users manage own workout sessions"
  on public.workout_sessions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
