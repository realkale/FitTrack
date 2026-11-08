-- ─────────────────────────────────────────────────────────────────────────────
-- FitTrack · HYROX training tables
-- Run once in Supabase → SQL Editor → New query → paste → Run.
-- Safe to re-run: everything is "if not exists" / "drop policy if exists".
-- These are separate from `logs`, so leaderboards and challenges are untouched.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1) One row per logged HYROX effort (a station, an alternative, or a run)
create table if not exists public.hyrox_logs (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  station      text not null check (station in
                 ('run','ski','sled_push','sled_pull','bbj','row','farmers','lunges','wall_balls')),
  variant      text not null default 'official',   -- 'official' or an alternative id, e.g. 'band-pulldown'
  duration_sec integer check (duration_sec is null or duration_sec between 1 and 86400),
  amount       numeric check (amount is null or amount > 0),   -- metres, reps or km depending on unit
  unit         text,                                            -- 'm' | 'reps' | 'km'
  weight_kg    numeric check (weight_kg is null or weight_kg >= 0),
  notes        text check (notes is null or char_length(notes) <= 500),
  local_date   date not null,                                   -- local day bucket (same idea as logs.local_date)
  logged_at    timestamptz not null default now()
);

create index if not exists hyrox_logs_profile_date_idx
  on public.hyrox_logs (profile_id, local_date desc);

-- 2) Race settings (one row per person): division, race date, race name
create table if not exists public.hyrox_profile (
  profile_id  uuid primary key default auth.uid() references public.profiles(id) on delete cascade,
  division    text not null default 'open_m' check (division in ('open_w','open_m','pro_w','pro_m')),
  race_date   date,
  race_name   text check (race_name is null or char_length(race_name) <= 80),
  updated_at  timestamptz not null default now()
);

-- 3) Row Level Security: you can only see and change your own rows
alter table public.hyrox_logs    enable row level security;
alter table public.hyrox_profile enable row level security;

drop policy if exists "hyrox_logs own select" on public.hyrox_logs;
drop policy if exists "hyrox_logs own insert" on public.hyrox_logs;
drop policy if exists "hyrox_logs own update" on public.hyrox_logs;
drop policy if exists "hyrox_logs own delete" on public.hyrox_logs;
create policy "hyrox_logs own select" on public.hyrox_logs for select to authenticated using (profile_id = auth.uid());
create policy "hyrox_logs own insert" on public.hyrox_logs for insert to authenticated with check (profile_id = auth.uid());
create policy "hyrox_logs own update" on public.hyrox_logs for update to authenticated using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy "hyrox_logs own delete" on public.hyrox_logs for delete to authenticated using (profile_id = auth.uid());

drop policy if exists "hyrox_profile own select" on public.hyrox_profile;
drop policy if exists "hyrox_profile own insert" on public.hyrox_profile;
drop policy if exists "hyrox_profile own update" on public.hyrox_profile;
create policy "hyrox_profile own select" on public.hyrox_profile for select to authenticated using (profile_id = auth.uid());
create policy "hyrox_profile own insert" on public.hyrox_profile for insert to authenticated with check (profile_id = auth.uid());
create policy "hyrox_profile own update" on public.hyrox_profile for update to authenticated using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- 4) Explicit grants (same lesson as public_user_directory: don't rely on defaults)
grant select, insert, update, delete on public.hyrox_logs    to authenticated;
grant select, insert, update         on public.hyrox_profile to authenticated;
