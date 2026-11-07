# Phase 2.4 Test Report

Date: 2026-11-04

## Scope and method

The repository, product and architecture documents, migrations 001–006, React admin client, SwiftUI member client, Edge Function source, and RLS definitions were inspected. No migration, Edge Function deployment, Storage configuration change, or destructive database action was performed.

Live checks used only the configured project's publishable key as an anonymous client. They were read-only. No administrator or non-admin test credentials were available, so those contexts were not simulated or inferred.

## Results

| Area | Expected outcome | Actual outcome | Result |
| --- | --- | --- | --- |
| Admin web build | TypeScript and production bundle build | `npm run build` completed successfully | Passed |
| iOS Simulator build | CampusDogs builds for an iPhone simulator | `xcodebuild` completed successfully for iPhone 16 (iOS 18.6) | Passed |
| Anonymous active dogs | Active dog profiles are readable | HTTP 200, 3 rows | Passed |
| Anonymous inactive dogs | Inactive profiles are hidden | HTTP 200, 0 rows | Passed |
| Anonymous public health | Public records are readable | HTTP 200, 2 rows | Passed |
| Anonymous private health | Private records are hidden | HTTP 200, 0 rows | Passed |
| Anonymous care icons | Care icons are readable | HTTP 200, 4 rows | Passed |
| Anonymous published announcements | Published announcements are readable | HTTP 200, 2 rows | Passed |
| Anonymous draft announcements | Draft announcements are hidden | HTTP 200, 0 rows | Passed |
| Anonymous reports, notes, admins | Internal records are hidden | HTTP 200, 0 rows for each endpoint | Passed |
| Anonymous admin status | Anonymous user is not an administrator | `is_admin()` returned `false` | Passed |
| Anonymous locations | Only actual stored locations are exposed | HTTP 200, 0 rows; no coordinates were invented | Passed |
| Dog image bucket metadata | Bucket configuration endpoint is readable anonymously | Storage API returned `NoSuchBucket`; this endpoint does not establish bucket absence for the anonymous role | Not applicable |

## Stabilization fixes made

- Normal administrators no longer see the **Admin Yönetimi** navigation link. Direct access remains protected by the page guard and the `create-admin` Edge Function verifies `is_super_admin()` server-side.
- The member home screen now loads live active dogs rather than displaying local example dogs.
- Dog-photo loading uses the paw fallback for an unavailable URL as well as a missing path.
- Care-icon keys use a known SwiftUI-symbol mapping with a safe fallback, and the icon row scrolls horizontally on narrow iPhones.
- The current-health interface now lets administrators select all four supported states instead of toggling only Normal/Gözlem Altında.

## Not performed

The following require an approved master-admin account, an approved regular-admin account, and a configured `dog-images` bucket. They were not run and are not marked as passing:

- Master-admin login and administrator creation; regular-admin UI/API rejection; anonymous Edge Function rejection.
- Dog create/edit/deactivate, optional-date and nullable-care persistence, and dashboard count reconciliation as an admin.
- Dog-image JPEG/PNG/WebP upload, public retrieval, replacement, removal, oversized/unsupported-file rejection, and anonymous/non-admin write rejection.
- Health record creation/editing and member refresh; private record and admin-note visibility as an authenticated administrator.
- Care-icon creation/editing and assignment changes.
- Anonymous report submission and subsequent admin review.
- Announcement create/edit/publish/unpublish flow.
- Interactive iOS Simulator navigation, live remote-image display, and actual anonymous report submission.

## Phase 2.4.1 Storage diagnostic correction

The previous `NoSuchBucket` conclusion was corrected with a second, read-only check against the same configured project (`aiihwhpgfrnevpnudahp`). Both the admin and iOS local configurations point to that project.

- Anonymous `GET /storage/v1/bucket/dog-images` returned `NoSuchBucket`. This is a bucket-metadata endpoint and the anonymous client is not authorized to inspect Storage bucket configuration.
- Anonymous `GET /storage/v1/object/public/dog-images/diagnostic/no-such-object.jpg` returned `NoSuchKey`, which proves the bucket was resolved and the requested object alone was absent.
- A stored, non-null public `dogs.photo_path` resolved through `/storage/v1/object/public/dog-images/{path}` with HTTP 200.

Therefore, the prior bucket blocker was a false negative caused by using the metadata endpoint with an anonymous key. Public dog-image retrieval is confirmed. File-size and allowed-MIME bucket configuration cannot be read through the anonymous Storage API and must be verified by an authorized Dashboard or SQL inspection.

## RLS findings and limitations

Anonymous reads observed through the actual client API match the intended public/private boundaries above. This does not establish the authenticated-admin or authenticated-non-admin boundaries; those require real test accounts. RLS remains the enforcement boundary; frontend visibility is not treated as authorization.

The authenticated-admin write path was not tested because no administrator session was supplied to this validation. The applied status/effect of migrations 005–006 and the bucket's MIME/size settings require manual Cloud verification; this does not block confirmed public object retrieval.

## Required manual actions

1. Verify the existing `dog-images` bucket in the Dashboard: public enabled, maximum size `5242880`, MIME types `image/jpeg`, `image/png`, and `image/webp`.
2. Verify that migrations 005–006 effects are present, including the three scoped dog-image object policies. Do not rerun migrations solely because the anonymous metadata endpoint returned `NoSuchBucket`.
3. Provide controlled master-admin and regular-admin test accounts, or run the documented role matrix without sharing passwords.
4. Repeat the not-performed scenarios and record their actual outcomes before deployment.
