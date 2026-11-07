# Development test data setup

`supabase/seed.sql` is a development-only repeatable fixture. It uses stable UUIDs for Duman, Tarçın, Boncuk, four care icons, two published announcements, three health records (two public and one private), and two anonymous report scenarios. It intentionally creates no locations, collars, Bluetooth identifiers, member identities, credentials, or image objects. The reports contain no identifying or contact information and exist only to exercise the admin review interface.

The iOS Phase 2.2B connection checks are separate from this seed. They may create anonymous development reports whose category is `Geliştirme doğrulaması` and whose description begins `Phase 2.2B`; an administrator must remove those rows from `member_reports` after testing. They are not member identities or production incidents.

## Apply

1. Confirm migrations 001–004 have been applied in order.
2. Open Supabase Dashboard → SQL Editor.
3. Paste and execute `supabase/seed.sql`.
4. For the optional private note, find an existing `public.admin_users.id`, replace `ADMIN_USER_UUID` in the commented statement, then execute that statement from a trusted admin context.

The primary-key upserts and join conflict handling make reruns safe. Dogs and announcements have no schema-level name/title uniqueness, so remove earlier manually inserted examples when a fully clean fixture dataset is required.

## Safe fixture removal

Run only in Supabase SQL Editor. These IDs target the fixture records only.

```sql
delete from public.admin_notes where id = '50000000-0000-4000-8000-000000000001';
delete from public.dog_care_icons where dog_id in ('10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000003');
delete from public.health_records where id in ('40000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000002','40000000-0000-4000-8000-000000000003');
delete from public.member_reports where id in ('60000000-0000-4000-8000-000000000001','60000000-0000-4000-8000-000000000002');
delete from public.announcements where id in ('30000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000002');
delete from public.dogs where id in ('10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000003');
delete from public.care_icons where id in ('20000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000004');
```

Do not use this fixture dataset as production content.
