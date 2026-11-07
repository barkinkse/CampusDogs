-- Phase 1.1 security hardening. This migration intentionally follows the initial schema.

-- Admin provisioning is a trusted server-side responsibility. An admin browser session
-- must not be able to promote an arbitrary existing auth.users row.
drop policy if exists "admins manage admin users" on public.admin_users;

-- Do not rely on PostgreSQL's default PUBLIC function privilege. RLS callers need the
-- boolean helper, but it returns no admin-user data and is safe for those roles.
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = pg_catalog, public
as $$ select exists (select 1 from public.admin_users where id = auth.uid()) $$;

-- Client location submissions remain intentionally unverified until collar hardware and
-- a verifiable advertisement protocol are selected. This stores no caller identity.
revoke all on function public.submit_dog_location(uuid, double precision, double precision) from public;
grant execute on function public.submit_dog_location(uuid, double precision, double precision) to anon, authenticated;
create or replace function public.submit_dog_location(target_dog_id uuid, input_latitude double precision, input_longitude double precision)
returns void language plpgsql security definer set search_path = pg_catalog, public as $$
begin
  if input_latitude is null or input_longitude is null or input_latitude not between -90 and 90 or input_longitude not between -180 and 180 then
    raise exception 'Invalid coordinates';
  end if;
  if not exists (select 1 from public.dogs where id = target_dog_id and is_active) then
    raise exception 'Dog is unavailable';
  end if;
  insert into public.dog_locations(dog_id, latitude, longitude, updated_at) values (target_dog_id, input_latitude, input_longitude, now())
  on conflict (dog_id) do update set latitude = excluded.latitude, longitude = excluded.longitude, updated_at = excluded.updated_at;
end;
$$;

-- A collar can have only one active dog and a dog can have only one active collar.
create unique index dog_one_active_collar_assignment on public.dog_collar_assignments(dog_id) where unassigned_at is null;

-- Notes retain their actual author. Administrators can edit/delete notes, but no one
-- can rewrite attribution after insertion.
create or replace function public.prevent_admin_note_author_change()
returns trigger language plpgsql set search_path = pg_catalog, public as $$
begin
  if new.author_id is distinct from old.author_id then raise exception 'Admin note author cannot be changed'; end if;
  return new;
end;
$$;
create trigger admin_notes_author_immutable before update on public.admin_notes for each row execute function public.prevent_admin_note_author_change();
drop policy if exists "admins manage private notes" on public.admin_notes;
create policy "admins read private notes" on public.admin_notes for select to authenticated using (public.is_admin());
create policy "admins create attributed private notes" on public.admin_notes for insert to authenticated with check (public.is_admin() and author_id = auth.uid());
create policy "admins update private notes" on public.admin_notes for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins delete private notes" on public.admin_notes for delete to authenticated using (public.is_admin());
