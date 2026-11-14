-- ─────────────────────────────────────────────────────────────────────────────
-- FitTrack · Murph training, squats, and weighted-vest sets
-- Run once in Supabase → SQL Editor → New query → paste → Run.
-- Safe to re-run, and safe whether or not an earlier draft of this file was run.
--
-- Pull-ups, push-ups and squats logged for Murph go into `logs` like any other
-- set, so they count toward daily totals, leaderboards and challenges. This file:
--   1. adds squats as a fourth everyday exercise (logs + challenges)
--   2. records the vest weight on every set (`logs.vest_lb`, null = no vest)
--   3. adds `murph_logs` for the parts that aren't reps: runs and full attempts
-- ─────────────────────────────────────────────────────────────────────────────

-- 1) Squats: widen the exercise checks on logs and challenges
do $$
declare r record;
begin
  for r in
    select conrelid::regclass as tbl, conname
    from pg_constraint
    where contype = 'c'
      and conrelid in ('public.logs'::regclass, 'public.challenges'::regclass)
      and pg_get_constraintdef(oid) like '%situps%'
  loop
    execute format('alter table %s drop constraint %I', r.tbl, r.conname);
  end loop;
end $$;
alter table public.logs
  add constraint logs_exercise_check check (exercise in ('pushups', 'pullups', 'situps', 'squats'));
alter table public.challenges
  add constraint challenges_exercise_check check (exercise in ('pushups', 'pullups', 'situps', 'squats'));

-- 2) One row per run or full Murph attempt
create table if not exists public.murph_logs (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  kind         text not null check (kind in ('run', 'attempt')),
  distance_mi  numeric check (distance_mi is null or (distance_mi > 0 and distance_mi <= 50)),  -- runs only
  duration_sec integer check (duration_sec is null or duration_sec between 1 and 86400),
  notes        text check (notes is null or char_length(notes) <= 500),
  local_date   date not null,
  logged_at    timestamptz not null default now(),
  constraint attempt_has_time check (kind <> 'attempt' or duration_sec is not null),
  constraint run_has_distance check (kind <> 'run' or distance_mi is not null)
);
create index if not exists murph_logs_profile_date_idx
  on public.murph_logs (profile_id, local_date desc);

-- 3) Vest weight in pounds (null = no vest), on runs/attempts and on every set
alter table public.murph_logs add column if not exists vest_lb numeric check (vest_lb is null or (vest_lb > 0 and vest_lb <= 100));
alter table public.logs       add column if not exists vest_lb numeric check (vest_lb is null or (vest_lb > 0 and vest_lb <= 100));

-- An earlier draft stored a yes/no `vest` column: carry it over as 20 lb, then drop it
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'murph_logs' and column_name = 'vest') then
    update public.murph_logs set vest_lb = 20 where vest and vest_lb is null;
    alter table public.murph_logs drop column vest;
  end if;
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'logs' and column_name = 'vest') then
    update public.logs set vest_lb = 20 where vest and vest_lb is null;
    alter table public.logs drop column vest;
  end if;
end $$;

-- 4) Reps from a full attempt point back at it. Deleting the attempt keeps the
--    reps (they were really done); the link is just cleared.
alter table public.logs add column if not exists murph_log_id uuid;
alter table public.logs drop constraint if exists logs_murph_log_id_fkey;
alter table public.logs add constraint logs_murph_log_id_fkey
  foreign key (murph_log_id) references public.murph_logs(id) on delete set null;

-- 5) Row Level Security: you can only see and change your own Murph rows
alter table public.murph_logs enable row level security;

drop policy if exists "murph_logs own select" on public.murph_logs;
drop policy if exists "murph_logs own insert" on public.murph_logs;
drop policy if exists "murph_logs own delete" on public.murph_logs;
create policy "murph_logs own select" on public.murph_logs for select to authenticated using (profile_id = auth.uid());
create policy "murph_logs own insert" on public.murph_logs for insert to authenticated with check (profile_id = auth.uid());
create policy "murph_logs own delete" on public.murph_logs for delete to authenticated using (profile_id = auth.uid());

-- 6) Explicit grants (same lesson as public_user_directory: don't rely on defaults)
grant select, insert, delete on public.murph_logs to authenticated;

notify pgrst, 'reload schema';
