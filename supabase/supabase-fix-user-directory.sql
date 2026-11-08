-- Fix: create the missing public_user_directory view, with explicit grants
-- Run this in Supabase SQL Editor

create or replace view public_user_directory as
select id, display_name from profiles;

-- Explicit grants — views need these separately from RLS policies on the
-- underlying table, otherwise the anon/authenticated roles can't query them.
grant select on public_user_directory to anon, authenticated;

-- Quick test — should return your own row and any other signed-up users
select id, display_name from public_user_directory limit 10;
