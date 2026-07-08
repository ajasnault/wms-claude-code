-- WMS — Capacity & Work Units module
-- Run in the Supabase SQL Editor after schema.sql

-- 1. Tables -----------------------------------------------------------

create table public.collaborators (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  building building_type not null,
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
  building building_type not null,
  date date not null,
  value numeric not null,
  unique (building, date)
);

create table public.work_unit_matrix (
  id uuid primary key default gen_random_uuid(),
  task_type task_type not null,
  carrier carrier_type,
  destination_k destination_k,
  destination_s destination_s,
  unit_type text not null default 'PALLET',
  work_unit_value numeric not null default 1,
  created_at timestamptz not null default now()
);

-- 2. RLS ----------------------------------------------------------------

alter table public.collaborators enable row level security;
alter table public.collaborator_availability enable row level security;
alter table public.capacity_forecasts enable row level security;
alter table public.work_unit_matrix enable row level security;

create policy "collaborators_select_authenticated" on public.collaborators
  for select to authenticated using (true);
create policy "collaborators_admin_write" on public.collaborators
  for all to authenticated
  using (public.has_role(auth.uid(), 'admin'))
  with check (public.has_role(auth.uid(), 'admin'));

create policy "collaborator_availability_select_authenticated" on public.collaborator_availability
  for select to authenticated using (true);
create policy "collaborator_availability_admin_write" on public.collaborator_availability
  for all to authenticated
  using (public.has_role(auth.uid(), 'admin'))
  with check (public.has_role(auth.uid(), 'admin'));

create policy "capacity_forecasts_select_authenticated" on public.capacity_forecasts
  for select to authenticated using (true);
create policy "capacity_forecasts_admin_write" on public.capacity_forecasts
  for all to authenticated
  using (public.has_role(auth.uid(), 'admin'))
  with check (public.has_role(auth.uid(), 'admin'));

create policy "work_unit_matrix_select_authenticated" on public.work_unit_matrix
  for select to authenticated using (true);
create policy "work_unit_matrix_admin_write" on public.work_unit_matrix
  for all to authenticated
  using (public.has_role(auth.uid(), 'admin'))
  with check (public.has_role(auth.uid(), 'admin'));

-- 3. Realtime -------------------------------------------------------------

alter publication supabase_realtime add table public.capacity_forecasts;
alter publication supabase_realtime add table public.collaborator_availability;
