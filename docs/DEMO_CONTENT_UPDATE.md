# Demo content refresh

`supabase/demo_content_update.sql` is an optional manual refresh for an existing Cloud database. It is not a migration and must not be applied automatically.

It updates only the previous, source-controlled development fixture text for these stable IDs:

- Dogs: `10000000-0000-4000-8000-000000000001` through `...0003`
- Care icons: `20000000-0000-4000-8000-000000000001` through `...0004`
- Announcements: `30000000-0000-4000-8000-000000000001` and `...0002`
- Health records: `40000000-0000-4000-8000-000000000001` through `...0003`
- Optional seeded admin note: `50000000-0000-4000-8000-000000000001`

Each update also requires an exact match of the old fixture content. Rows that have been edited by a user, were created outside this fixture, or do not exist are left unchanged. No report, identity, credential, storage object, or unknown user-created record is modified.

To use it, review the file, open Supabase Dashboard → SQL Editor, then paste and execute it manually. Inspect the affected rows afterward. The script has not been executed by this project.
