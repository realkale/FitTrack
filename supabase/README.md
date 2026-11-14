# Supabase migrations

SQL for the FitTrack database (project ref `kljejjngnqwayteprhea`). Run each file in the Supabase SQL Editor, in this order:

1. `supabase-setup.sql`: Phase 1 tables (`logs`, etc.)
2. `supabase-migration-groups.sql`: Supabase Auth, profiles, groups, legacy-data claim
3. `supabase-challenges.sql`: Phase 3 head-to-head challenges
4. `supabase-unique-names.sql`: unique display names (must run before invites)
5. `supabase-group-invites.sql`: group invites and the `public_user_directory` view
6. `supabase-fix-user-directory.sql`: recreates `public_user_directory` with explicit grants
7. `hyrox.sql`: HYROX training tables (`hyrox_logs`, `hyrox_profile`)
8. `murph.sql`: Murph runs and attempts (`murph_logs`), plus `vest` and `murph_log_id` on `logs`

Steps 1–6 were already applied to the live project. The `group_invites` table from step 5 never got created the first time; its table section was rerun on 2026-10-31. Keep them here so a fresh project can be rebuilt from scratch.
