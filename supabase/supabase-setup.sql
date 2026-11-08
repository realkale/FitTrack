-- FitTrack Phase 1: Database Setup
-- Run this in Supabase's SQL Editor (left sidebar → SQL Editor → New Query)

-- 1. Users table: simple sign-in with name + private access code
create table users (
  id uuid primary key default gen_random_uuid(),
  display_name text not null unique,
  access_code text not null,
  created_at timestamptz default now()
);

-- 2. Logs table: every logged set, shared across all users
create table logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  exercise text not null check (exercise in ('pushups', 'pullups', 'situps')),
  count integer not null check (count > 0),
  logged_at timestamptz default now(),
  local_date text not null  -- e.g. '2026-07-04', calculated client-side using local time
);

-- Index for fast lookups by user and date (used constantly by the app)
create index logs_user_date_idx on logs(user_id, local_date);

-- 3. Row Level Security: allow read/write but scoped sensibly
-- (Keeping this simple for a friend group — everyone can read everyone's logs
--  for the leaderboard, but can only insert their own)
alter table users enable row level security;
alter table logs enable row level security;

create policy "Anyone can view users" on users
  for select using (true);

create policy "Anyone can create their own user" on users
  for insert with check (true);

create policy "Anyone can view all logs" on logs
  for select using (true);

create policy "Users can insert their own logs" on logs
  for insert with check (true);

create policy "Users can delete their own logs" on logs
  for delete using (true);
