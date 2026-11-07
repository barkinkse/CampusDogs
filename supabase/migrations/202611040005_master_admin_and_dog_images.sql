-- Phase 2.3D: apply manually after 001-004. Never guesses the master admin.
alter table public.admin_users add column if not exists is_super_admin boolean not null default false;
do $$
declare admin_count integer;
begin
  select count(*) into admin_count from public.admin_users;
  if admin_count = 1 then
    update public.admin_users set is_super_admin = true where is_super_admin = false;
  elsif admin_count <> 0 then
    raise notice 'Multiple administrators found. Promote exactly one manually: update public.admin_users set is_super_admin = true where id = ''AUTH_USER_UUID'';';
  else
    raise notice 'No administrator found. Provision an initial admin, then promote it manually.';
  end if;
end $$;

create or replace function public.is_super_admin() returns boolean language sql stable security definer set search_path = pg_catalog, public as $$
  select exists(select 1 from public.admin_users where id = auth.uid() and is_super_admin)
$$;
revoke all on function public.is_super_admin() from public;
grant execute on function public.is_super_admin() to authenticated;

insert into storage.buckets (id,name,public) values ('dog-images','dog-images',true) on conflict (id) do nothing;
create policy "admins manage dog images" on storage.objects for all to authenticated
using (bucket_id = 'dog-images' and public.is_admin())
with check (bucket_id = 'dog-images' and public.is_admin() and storage.extension(name) in ('jpg','jpeg','png','webp') and coalesce((metadata->>'size')::bigint,0) between 1 and 5242880);
