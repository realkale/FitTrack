-- FitTrack Phase 3: Head-to-Head Challenges
-- Run this in Supabase SQL Editor (New Query)

create table challenges (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid references profiles(id) on delete cascade not null,
  opponent_id uuid references profiles(id) on delete cascade not null,
  exercise text not null check (exercise in ('pushups', 'pullups', 'situps')),
  target_count integer not null check (target_count > 0),
  status text not null default 'pending' check (status in ('pending', 'active', 'completed', 'declined')),
  winner_id uuid references profiles(id) on delete set null,
  started_at timestamptz,          -- set when opponent accepts; progress counts from this point forward
  completed_at timestamptz,
  created_at timestamptz default now(),

  constraint different_people check (creator_id <> opponent_id)
);

create index challenges_creator_idx on challenges(creator_id);
create index challenges_opponent_idx on challenges(opponent_id);
create index challenges_status_idx on challenges(status);

alter table challenges enable row level security;

-- Both people in a challenge can see it
create policy "Participants can view their challenges" on challenges
  for select using (auth.uid() = creator_id or auth.uid() = opponent_id);

-- Anyone logged in can create a challenge where they are the creator
create policy "Users can create challenges as creator" on challenges
  for insert with check (auth.uid() = creator_id);

-- Only the opponent can accept/decline (update status from pending),
-- and either participant can have the row updated when a winner is determined
create policy "Participants can update their challenges" on challenges
  for update using (auth.uid() = creator_id or auth.uid() = opponent_id);

-- Note: opponent selection happens entirely through shared groups in the app —
-- no email lookup or cross-account discovery mechanism is needed or provided.
-- The app will query group_members to find people who share a group with the
-- current user, then let them pick from that list.

