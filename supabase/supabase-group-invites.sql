-- FitTrack: Group Invites (invite anyone in the app to a group you're in)
-- Run this in Supabase SQL Editor (New Query)

create table group_invites (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references groups(id) on delete cascade not null,
  invited_by uuid references profiles(id) on delete cascade not null,
  invitee_id uuid references profiles(id) on delete cascade not null,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz default now(),

  constraint no_self_invite check (invited_by <> invitee_id)
);

create index group_invites_invitee_idx on group_invites(invitee_id);
create index group_invites_group_idx on group_invites(group_id);

alter table group_invites enable row level security;

-- The invitee and the inviter can both see the invite
create policy "Participants can view their invites" on group_invites
  for select using (auth.uid() = invitee_id or auth.uid() = invited_by);

-- Any existing member of a group can invite someone (enforced: invited_by must be a member of group_id)
create policy "Group members can create invites" on group_invites
  for insert with check (
    auth.uid() = invited_by
    and exists (
      select 1 from group_members
      where group_members.group_id = group_invites.group_id
      and group_members.user_id = auth.uid()
    )
  );

-- Only the invitee can respond (accept/decline) to their own invite
create policy "Invitee can respond to their invite" on group_invites
  for update using (auth.uid() = invitee_id);

-- Support "search all users by name" for the invite picker.
-- Exposes only id + display_name — no email, no sensitive data.
create or replace view public_user_directory as
select id, display_name from profiles;

alter view public_user_directory owner to postgres;
