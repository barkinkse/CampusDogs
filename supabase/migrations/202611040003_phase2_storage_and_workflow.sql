-- Phase 2 additions. Apply after the two already-executed migrations; do not rerun prior files.
alter table public.announcements add column if not exists image_path text;
alter table public.member_reports add column if not exists resolution_description text;
alter table public.member_reports add column if not exists resolved_at timestamptz;

-- Both buckets are private. Member report objects never receive public URLs.
insert into storage.buckets (id, name, public) values ('report-images', 'report-images', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('announcement-images', 'announcement-images', false) on conflict (id) do nothing;

create policy "anonymous uploads report images" on storage.objects for insert to anon, authenticated
with check (
  bucket_id = 'report-images'
  and (storage.extension(name) in ('jpg', 'jpeg', 'png', 'heic'))
  and coalesce((metadata->>'size')::bigint, 0) <= 5242880
);
create policy "admins manage report images" on storage.objects for all to authenticated
using (bucket_id = 'report-images' and public.is_admin())
with check (bucket_id = 'report-images' and public.is_admin());
create policy "admins manage announcement images" on storage.objects for all to authenticated
using (bucket_id = 'announcement-images' and public.is_admin())
with check (bucket_id = 'announcement-images' and public.is_admin());
