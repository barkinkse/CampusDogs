# Dog Image Storage Setup

This setup applies only to the public `dog-images` bucket. It keeps downloads public while allowing writes only to authenticated administrators through the policies in migration `202611040006_fix_dog_image_storage_policies.sql`.

## Required Dashboard configuration

In Supabase Dashboard, open **Storage → Buckets → dog-images → Edit bucket** and set:

- **Public bucket:** enabled
- **Maximum file size:** `5242880` bytes (5 MB)
- **Allowed MIME types:** `image/jpeg`, `image/png`, `image/webp`

Save the bucket. These are authoritative Storage restrictions; the browser validation is only an additional usability guard.

## Apply the policy migration manually

After the bucket settings are saved, open **SQL Editor** and run the contents of `supabase/migrations/202611040006_fix_dog_image_storage_policies.sql` once. It removes only the former broad dog-image policy and creates separate administrator-only INSERT, UPDATE, and DELETE policies.

The policies permit only paths shaped as `dogs/{dog_id}/{filename}` with a JPG, JPEG, PNG, or WebP extension. They do not grant anonymous writes and do not alter public retrieval from the bucket.

## Verify after applying

With an administrator account, upload one JPEG, PNG, and WebP image, then replace and remove an image. Confirm a public image URL loads without a login. Also verify that an anonymous browser session and an authenticated non-admin account receive upload rejection.

The migration and this document do not change Supabase Cloud automatically.
