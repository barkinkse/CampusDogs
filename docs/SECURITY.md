# Security

Anonymous users can select active dogs, public health data, public care information, active-dog locations, and published announcements. They can insert anonymous health reports and execute `submit_dog_location`, a validated security-definer RPC that upserts only a current point for an active dog. They cannot directly mutate profiles, collars, announcements, notes, or admin records.

Authenticated users are not automatically admins. Admins are defined solely by an `auth.users`-linked `admin_users` row, and both the dashboard guard and RLS use `is_admin()`. The helper is security-definer to avoid recursive RLS, has an explicit safe search path, and returns only a boolean. Function privileges are explicitly limited to `anon` and `authenticated` rather than default `PUBLIC`.

Anonymous users cannot access `admin_users` or `admin_notes`; no policy permits it. Private health records and notes are administrator-only. Browser clients have no policy that can insert into `admin_users`; admin creation must use a trusted server-side/Edge Function flow. Note inserts require the current admin as author and attribution cannot be rewritten. Service-role credentials are server-only and excluded from source and environment templates.

`submit_dog_location` is intentionally not proof of collar proximity. It validates coordinates and active dogs and records no member identity, but the backend cannot independently validate a client claim until hardware/protocol decisions exist. See Bluetooth Design for planned anti-abuse controls.

Phase 2 migration 003 creates private `report-images` and `announcement-images` buckets. Anonymous upload access is limited to report-image extensions and a 5 MB metadata limit; there is no anonymous read policy and no public URL. Administrators access objects only through their `is_admin()` RLS policy. Apply this migration before implementing client image uploads.

Migration 004 requires a non-empty, numeric Storage size metadata field, validates MIME type, and constrains anonymous report-image object paths to `anonymous/…`. The repository implementation re-encodes selected photos as JPEG, enforces the 5 MB limit before upload, sends matching metadata, then stores only the resulting private path on `member_reports`. A failed image upload does not silently submit a text-only replacement.

The current member UI leaves photo selection disabled because the configured Cloud project rejected a migration-004-compatible anonymous private-image probe with Storage RLS. Text-only reports remain enabled. Re-enable the UI only after an administrator verifies the deployed `storage.objects` policy with the same anonymous client contract.

`announcement-images` is also private and has no anonymous object-read policy. The member announcements view therefore never manufactures a public URL or exposes a private image; it shows the published title, body, and date. To show announcement images to anonymous members, the backend would need a deliberately designed, access-controlled delivery mechanism rather than a client-side policy relaxation.

Administrator invitation is server-only: the dashboard invokes the `invite-admin` Edge Function with the current access token, and the function verifies `is_admin()` before using the service-role Admin API. The browser never writes `admin_users` and never receives a service-role credential. Report workflow statuses and admin notes are internal-only; anonymous members have neither report history nor a policy to read `member_reports` or `admin_notes`.
