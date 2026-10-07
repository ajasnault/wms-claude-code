-- WMS — Fix dry-ice work-unit under-counting (ticket WMS711977; prior case
-- WMS749370 was partially fixed by migration_013).
--
-- Root cause, confirmed against live data:
--
--   1. calculateWorkUnits() (src/lib/workUnitCalculator.ts) matches
--      work_unit_matrix rows on task.temperature_group. When it isn't
--      exactly 'DRY_ICE' on an ERP_DOCUMENT task, the shipment either
--      matches nothing (0 WU, no badge) or matches the wrong temperature
--      group's rate.
--
--   2. migration_013 only backfilled rows where temperature_group WAS
--      NULL. 183 ERP_DOCUMENT tasks carry the legacy
--      temperature_conditions -> {"DRY_ICE": true} flag but already had
--      temperature_group = 'AMBIENT', so migration_013's `is null` guard
--      skipped them — they've been costed at the AMBIENT rate ever since.
--
--   3. It was a one-off migration, not an ongoing safeguard: the
--      migration_005/010/011/014 "copy tasks into another month" scripts
--      don't copy temperature_group or temperature_conditions at all, so
--      every task created that way loses its classification. WMS711977's
--      2026-09-07 occurrence is exactly this — a migration_014 copy of the
--      January task, with temperature_group/temperature_conditions both
--      dropped.
--
--   4. Separately, 4 rows in work_unit_matrix have work_unit_value = 0.01
--      instead of 2.00 for ERP_DOCUMENT/DRY_ICE/PACKAGE — a data-entry
--      slip from migration_004's original import. Not yet hit by real
--      shipments (verified against current data), but latent.
--
-- This migration:
--   A. Backfills temperature_group = 'DRY_ICE' from the legacy
--      temperature_conditions flag (fixes the 183 AMBIENT-mislabeled rows).
--   B. Re-runs migration_013's PREP_DRY_ICE-link backfill, broadened to
--      overwrite any wrong value (not just NULL) — catches rows created
--      since migration_013 ran, WMS711977 included.
--   C. Fixes the 4 mis-priced work_unit_matrix rows.
--   D. Adds triggers so this stops recurring: any INSERT or UPDATE on
--      `tasks` re-syncs temperature_group = 'DRY_ICE' for any
--      ERP_DOCUMENT/PREP_DRY_ICE pair sharing an erp_document_number
--      touched by the statement, regardless of which side changed or the
--      row order within a bulk statement (uses statement-level transition
--      tables, not a per-row lookup, so it's safe for the bulk "copy
--      tasks" migrations too).
--
-- Run in the Supabase SQL Editor after migration_015.

begin;

-- A. Legacy temperature_conditions flag --------------------------------

update public.tasks
set temperature_group = 'DRY_ICE'
where type = 'ERP_DOCUMENT'
  and temperature_group is distinct from 'DRY_ICE'
  and temperature_conditions @> '{"DRY_ICE": true}'::jsonb;

-- B. PREP_DRY_ICE link (broadened migration_013) ------------------------

update public.tasks t
set temperature_group = 'DRY_ICE'
where t.type = 'ERP_DOCUMENT'
  and t.temperature_group is distinct from 'DRY_ICE'
  and t.erp_document_number is not null
  and exists (
    select 1 from public.tasks p
    where p.type = 'PREP_DRY_ICE'
      and p.erp_document_number = t.erp_document_number
  );

-- C. work_unit_matrix: DRY_ICE/PACKAGE rows mis-priced at 0.01 ----------

update public.work_unit_matrix
set work_unit_value = 2.00
where id in (
  'a1d15c86-2844-4def-ac19-19a885cac1a6', -- ESSERS / EUROFINS
  '77bd762b-5ce7-42f0-9329-104edde3da1d', -- KUEHNE_NAGEL / EUROFINS
  'c23fce88-e9d7-4aad-b91a-85f5297e2747', -- TNT_FEDEX (any destination)
  '0c748026-c275-4ed1-a370-831c65bd7f86'  -- carrier OTHER (any destination)
)
and unit_type = 'PACKAGE'
and temperature_group = 'DRY_ICE'
and work_unit_value = 0.01;

-- D. Ongoing safeguard: keep temperature_group in sync going forward ----

create or replace function public.sync_dry_ice_temperature_group()
returns trigger
language plpgsql
as $$
begin
  update public.tasks t
  set temperature_group = 'DRY_ICE'
  from (
    select distinct erp_document_number
    from new_rows
    where erp_document_number is not null
  ) touched
  where t.type = 'ERP_DOCUMENT'
    and t.erp_document_number = touched.erp_document_number
    and t.temperature_group is distinct from 'DRY_ICE'
    and exists (
      select 1 from public.tasks p
      where p.type = 'PREP_DRY_ICE'
        and p.erp_document_number = t.erp_document_number
    );
  return null;
end;
$$;

-- Postgres doesn't allow REFERENCING NEW TABLE on a trigger that combines
-- multiple events (insert or update of ...) — split into two triggers on
-- the same function instead.

drop trigger if exists tasks_sync_dry_ice_temperature_group on public.tasks;
drop trigger if exists tasks_sync_dry_ice_temperature_group_ins on public.tasks;
drop trigger if exists tasks_sync_dry_ice_temperature_group_upd on public.tasks;

create trigger tasks_sync_dry_ice_temperature_group_ins
  after insert on public.tasks
  referencing new table as new_rows
  for each statement
  execute function public.sync_dry_ice_temperature_group();

-- Postgres also disallows REFERENCING NEW TABLE combined with an
-- UPDATE OF <column list> — fire on every update instead; the function
-- itself only writes when the dry-ice/PREP_DRY_ICE case actually applies,
-- so this is a cheap no-op update-checks scan the rest of the time.
create trigger tasks_sync_dry_ice_temperature_group_upd
  after update on public.tasks
  referencing new table as new_rows
  for each statement
  execute function public.sync_dry_ice_temperature_group();

-- Verification (both counts should be 0) ---------------------------------

select count(*) as remaining_ambient_but_flagged_dry_ice
from public.tasks
where type = 'ERP_DOCUMENT'
  and temperature_conditions @> '{"DRY_ICE": true}'::jsonb
  and temperature_group is distinct from 'DRY_ICE';

select count(*) as remaining_null_with_prep_link
from public.tasks t
where t.type = 'ERP_DOCUMENT'
  and t.temperature_group is distinct from 'DRY_ICE'
  and exists (
    select 1 from public.tasks p
    where p.type = 'PREP_DRY_ICE' and p.erp_document_number = t.erp_document_number
  );

select id, carrier, destination_k, work_unit_value
from public.work_unit_matrix
where temperature_group = 'DRY_ICE' and unit_type = 'PACKAGE'
order by carrier, destination_k;

commit;
