-- Campus Dogs Phase 1: schema, anonymous member boundary, and administrator RLS.
create extension if not exists pgcrypto;

create type public.health_status as enum ('normal', 'under_observation', 'under_treatment', 'recovering');
create type public.report_severity as enum ('low', 'medium', 'high');
create type public.report_status as enum ('new', 'reviewing', 'resolved', 'dismissed');

create table public.admin_users (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table public.dogs (
  id uuid primary key default gen_random_uuid(), name text not null check (char_length(name) between 1 and 100),
  photo_path text, gender text check (gender in ('female','male','unknown')), estimated_birth_date date,
  description text, public_health_status public.health_status not null default 'normal', public_care_info text,
  is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.collars (
  id uuid primary key default gen_random_uuid(), hardware_identifier text not null unique,
  advertisement_identifier text unique, display_icon_path text, is_active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (hardware_identifier <> '')
);
create table public.dog_collar_assignments (
  id uuid primary key default gen_random_uuid(), dog_id uuid not null references public.dogs(id), collar_id uuid not null references public.collars(id),
  assigned_at timestamptz not null default now(), unassigned_at timestamptz, created_at timestamptz not null default now(),
  check (unassigned_at is null or unassigned_at >= assigned_at)
);
create unique index dog_collar_one_active_assignment on public.dog_collar_assignments(collar_id) where unassigned_at is null;
create table public.dog_locations (
  dog_id uuid primary key references public.dogs(id) on delete cascade, latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180), updated_at timestamptz not null default now()
);
create table public.health_records (
  id uuid primary key default gen_random_uuid(), dog_id uuid not null references public.dogs(id) on delete cascade,
  title text not null, description text, status public.health_status not null, is_public boolean not null default false,
  recorded_at timestamptz not null default now(), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.care_icons (
  id uuid primary key default gen_random_uuid(), name text not null unique, icon_key text not null, description text not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.dog_care_icons (dog_id uuid not null references public.dogs(id) on delete cascade, care_icon_id uuid not null references public.care_icons(id) on delete cascade, created_at timestamptz not null default now(), primary key (dog_id, care_icon_id));
create table public.member_reports (
  id uuid primary key default gen_random_uuid(), dog_id uuid not null references public.dogs(id), category text not null, description text not null,
  image_path text, severity public.report_severity not null default 'medium', status public.report_status not null default 'new', created_at timestamptz not null default now(),
  check (char_length(description) between 1 and 4000)
);
create table public.admin_notes (
  id uuid primary key default gen_random_uuid(), dog_id uuid not null references public.dogs(id) on delete cascade, body text not null,
  author_id uuid not null references public.admin_users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.announcements (
  id uuid primary key default gen_random_uuid(), title text not null, body text not null, is_published boolean not null default false,
  published_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index dogs_active_idx on public.dogs(is_active); create index health_records_dog_public_idx on public.health_records(dog_id, is_public);
create index report_dog_status_idx on public.member_reports(dog_id, status); create index announcements_published_idx on public.announcements(is_published, published_at desc);

create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end $$;
create trigger dogs_updated before update on public.dogs for each row execute function public.set_updated_at();
create trigger collars_updated before update on public.collars for each row execute function public.set_updated_at();
create trigger health_records_updated before update on public.health_records for each row execute function public.set_updated_at();
create trigger care_icons_updated before update on public.care_icons for each row execute function public.set_updated_at();
create trigger admin_notes_updated before update on public.admin_notes for each row execute function public.set_updated_at();
create trigger announcements_updated before update on public.announcements for each row execute function public.set_updated_at();

-- SECURITY DEFINER avoids policies recursively querying admin_users. Never grant admin_users to clients.
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$ select exists (select 1 from public.admin_users where id = auth.uid()) $$;
create or replace function public.submit_dog_location(target_dog_id uuid, input_latitude double precision, input_longitude double precision) returns void language plpgsql security definer set search_path = public as $$
begin
  if input_latitude not between -90 and 90 or input_longitude not between -180 and 180 then raise exception 'Invalid coordinates'; end if;
  if not exists (select 1 from public.dogs where id = target_dog_id and is_active) then raise exception 'Dog is unavailable'; end if;
  insert into public.dog_locations(dog_id, latitude, longitude, updated_at) values(target_dog_id,input_latitude,input_longitude,now())
  on conflict (dog_id) do update set latitude=excluded.latitude, longitude=excluded.longitude, updated_at=excluded.updated_at;
end $$;
grant execute on function public.submit_dog_location(uuid, double precision, double precision) to anon, authenticated;

alter table public.admin_users enable row level security; alter table public.dogs enable row level security; alter table public.collars enable row level security; alter table public.dog_collar_assignments enable row level security; alter table public.dog_locations enable row level security; alter table public.health_records enable row level security; alter table public.care_icons enable row level security; alter table public.dog_care_icons enable row level security; alter table public.member_reports enable row level security; alter table public.admin_notes enable row level security; alter table public.announcements enable row level security;
create policy "admins manage admin users" on public.admin_users for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "public reads active dogs" on public.dogs for select to anon, authenticated using (is_active or public.is_admin()); create policy "admins manage dogs" on public.dogs for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins manage collars" on public.collars for all to authenticated using (public.is_admin()) with check (public.is_admin()); create policy "admins manage assignments" on public.dog_collar_assignments for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "public reads active dog locations" on public.dog_locations for select to anon, authenticated using (exists(select 1 from public.dogs d where d.id=dog_id and d.is_active) or public.is_admin()); create policy "admins manage locations" on public.dog_locations for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "public reads public health" on public.health_records for select to anon, authenticated using (is_public or public.is_admin()); create policy "admins manage health records" on public.health_records for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "public reads care icons" on public.care_icons for select to anon, authenticated using (true); create policy "admins manage care icons" on public.care_icons for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "public reads active dog care icons" on public.dog_care_icons for select to anon, authenticated using (exists(select 1 from public.dogs d where d.id=dog_id and d.is_active) or public.is_admin()); create policy "admins manage dog care icons" on public.dog_care_icons for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "anonymous submits reports" on public.member_reports for insert to anon, authenticated with check (exists(select 1 from public.dogs d where d.id=dog_id and d.is_active)); create policy "admins manage reports" on public.member_reports for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins manage private notes" on public.admin_notes for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "public reads published announcements" on public.announcements for select to anon, authenticated using (is_published or public.is_admin()); create policy "admins manage announcements" on public.announcements for all to authenticated using (public.is_admin()) with check (public.is_admin());
