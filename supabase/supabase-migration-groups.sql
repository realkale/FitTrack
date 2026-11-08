-- FitTrack: Migration to Supabase Auth + Groups
-- Run this in Supabase SQL Editor (New Query)

-- ─────────────────────────────────────────────────────────────────────────
-- 1. PROFILES TABLE (linked to Supabase Auth users)
-- ─────────────────────────────────────────────────────────────────────────
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  claimed_legacy boolean default false,  -- true once old data has been claimed
  created_at timestamptz default now()
);

alter table profiles enable row level security;

create policy "Anyone can view profiles" on profiles
  for select using (true);

create policy "Users can insert their own profile" on profiles
  for insert with check (auth.uid() = id);

create policy "Users can update their own profile" on profiles
  for update using (auth.uid() = id);

-- ─────────────────────────────────────────────────────────────────────────
-- 2. GROUPS TABLES
-- ─────────────────────────────────────────────────────────────────────────
create table groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  join_code text not null unique,  -- short, memorable, e.g. SWOLE4F2A
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz default now()
);

create table group_members (
  group_id uuid references groups(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  joined_at timestamptz default now(),
  primary key (group_id, user_id)
);

alter table groups enable row level security;
alter table group_members enable row level security;

create policy "Anyone can view groups" on groups
  for select using (true);

create policy "Authenticated users can create groups" on groups
  for insert with check (auth.uid() = created_by);

create policy "Anyone can view memberships" on group_members
  for select using (true);

create policy "Users can join groups themselves" on group_members
  for insert with check (auth.uid() = user_id);

create policy "Users can leave groups themselves" on group_members
  for delete using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. UPDATE LOGS TABLE to reference profiles instead of the old users table
-- ─────────────────────────────────────────────────────────────────────────
-- Add a new column pointing to profiles; keep old user_id temporarily for migration
alter table logs add column profile_id uuid references profiles(id) on delete cascade;
create index logs_profile_date_idx on logs(profile_id, local_date);

-- Update RLS to use profile_id going forward
drop policy if exists "Anyone can view all logs" on logs;
drop policy if exists "Users can insert their own logs" on logs;
drop policy if exists "Users can delete their own logs" on logs;

create policy "Anyone can view all logs" on logs
  for select using (true);

create policy "Users can insert their own logs" on logs
  for insert with check (auth.uid() = profile_id);

create policy "Users can delete their own logs" on logs
  for delete using (auth.uid() = profile_id);

-- ─────────────────────────────────────────────────────────────────────────
-- 4. Keep the OLD `users` table as-is for now — needed for "claim my old data"
--    lookups (matching by display_name). Do not drop it yet.
-- ─────────────────────────────────────────────────────────────────────────
-- (No action needed — just leaving a note here for your own reference.)

-- ─────────────────────────────────────────────────────────────────────────
-- 5. Function + policy to support "claim legacy data" safely
--    This lets a logged-in user pull old logs matching their claimed old name
--    into their new profile_id, but only once (claimed_legacy flag prevents repeats)
-- ─────────────────────────────────────────────────────────────────────────
create or replace function claim_legacy_logs(old_display_name text)
returns integer
language plpgsql
security definer
as $$
declare
  old_user_id uuid;
  rows_updated integer;
  already_claimed boolean;
begin
  -- Prevent double-claiming
  select claimed_legacy into already_claimed from profiles where id = auth.uid();
  if already_claimed then
    raise exception 'Legacy data already claimed for this account';
  end if;

  -- Find the old user by display name
  select id into old_user_id from users where display_name = old_display_name;
  if old_user_id is null then
    return 0;
  end if;

  -- Move their logs to the new profile
  update logs set profile_id = auth.uid()
  where user_id = old_user_id and profile_id is null;

  get diagnostics rows_updated = row_count;

  update profiles set claimed_legacy = true where id = auth.uid();

  return rows_updated;
end;
$$;
