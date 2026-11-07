# Phase 1 Security & Backend Verification Audit

Date: 2026-11-04. This is an audit-only report. No application source, migration, Cloud policy, account, object, or database row was changed.

## Executive assessment

The intended authorization model is sound in several important areas: data-bearing admin operations are RLS-gated by `public.is_admin()`, notes require authenticated author attribution, member reports do not expose reporter identity, and master-admin provisioning is implemented server-side in `create-admin`. Anonymous live read checks confirmed that private health records, member reports, admin notes, admin users, inactive dogs, and draft announcements are not returned.

There is one confirmed **High** data-integrity risk: `public.submit_dog_location` is executable by anonymous clients and accepts arbitrary in-range coordinates for any active dog. It does not authenticate a collar, validate hardware origin, rate-limit, or establish location plausibility. Bluetooth is out of scope; therefore the safest temporary behavior is to remove anonymous execution from the deployed function or otherwise disable member-originated location writes until a verifiable hardware/server ingestion path exists. This report does not make that change.

The report also found a **Medium** authorization-verification anomaly: anonymous API invocation of `is_super_admin()` returned `false` with HTTP 200, although migration 005 grants it only to `authenticated`. The function returns only a boolean, so this is not known privilege escalation, but actual Cloud function privileges must be inspected before relying on the intended restriction.

## Evidence and scope

Reviewed: migrations `001`–`006`, `supabase/functions/create-admin/index.ts`, `ProtectedRoute.tsx`, `AdminLayout.tsx`, `AdminsPage.tsx`, `adminRepository.ts`, and the public Supabase client configuration. Live requests used only the configured project's publishable key and did not perform a successful write.

Executed live checks:

| Check | Actual result | Status |
| --- | --- | --- |
| Anonymous `is_admin()` | HTTP 200, `false` | Verified |
| Anonymous `is_super_admin()` | HTTP 200, `false` | Verified; privilege expectation needs review |
| Anonymous `submit_dog_location` with latitude `91` | HTTP 400, database exception `Invalid coordinates` | Verified execution reached function validation; no write occurred |
| Anonymous reads of active dogs/public health/icons/published announcements | Returned expected public rows | Previously verified, retained evidence |
| Anonymous reads of private health/reports/notes/admin users/inactive dogs/drafts | Returned zero rows | Previously verified, retained evidence |

No authenticated normal-admin or master-admin credentials were supplied. Consequently, positive admin behavior, authenticated non-admin rejection, Edge Function deployment, and Storage writes are **not verified**.

## Role-based authorization matrix

“DB” means current migration policy/function logic. “UI” means a browser/iOS visibility guard only; it is never treated as the security boundary.

| Resource / operation | Anonymous | Normal admin | Master admin | Enforced by | Verification |
| --- | --- | --- | --- | --- | --- |
| `dogs` SELECT | Active rows only | All rows | All rows | DB RLS, 001:81 | Anon verified; admin not verified |
| `dogs` INSERT/UPDATE/DELETE | Denied | Allowed | Allowed | DB RLS `is_admin()` | Not verified with roles |
| `health_records` SELECT | `is_public=true` only | All | All | DB RLS, 001:84 | Anon verified; admin not verified |
| `health_records` write | Denied | Allowed | Allowed | DB RLS | Not verified |
| `care_icons` SELECT | Allowed | Allowed | Allowed | DB RLS, 001:85 | Anon verified |
| `care_icons` write | Denied | Allowed | Allowed | DB RLS | Not verified |
| `dog_care_icons` SELECT | Active-dog joins | All | All | DB RLS, 001:86 | Derived from policy; not direct tested |
| `dog_care_icons` write | Denied | Allowed | Allowed | DB RLS | Not verified |
| `dog_locations` SELECT | Only active-dog rows | All | All | DB RLS, 001:83 | Anon verified with zero current rows |
| `dog_locations` direct write | Denied | Allowed | Allowed | DB RLS | Not verified |
| `submit_dog_location` RPC | **Allowed**; valid in-range arbitrary point for active dog would upsert | Allowed | Allowed | Function grant + `SECURITY DEFINER`, 002:17–31 | Anon execution verified safely with invalid point |
| `member_reports` INSERT | Allowed for active dog; no identity field | Same | Same | DB RLS, 001:87 | Policy inspected; successful write not attempted |
| `member_reports` SELECT/UPDATE/DELETE | Denied | Allowed | Allowed | DB RLS | Anon SELECT verified; admin not verified |
| `admin_notes` SELECT | Denied | Allowed | Allowed | DB RLS, 002:47 | Anon SELECT verified |
| `admin_notes` INSERT | Denied | Allowed only with `author_id=auth.uid()` | Same | DB RLS, 002:48 + immutable trigger | Not verified with admin |
| `admin_notes` UPDATE/DELETE | Denied | Allowed | Allowed | DB RLS, 002:49–50 | Not verified |
| `announcements` SELECT | Published only | All | All | DB RLS, 001:89 | Anon verified |
| `announcements` write | Denied | Allowed | Allowed | DB RLS | Not verified |
| `admin_users` direct client read/write | Denied | Denied | Denied | RLS enabled; broad policy removed in 002:5; no replacement policy | Anon SELECT verified; role behavior inferred from policy |
| `is_admin()` | Returns boolean | Returns boolean | Returns boolean | `SECURITY DEFINER`, 002:9–13 | Anon false verified |
| `is_super_admin()` | Expected no execute; live returns false | Expected boolean | Expected boolean | 005:16–20 | Anon false response verified; grant anomaly unresolved |
| `create-admin` Edge Function | Missing/invalid bearer rejected | Server rejects unless `is_super_admin()` true | Creates Auth user + non-super admin row | Edge Function server-side check | Source inspected; deployment and calls not verified |
| `dog-images` read | Public object URL | Public object URL | Public object URL | Public bucket | Public real object HTTP 200 previously verified |
| `dog-images` INSERT/UPDATE/DELETE | Denied | Allowed only under `dogs/{folder}/{file}` + extension | Same | Storage RLS, 006:8–47 | Policy inspected; write behavior not verified |
| `report-images` INSERT | Allowed only for constrained `anonymous/%` image metadata | Same; admins broader management | Same | Storage RLS, 004 | Not tested; member UI is text-only |
| `announcement-images` management | Denied | Allowed | Allowed | Storage RLS, 003:19–21 | Not tested |

## Security findings

### High — anonymous callers can inject arbitrary public dog locations

**Evidence:** `submit_dog_location` is granted to `anon, authenticated` in `202611040002_security_hardening.sql:17–18`. Its body in lines 19–31 checks only non-null/range coordinates and whether the target dog is active, then upserts `dog_locations`. A live anonymous invalid-coordinate call produced `Invalid coordinates`, proving anonymous invocation reaches function validation.

**Impact:** Any anonymous actor can submit a valid latitude/longitude for a known active dog. The map exposes these records to other anonymous users. This enables false sightings, reputation harm, and data-integrity abuse; it is not a real collar/location proof.

**Temporary remediation:** revoke `anon` execution (and preferably all mobile-client execution) or disable location publishing until a trusted ingestion design is available. A future design should authenticate registered collar/server data, verify timestamps/accuracy, rate-limit, reject implausible movement, and audit writes. This requires a reviewed sequential migration and is explicitly not implemented by this audit.

### Medium — `is_super_admin()` anonymous execution differs from migration intent

**Evidence:** migration 005 lines 16–20 revokes `PUBLIC` and grants only `authenticated`. Yet an anonymous publishable-key RPC returned HTTP 200 `false`.

**Impact:** The returned value alone does not reveal user data or grant privileges. The `create-admin` Function independently requires a valid user and `master===true`, so no privilege escalation was demonstrated. Nevertheless it indicates Cloud function-grant drift, role behavior, or an assumption that needs verification.

**Remediation:** an authorized database operator should inspect actual function ACLs and `pg_proc.proacl`, then compare to migration 005. Do not change privileges before confirming the deployed state.

### Medium — anonymous member report insertion is intentionally unauthenticated and abuse-prone

**Evidence:** migration 001 line 87 permits `anon, authenticated` INSERT when the dog is active. Schema checks description length only (001:44–47). There is no identity, rate limit, CAPTCHA, moderation queue rule beyond initial `status='new'`, or server-side abuse control.

**Impact:** This supports the anonymous product requirement but permits spam against active dogs.

**Remediation:** retain anonymity but add an abuse-control design before broad release (edge proxy/rate limit, anti-automation control, content moderation workflow). This is a product/security trade-off, not a confirmed RLS bypass.

### Medium — authorization cannot be fully established from frontend guards

**Evidence:** `ProtectedRoute.tsx:15–18`, `AdminLayout.tsx:10–12`, and `AdminsPage.tsx:2` enforce useful UI behavior. RLS and the Edge Function are the actual authorization layers. No normal-admin/master-admin API calls were executed.

**Impact:** A UI test alone cannot establish that direct PostgREST/Function calls are protected.

**Remediation:** run a controlled three-role API test matrix before release; retain the database/Edge Function checks even if UI changes.

### Low — service-role usage is correctly isolated in source, deploy state unknown

**Evidence:** browser and iOS configuration only name publishable keys (`apps/admin/src/services/supabase.ts`, `SupabaseConfiguration.swift`). `SUPABASE_SERVICE_ROLE_KEY` appears only in Edge Function sources (`create-admin`, legacy `invite-admin`).

**Impact:** No client-side service-role exposure was found in inspected source. Function deployment secrets and deployment configuration were not inspectable.

### Low — legacy `invite-admin` documentation/function is inconsistent with current master-admin flow

**Evidence:** `AdminsPage` invokes `create-admin`, while `docs/FIRST_ADMIN_SETUP.md` documents `invite-admin` and its source remains present.

**Impact:** Operators may deploy or reason about the wrong admin-provisioning route. This is operational/maintainability risk, not an observed access-control bypass.

## Storage policy analysis

Migration 006 supersedes 005's unreliable `metadata.size` write condition. It creates separate policies:

- INSERT: authenticated `is_admin()`, bucket `dog-images`, exactly a two-folder `dogs/...` path and permitted extension.
- UPDATE/DELETE: the same admin, path, and extension constraints in `USING`/`WITH CHECK` as applicable.

There is no anonymous dog-image write policy. `dog-images` is public for retrieval, which was confirmed separately by a real object HTTP 200 response. This audit did not attempt upload/delete/replacement because those operations could modify Cloud data.

## Verification matrix and prioritized plan

| Priority | Action | Why | Completion evidence |
| --- | --- | --- |
| P0 | Make a reviewed temporary decision on anonymous `submit_dog_location` | Confirmed arbitrary-location integrity risk | Approved migration/policy decision plus anonymous valid-write rejection test |
| P1 | Verify live function ACL for `is_super_admin()` | Actual anonymous execution differs from migration expectation | Authorized ACL query and anon RPC result consistent with intended policy |
| P1 | Execute controlled normal-admin/master-admin API matrix | Source is not sufficient for positive/admin-denial behavior | Documented API responses for DB, Storage, direct `/admins`, and `create-admin` |
| P1 | Verify deployed `create-admin` Function settings | Source exists, deploy/secret/CORS state is unknown | Master-admin success and normal/anonymous failure with no account leakage |
| P2 | Verify bucket MIME and 5 MB Dashboard limits | RLS extension check does not prove MIME/size enforcement | Authorized Dashboard/SQL evidence and rejected test files |
| P2 | Design anonymous report abuse controls | Intended anonymous write can be spammed | Product-approved threat model and rate-limit/moderation implementation plan |
| P3 | Retire or document `invite-admin` clearly | Avoid operator confusion | One canonical runbook and one supported Function path |

## Constraints and unverified items

No passwords, tokens, service-role keys, real account changes, migrations, or Storage writes were used. The normal-admin/master-admin rows, Edge Function deployment, actual Storage write enforcement, report insertion success, and Cloud dashboard settings remain unverified because this audit had no authorized test credentials and intentionally did not mutate data.
