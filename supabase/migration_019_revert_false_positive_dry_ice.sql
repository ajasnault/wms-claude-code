-- WMS -- Revert false-positive DRY_ICE classification introduced by
-- migration_016's rule B.
--
-- migration_016 classified an ERP_DOCUMENT task as DRY_ICE whenever ANY
-- PREP_DRY_ICE task shared its erp_document_number -- but at the time,
-- erp_document_number was frequently reused across unrelated shipments on
-- unrelated, far-apart dates (see migration_018). Some of those matches
-- were coincidental: an ERP_DOCUMENT task got linked to a PREP_DRY_ICE
-- task from a completely different month that just happened to share the
-- same (reused) number.
--
-- Now that migration_018 has deduplicated erp_document_number so it's
-- unique per real shipment event, re-checking the same rule against
-- current data shows 16 ERP_DOCUMENT rows that are DRY_ICE-classified
-- with:
--   - no temperature_conditions.DRY_ICE flag (the direct, reliable
--     signal used by migration_016's rule A), AND
--   - no PREP_DRY_ICE sibling under their now-accurate number
-- i.e. no remaining evidence they're actually dry-ice shipments -- the
-- only "evidence" was the coincidental old-number collision. Revert them
-- to unclassified (NULL), matching what they would have been without
-- that collision.
--
-- Verified offline against a live read-only export before writing this;
-- the WHERE clause is self-deriving (not just a hardcoded ID list) so it
-- stays correct even if the exact row set has shifted slightly, but the
-- 16 numbers found at verification time are listed explicitly too, as a
-- safety bound against reverting anything broader than intended.

begin;

update public.tasks t
set temperature_group = null
where t.type = 'ERP_DOCUMENT'
  and t.temperature_group = 'DRY_ICE'
  and coalesce(t.temperature_conditions @> '{"DRY_ICE": true}'::jsonb, false) = false
  and not exists (
    select 1 from public.tasks p
    where p.type = 'PREP_DRY_ICE'
      and p.erp_document_number = t.erp_document_number
  )
  and t.erp_document_number in (
    'WMS1000139','WMS1000141','WMS1000143','WMS1000145','WMS1000157',
    'WMS1000160','WMS1000162','WMS1000198','WMS1000200','WMS1000273',
    'WMS1000277','WMS1000281','WMS1000329','WMS1000331','WMS1000334',
    'WMS1000339'
  );

commit;

-- Verification: should return 0 rows (no more unexplained DRY_ICE
-- classifications left).
select t.erp_document_number
from public.tasks t
where t.type = 'ERP_DOCUMENT'
  and t.temperature_group = 'DRY_ICE'
  and coalesce(t.temperature_conditions @> '{"DRY_ICE": true}'::jsonb, false) = false
  and not exists (
    select 1 from public.tasks p
    where p.type = 'PREP_DRY_ICE' and p.erp_document_number = t.erp_document_number
  );
