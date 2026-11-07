-- Phase 2.1: migration 003 is already applied. Replace only its anonymous upload
-- policy so a missing/malformed size cannot bypass the 5 MB limit.
drop policy if exists "anonymous uploads report images" on storage.objects;

create policy "anonymous uploads report images" on storage.objects for insert to anon, authenticated
with check (
  bucket_id = 'report-images'
  and name like 'anonymous/%'
  and storage.extension(name) in ('jpg', 'jpeg', 'png', 'heic')
  and lower(coalesce(metadata->>'mimetype', '')) in ('image/jpeg', 'image/png', 'image/heic', 'image/heif')
  and coalesce(metadata->>'size', '') ~ '^[0-9]+$'
  and (metadata->>'size')::bigint between 1 and 5242880
);
