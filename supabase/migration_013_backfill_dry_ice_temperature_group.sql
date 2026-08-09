-- Backfills temperature_group = 'DRY_ICE' on ERP_DOCUMENT tasks that are
-- missing it but have a linked PREP_DRY_ICE task (same erp_document_number)
-- — a reliable signal that the shipment is dry-ice conditioned.
--
-- Without temperature_group set, these tasks never matched any entry in
-- work_unit_matrix (all DHL/ESSERS/... entries require a specific
-- temperature group), so their workload silently computed to 0 WU on the
-- Capacity page — e.g. WMS749370.
--
-- Scope: 28 tasks, verified via a matching SELECT before this migration
-- was written. Deliberately narrow — 39 other ERP_DOCUMENT tasks are also
-- missing temperature_group but have no PREP_DRY_ICE link, so DRY_ICE
-- can't be inferred for them; they're left for manual review.

begin;

update public.tasks t
set temperature_group = 'DRY_ICE'
where t.type = 'ERP_DOCUMENT'
  and t.temperature_group is null
  and t.erp_document_number is not null
  and exists (
    select 1 from public.tasks p
    where p.type = 'PREP_DRY_ICE'
      and p.erp_document_number = t.erp_document_number
  );

select count(*) as updated_count
from public.tasks
where type = 'ERP_DOCUMENT' and temperature_group = 'DRY_ICE';

commit;
