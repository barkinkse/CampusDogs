# First administrator setup

1. In Supabase Dashboard, create the first user under **Authentication → Users** (or send an invite).
2. Copy that user’s UUID.
3. In the SQL Editor, run this once using a trusted administrator session:

```sql
insert into public.admin_users (id) values ('AUTH_USER_UUID');
```

4. Apply the Phase 2 migration after the existing two migrations:

```sql
-- Run supabase/migrations/202611040003_phase2_storage_and_workflow.sql
```

5. Deploy the invitation function only when ready:

```sh
supabase functions deploy invite-admin
```

The Edge Function uses the Supabase-managed `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` environment values. Do not put the service-role key in a browser, iOS app, Vercel variable, or repository. Auth email invitations require a working Supabase SMTP configuration for reliable delivery.

After deployment, an existing administrator can invite another administrator from **Admin Yönetimi**. The browser calls `invite-admin` with its current session; the function verifies `is_admin()`, validates the email, provisions the Auth invitation, and inserts `admin_users` only on the server. Configure Auth redirect URLs and SMTP before relying on invitation delivery.
