-- WMS -- Remove the DRY_ICE/PALLET rows from work_unit_matrix (ticket
-- WMS1000320, ex-WMS??????: shipment showed 0.02 WU instead of 4.00).
--
-- Root cause: calculateWorkUnits() (src/lib/workUnitCalculator.ts) picks
-- among tied-specificity matrix entries by "whichever unit_type the task
-- has non-zero data for". For ERP_DOCUMENT/DRY_ICE, nearly every
-- carrier+destination combo has BOTH a PACKAGE row (2.00 -- the real
-- rate, matching "each carton = 2WU") and a PALLET row (0.01 -- always a
-- near-zero placeholder, never the intended dry-ice billing unit). 174 of
-- 226 current DRY_ICE ERP_DOCUMENT tasks (77%) have both package_count
-- AND pallet_count populated simultaneously, so the tie is real, and
-- which entry wins depends on undefined row-fetch order (the query only
-- orders by task_type -- see useWorkUnitMatrix.tsx) -- not deterministic,
-- and for WMS1000320 it silently landed on the wrong (PALLET) one.
--
-- Fix: dry ice is never billed by pallet (0.01 in every single DRY_ICE
-- row, no exception) -- removing these rows leaves PACKAGE as the only
-- possible match for ERP_DOCUMENT/DRY_ICE, eliminating the ambiguity
-- entirely without touching the calculator code.
--
-- Side effect (confirmed acceptable by the user): 3 DHL/destination=OTHER
-- tasks currently have pallet_count set but no package_count (their only
-- current match is the DHL/DRY_ICE/PALLET row) -- they'll go from 0.01 WU
-- (already not meaningful) to 0 WU / no WU badge, which is more honest
-- than a fake near-zero value.
--
-- 15 rows deleted, listed explicitly (from migration_004's original
-- insert) as a safety bound on top of the declarative WHERE clause.

begin;

delete from public.work_unit_matrix
where task_type = 'ERP_DOCUMENT'
  and temperature_group = 'DRY_ICE'
  and unit_type = 'PALLET'
  and id in (
    'eb4ac430-2171-4653-8baf-1785ad93b39e', -- DHL
    'a3eb8a08-ed6f-4938-8b94-c60bb3d5e37e', -- ESSERS / EUROFINS
    '46ef6ac4-c9d2-49fd-88ba-1bac31405332', -- KUEHNE_NAGEL / EUROFINS
    '30fc68a6-b5a7-47f1-983c-1d5293fb5137', -- ESSERS / OTHER
    'b2139a23-9203-4ab4-acf3-022df73e469a', -- ESSERS / WAVRE_BE
    '220239a3-212b-4723-914c-64aff85c5a14', -- KUEHNE_NAGEL / WAVRE_BE
    '8a249496-0290-4b59-9209-308637a70b95', -- KUEHNE_NAGEL / OTHER
    '70fa8796-8352-49df-b0fd-3b388a282149', -- TNT_FEDEX
    '1d2db458-93df-4ab1-86a5-231e69cbb870', -- DUPERREX
    'e3d4d014-96f2-438f-bbfd-bc2fcfb30771', -- WORLD_COURIER
    '02560a8c-b997-48c4-90c7-f7b8f2258ce9', -- carrier OTHER
    'd00b777c-955c-4b9e-8a54-b875b890e886', -- ESSERS / ANGERS_FR
    '644efb59-3103-492a-a5de-2845a112cfc8', -- KUEHNE_NAGEL / ANGERS_FR
    '30dc8da1-cacf-44d4-8445-9d0663b1f49b', -- ESSERS / MALAGA_ES
    '67039047-5973-4f65-bb67-70e7e92960c3'  -- KUEHNE_NAGEL / MALAGA_ES
  );

commit;

-- Verification: should return 0 rows (no DRY_ICE/PALLET entries left for
-- ERP_DOCUMENT).
select id, carrier, destination_k, unit_type, work_unit_value
from public.work_unit_matrix
where task_type = 'ERP_DOCUMENT' and temperature_group = 'DRY_ICE' and unit_type = 'PALLET';
