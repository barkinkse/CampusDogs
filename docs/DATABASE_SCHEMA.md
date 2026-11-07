# Database schema

The initial migration creates `admin_users` (Auth reference), `dogs`, `collars`, `dog_collar_assignments`, `dog_locations`, `health_records`, `care_icons`, `dog_care_icons`, `member_reports`, `admin_notes`, and `announcements`.

Dogs own current locations, health records, care-icon joins, reports, notes, and historical collar assignments. A location row is keyed by `dog_id`, therefore exactly one current last-seen point is held per dog. Health records have `is_public`; announcements have `is_published`. Reports store no reporter field. Indexes cover active dogs, public health records, reports, and published announcements.

The migrations use UUIDs, referential integrity, constrained enum values, timestamps, and automatic update timestamp triggers. Active collar assignments are unique in both directions: a collar has one active dog and a dog has one active collar. Dogs are soft-deactivated with `is_active`; their historical dependent records are retained.

`202611040002_security_hardening.sql` intentionally follows the initial migration. It removes browser access to `admin_users`, restricts function privileges, makes note authors immutable, and splits admin-note policies so insertion requires `author_id = auth.uid()`.
