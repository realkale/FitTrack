-- FitTrack: Enforce unique display names
-- Run this in Supabase SQL Editor (New Query)
-- Run this BEFORE the group-invites migration, since invites rely on names being unique enough to search reliably.

-- First, check if any duplicates already exist — this query will show them, if any:
select display_name, count(*) 
from profiles 
group by display_name 
having count(*) > 1;

-- If the above returns any rows, resolve them manually (e.g. rename one of the
-- duplicates in the Table Editor) BEFORE running the constraint below, or the
-- next statement will fail.

-- Add the uniqueness constraint going forward
alter table profiles add constraint profiles_display_name_unique unique (display_name);
