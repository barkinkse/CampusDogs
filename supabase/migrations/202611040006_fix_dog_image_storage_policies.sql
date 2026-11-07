-- Dog image object policies only. Bucket file limits and MIME allow-list are configured in the Supabase Dashboard.
-- This replaces the metadata.size RLS condition from migration 005 because object metadata is not reliable at INSERT authorization time.
drop policy if exists "admins manage dog images" on storage.objects;
drop policy if exists "admins insert dog images" on storage.objects;
drop policy if exists "admins update dog images" on storage.objects;
drop policy if exists "admins delete dog images" on storage.objects;

create policy "admins insert dog images"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'dog-images'
  and public.is_admin()
  and (storage.foldername(name))[1] = 'dogs'
  and array_length(storage.foldername(name), 1) = 2
  and storage.filename(name) <> ''
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);

create policy "admins update dog images"
on storage.objects for update to authenticated
using (
  bucket_id = 'dog-images'
  and public.is_admin()
  and (storage.foldername(name))[1] = 'dogs'
  and array_length(storage.foldername(name), 1) = 2
  and storage.filename(name) <> ''
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
)
with check (
  bucket_id = 'dog-images'
  and public.is_admin()
  and (storage.foldername(name))[1] = 'dogs'
  and array_length(storage.foldername(name), 1) = 2
  and storage.filename(name) <> ''
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);

create policy "admins delete dog images"
on storage.objects for delete to authenticated
using (
  bucket_id = 'dog-images'
  and public.is_admin()
  and (storage.foldername(name))[1] = 'dogs'
  and array_length(storage.foldername(name), 1) = 2
  and storage.filename(name) <> ''
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);
