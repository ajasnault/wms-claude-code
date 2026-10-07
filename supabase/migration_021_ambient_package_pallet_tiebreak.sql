-- WMS -- Same PACKAGE/PALLET tie-break fragility as migration_020, this
-- time for ERP_DOCUMENT/AMBIENT rows.
--
-- calculateWorkUnits() breaks ties between same-specificity matrix
-- entries by "whichever unit_type the task has non-zero data for" --
-- undefined when both are non-zero, which happens on 93 current AMBIENT
-- ERP_DOCUMENT tasks (ESSERS 59, DHL 12, DUPERREX 11, OTHER 6,
-- KUEHNE_NAGEL 4). Unlike DRY_ICE, the AMBIENT matrix isn't uniform:
--
--   - ESSERS, KUEHNE_NAGEL, DUPERREX, WORLD_COURIER: PALLET is the real
--     rate (1.00-2.00), PACKAGE is a 0.01 placeholder -- confirmed live,
--     e.g. WMS1000218 (ESSERS, 259 pkg / 3 pal) already shows 3.00 WU
--     (correct), not 2.59 (259 x 0.01, wrong) -- it currently resolves
--     right by luck of undefined row order, same fragility that broke
--     WMS1000320 for DRY_ICE. Removing the 0.01 placeholder rows makes
--     this deterministic instead of accidental.
--   - TNT_FEDEX: inverted -- PACKAGE=2.00 is real, PALLET=0.01 is the
--     placeholder. No current task hits this tie, included anyway for
--     consistency (same 0.01-vs-real-value evidence).
--   - DHL: genuinely ambiguous by value alone (PALLET=1.00 vs
--     PACKAGE=0.25 -- neither looks like a placeholder). Confirmed with
--     the user: DHL AMBIENT should bill by PACKAGE. Currently resolves
--     to PALLET by the same undefined ordering (e.g. WMS1000324 shows
--     1.00 WU today; should be 1.50 WU = 6 pkg x 0.25).
--   - OTHER carrier: PALLET=0.50=PACKAGE=0.50, and ESSERS/KUEHNE_NAGEL's
--     EUROFINS-destination rows are 0.01=0.01 too -- genuinely tied
--     values, left alone since neither answer is wrong.
--
-- 12 rows removed: 10 placeholder PACKAGE/PALLET=0.01 rows across
-- ESSERS/KUEHNE_NAGEL/DUPERREX/WORLD_COURIER/TNT_FEDEX, plus DHL's
-- PALLET=1.00 row per the confirmed business rule above.

begin;

-- A. Remove the 0.01 placeholder rows (real rate is on the other side).
delete from public.work_unit_matrix
where task_type = 'ERP_DOCUMENT'
  and temperature_group = 'AMBIENT'
  and work_unit_value = 0.01
  and id in (
    '2bd583cb-3b6c-4a1f-9e62-899c638047d8', -- ESSERS / OTHER / PACKAGE
    'fc42d2b1-9caa-497e-87ef-0e05f82cfc68', -- ESSERS / WAVRE_BE / PACKAGE
    '4a6173ba-7608-4f14-bc49-f5d107e9d4af', -- ESSERS / ANGERS_FR / PACKAGE
    '6f5325c3-7b37-47f4-bc64-f95f1ef8446d', -- ESSERS / MALAGA_ES / PACKAGE
    '8446d317-a666-47d1-b1bf-bc11ab9be5d3', -- KUEHNE_NAGEL / OTHER / PACKAGE
    'a5e92c5b-6ca9-4f2a-be26-fc5838e0e0db', -- KUEHNE_NAGEL / WAVRE_BE / PACKAGE
    '9f7c6504-2cbc-4d06-9258-701a4a3826c5', -- KUEHNE_NAGEL / ANGERS_FR / PACKAGE
    'd6b8a85e-f5aa-42ac-b1c4-e65a2356911a', -- KUEHNE_NAGEL / MALAGA_ES / PACKAGE
    'cc33ff1c-89be-424a-9777-c9fa47d55940', -- DUPERREX / PACKAGE
    'b4fbe6df-40cf-4b1a-8be9-32dfe82a7130', -- WORLD_COURIER / PACKAGE
    '01d34f51-e99a-41bd-8647-93e98b7a4aed'  -- TNT_FEDEX / PALLET
  );

-- B. DHL AMBIENT bills by PACKAGE (confirmed with the user) -- remove
--    the competing PALLET=1.00 row.
delete from public.work_unit_matrix
where id = 'dc3a59ec-4b79-4192-a077-4226e3365785' -- DHL / PALLET / 1.00
  and task_type = 'ERP_DOCUMENT'
  and temperature_group = 'AMBIENT'
  and carrier = 'DHL'
  and unit_type = 'PALLET'
  and work_unit_value = 1.00;

commit;

-- Verification: should return exactly the still-intentionally-tied rows
-- (OTHER carrier at 0.50/0.50, and ESSERS/KUEHNE_NAGEL's EUROFINS rows
-- at 0.01/0.01) -- nothing else.
select carrier, destination_k, unit_type, work_unit_value
from public.work_unit_matrix
where task_type = 'ERP_DOCUMENT' and temperature_group = 'AMBIENT'
order by carrier, destination_k, unit_type;
