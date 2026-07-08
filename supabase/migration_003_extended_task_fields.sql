-- WMS — extend tasks schema to match real production data export
-- Run in the Supabase SQL Editor after migration_002_capacity.sql

-- 1. New enums -----------------------------------------------------------

create type transport_mode as enum ('ROAD', 'AIR', 'SEA');

create type other_shipment_category as enum (
  'CHEMICALS', 'DOMESTIC_SHIPMENT', 'HARVEST_BAG', 'MARTI', 'NAVETTE_AUBONNE_VEVEY', 'OTHER'
);

create type cmr_status as enum (
  'IN_WAITING', 'RECEIVED', 'CHECKED_APPROVED', 'TO_BE_MODIFIED', 'MANUAL', 'NA'
);

-- 2. Extend existing enums with real-world values seen in production ------

alter type destination_k add value if not exists 'ANGERS_FR';
alter type destination_k add value if not exists 'MALAGA_ES';
alter type destination_k add value if not exists 'WAVRE_BE';

alter type destination_s add value if not exists 'GUIDONIA';
alter type destination_s add value if not exists 'PHARMALOG_KGAA';

-- 3. New columns on tasks --------------------------------------------------

alter table public.tasks
  add column if not exists transport_mode transport_mode,
  add column if not exists is_bulk boolean not null default false,
  add column if not exists carrier_other text,
  add column if not exists destination_k_other text,
  add column if not exists destination_s_other text,
  add column if not exists other_shipment_category other_shipment_category,
  add column if not exists other_shipment_category_other text,
  add column if not exists temperature_conditions jsonb,
  add column if not exists sub_status text,
  add column if not exists sub_statuses jsonb,
  add column if not exists cmr_status cmr_status,
  add column if not exists k2_reference text,
  add column if not exists k2_closed boolean not null default false,
  add column if not exists pgi_done boolean not null default false,
  add column if not exists picking_date date,
  add column if not exists updated_by uuid references auth.users(id);
