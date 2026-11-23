-- WMS demo — full database schema.
--
-- Rebuilds every application object in the public schema from scratch:
-- running it DROPS all existing tasks, matrix entries, collaborators and
-- profiles. Auth accounts (auth.users) are left untouched, except that the
-- profile/role trigger is recreated.
--
-- Apply with `npm run db:reset` (schema + demo seed), or paste into the
-- Supabase SQL editor and run `npm run db:seed` afterwards.

begin;

-- ---------------------------------------------------------------------------
-- Clean slate
-- ---------------------------------------------------------------------------
drop trigger if exists on_auth_user_created on auth.users;

drop table if exists public.capacity_forecasts cascade;
drop table if exists public.collaborator_availability cascade;
drop table if exists public.collaborators cascade;
drop table if exists public.work_unit_matrix cascade;
drop table if exists public.tasks cascade;
drop table if exists public.user_roles cascade;
drop table if exists public.profiles cascade;

drop function if exists public.handle_new_user() cascade;
drop function if exists public.has_role(uuid, public.app_role) cascade;
drop function if exists public.update_updated_at() cascade;
drop function if exists public.sync_dry_ice_temperature_group() cascade;
drop function if exists public.generate_erp_document_number() cascade;
drop sequence if exists public.erp_document_number_seq;

drop type if exists public.building_type cascade;
drop type if exists public.task_status cascade;
drop type if exists public.task_priority cascade;
drop type if exists public.task_type cascade;
drop type if exists public.carrier_type cascade;
drop type if exists public.transport_mode cascade;
drop type if exists public.cmr_status cascade;
drop type if exists public.other_shipment_category cascade;
drop type if exists public.temperature_group cascade;
drop type if exists public.app_role cascade;

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------
create type public.building_type as enum ('PJ01', 'FG01');
create type public.task_status as enum ('NEW', 'IN_PROGRESS', 'DONE', 'LATE', 'STANDBY', 'OUT');
create type public.task_priority as enum ('1', '2', '3', '4', '5');
create type public.task_type as enum (
  'ERP_DOCUMENT', 'PREP_DRY_ICE', 'OTHER_SHIPMENTS', 'RE_SUPPLY', 'MAINTENANCE',
  'PICKING', 'PACKING', 'TRUCK_LOADING', 'SHIPMENT'
);
create type public.carrier_type as enum (
  'DHL', 'FEDEX', 'UPS', 'LEMAN_EXPRESS', 'CERVIN_CARGO', 'AZUR_FRET'
);
create type public.transport_mode as enum ('ROAD', 'AIR', 'SEA');
create type public.cmr_status as enum (
  'IN_WAITING', 'RECEIVED', 'CHECKED_APPROVED', 'TO_BE_MODIFIED', 'MANUAL', 'NA'
);
create type public.other_shipment_category as enum (
  'CHEMICALS', 'DOMESTIC_SHIPMENT', 'HARVEST_BAG', 'SAMPLES', 'INTERSITE_SHUTTLE', 'OTHER'
);
create type public.temperature_group as enum ('AMBIENT', 'DRY_ICE', 'MONITORED');
create type public.app_role as enum ('admin', 'operator');

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create sequence public.erp_document_number_seq start 2000001;

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  building public.building_type not null,
  type public.task_type not null,
  status public.task_status not null default 'NEW',
  priority public.task_priority not null default '3',
  erp_document_number text,
  carrier public.carrier_type,
  recipient text,
  transport_mode public.transport_mode,
  temperature_group public.temperature_group,
  other_shipment_category public.other_shipment_category,
  due_date date not null,
  due_time time,
  bottle_count integer,
  pallet_count integer,
  package_count integer,
  dry_ice_carton_count integer,
  cmr_status public.cmr_status,
  rdr26_reference text,
  rdr26_closed boolean not null default false,
  pgi_done boolean not null default false,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);
create index tasks_building_due_idx on public.tasks (building, due_date);
create index tasks_erp_idx on public.tasks (erp_document_number);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.app_role not null default 'operator',
  unique (user_id, role)
);

create table public.work_unit_matrix (
  id uuid primary key default gen_random_uuid(),
  task_type public.task_type not null,
  carrier public.carrier_type,
  temperature_group public.temperature_group,
  other_shipment_category public.other_shipment_category,
  unit_type text not null default 'PALLET',
  work_unit_value numeric not null default 1,
  created_at timestamptz not null default now()
);

create table public.collaborators (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  building public.building_type not null,
  base_capacity numeric not null default 0,
  default_percentage numeric not null default 100,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.collaborator_availability (
  id uuid primary key default gen_random_uuid(),
  collaborator_id uuid not null references public.collaborators(id) on delete cascade,
  date date not null,
  percentage numeric not null,
  unique (collaborator_id, date)
);

create table public.capacity_forecasts (
  id uuid primary key default gen_random_uuid(),
  building public.building_type not null,
  date date not null,
  value numeric not null,
  unique (building, date)
);

-- ---------------------------------------------------------------------------
-- Functions & triggers
-- ---------------------------------------------------------------------------
create function public.has_role(_user_id uuid, _role public.app_role)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.user_roles where user_id = _user_id and role = _role)
$$;

-- New accounts get a profile without their e-mail address (never shown in
-- the UI) and the operator role. Admins are promoted manually.
create function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name) values (new.id, 'User');
  insert into public.user_roles (user_id, role) values (new.id, 'operator');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger tasks_set_updated_at
  before update on public.tasks
  for each row execute function public.update_updated_at();

-- A shipment whose ERP number also has a "Prep Dry Ice" task is a dry-ice
-- shipment: keep its temperature group in sync.
create function public.sync_dry_ice_temperature_group()
returns trigger
language plpgsql
as $$
begin
  if pg_trigger_depth() > 1 then
    return null;
  end if;

  update public.tasks t
  set temperature_group = 'DRY_ICE'
  from (
    select distinct erp_document_number from new_rows where erp_document_number is not null
  ) touched
  where t.type = 'ERP_DOCUMENT'
    and t.erp_document_number = touched.erp_document_number
    and t.temperature_group is distinct from 'DRY_ICE'
    and exists (
      select 1 from public.tasks p
      where p.type = 'PREP_DRY_ICE' and p.erp_document_number = t.erp_document_number
    );
  return null;
end;
$$;

create trigger tasks_sync_dry_ice_temperature_group_ins
  after insert on public.tasks
  referencing new table as new_rows
  for each statement execute function public.sync_dry_ice_temperature_group();

create trigger tasks_sync_dry_ice_temperature_group_upd
  after update on public.tasks
  referencing new table as new_rows
  for each statement execute function public.sync_dry_ice_temperature_group();

create function public.generate_erp_document_number()
returns text
language sql
as $$
  select 'WMS' || nextval('public.erp_document_number_seq')::text;
$$;

-- ---------------------------------------------------------------------------
-- Row level security: everything requires a signed-in user
-- ---------------------------------------------------------------------------
alter table public.tasks enable row level security;
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.work_unit_matrix enable row level security;
alter table public.collaborators enable row level security;
alter table public.collaborator_availability enable row level security;
alter table public.capacity_forecasts enable row level security;

create policy tasks_select_authenticated on public.tasks
  for select to authenticated using (true);
create policy tasks_insert_authenticated on public.tasks
  for insert to authenticated with check (true);
create policy tasks_update_authenticated on public.tasks
  for update to authenticated using (true);
create policy tasks_delete_admin on public.tasks
  for delete to authenticated using (public.has_role(auth.uid(), 'admin'));

create policy profiles_select_own_or_admin on public.profiles
  for select to authenticated using (id = auth.uid() or public.has_role(auth.uid(), 'admin'));
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid());

create policy user_roles_select_own_or_admin on public.user_roles
  for select to authenticated using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
create policy user_roles_admin_write on public.user_roles
  for all to authenticated using (public.has_role(auth.uid(), 'admin'));

create policy work_unit_matrix_select_authenticated on public.work_unit_matrix
  for select to authenticated using (true);
create policy work_unit_matrix_admin_write on public.work_unit_matrix
  for all to authenticated using (public.has_role(auth.uid(), 'admin'));

create policy collaborators_select_authenticated on public.collaborators
  for select to authenticated using (true);
create policy collaborators_admin_write on public.collaborators
  for all to authenticated using (public.has_role(auth.uid(), 'admin'));

create policy collaborator_availability_select_authenticated on public.collaborator_availability
  for select to authenticated using (true);
create policy collaborator_availability_admin_write on public.collaborator_availability
  for all to authenticated using (public.has_role(auth.uid(), 'admin'));

create policy capacity_forecasts_select_authenticated on public.capacity_forecasts
  for select to authenticated using (true);
create policy capacity_forecasts_admin_write on public.capacity_forecasts
  for all to authenticated using (public.has_role(auth.uid(), 'admin'));

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table
  public.tasks, public.collaborator_availability, public.capacity_forecasts;

-- Profiles/roles for accounts that already exist (the trigger only covers
-- new sign-ups).
insert into public.profiles (id, display_name)
  select id, 'User' from auth.users on conflict do nothing;
insert into public.user_roles (user_id, role)
  select id, 'operator' from auth.users on conflict do nothing;

commit;
