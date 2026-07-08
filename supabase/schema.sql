-- WMS MVP schema
-- Run this once in the Supabase SQL Editor (Dashboard -> SQL Editor -> New query -> Run)

-- 1. Enums --------------------------------------------------------------

create type building_type as enum ('K', 'S');

create type task_status as enum ('NEW', 'IN_PROGRESS', 'DONE', 'LATE', 'STANDBY', 'OUT');

create type task_priority as enum ('1', '2', '3', '4', '5');

create type task_type as enum (
  'ERP_DOCUMENT', 'PREP_DRY_ICE', 'OTHER_SHIPMENTS', 'RE_SUPPLY', 'MAINTENANCE',
  'PICKING', 'PACKING', 'TRUCK_LOADING', 'SHIPMENT'
);

create type carrier_type as enum (
  'DHL', 'KUEHNE_NAGEL', 'WORLD_COURIER', 'ESSERS', 'DUPERREX', 'TNT_FEDEX', 'OTHER'
);

create type destination_k as enum (
  'GUIDONIA_IT', 'COLERETTO_IT', 'MODUGNO_IT', 'EUROFINS', 'OTHER'
);

create type destination_s as enum (
  'GLG', 'SANTA_PALOMBA', 'TURKEY', 'SWITZERLAND', 'USA', 'CHINA', 'KOREA', 'OTHER'
);

create type app_role as enum ('admin', 'operator');

-- 2. Tables ---------------------------------------------------------------

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  building building_type not null,
  type task_type not null,
  status task_status not null default 'NEW',
  priority task_priority not null default '3',
  erp_document_number text,
  carrier carrier_type,
  destination_k destination_k,
  destination_s destination_s,
  due_date date not null,
  due_time time,
  bottle_count int,
  pallet_count int,
  package_count int,
  dry_ice_carton_count int,
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now()
);

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role app_role not null default 'operator',
  unique (user_id, role)
);

-- 3. has_role() — SECURITY DEFINER avoids RLS recursion -------------------

create function public.has_role(_user_id uuid, _role app_role)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = _user_id and role = _role
  )
$$;

-- 4. handle_new_user() trigger ---------------------------------------------

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email);
  insert into public.user_roles (user_id, role) values (new.id, 'operator');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 5. updated_at trigger -----------------------------------------------------

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

-- 6. Row Level Security -------------------------------------------------

alter table public.tasks enable row level security;
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;

-- tasks: dashboards (K/S) are public TV/kiosk screens with no login, so SELECT
-- is open to everyone; only mutations require authentication.
create policy "tasks_select_public" on public.tasks
  for select using (true);

create policy "tasks_insert_authenticated" on public.tasks
  for insert to authenticated with check (true);

create policy "tasks_update_authenticated" on public.tasks
  for update to authenticated using (true);

create policy "tasks_delete_admin" on public.tasks
  for delete to authenticated using (public.has_role(auth.uid(), 'admin'));

-- profiles: owner or admin can read, owner can update own row
create policy "profiles_select_own_or_admin" on public.profiles
  for select to authenticated using (id = auth.uid() or public.has_role(auth.uid(), 'admin'));

create policy "profiles_update_own" on public.profiles
  for update to authenticated using (id = auth.uid());

-- user_roles: owner or admin can read, only admin can write
create policy "user_roles_select_own_or_admin" on public.user_roles
  for select to authenticated using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));

create policy "user_roles_admin_write" on public.user_roles
  for all to authenticated
  using (public.has_role(auth.uid(), 'admin'))
  with check (public.has_role(auth.uid(), 'admin'));

-- 7. Realtime ----------------------------------------------------------

alter publication supabase_realtime add table public.tasks;
