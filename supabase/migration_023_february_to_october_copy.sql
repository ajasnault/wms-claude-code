-- Fills October 2026 from February 2026 (both buildings, K and S).
--
-- February 2026 is 4 full Mon-Fri weeks (Feb 2-27, no weekend tasks), so
-- each February week maps onto the matching October week, same weekday:
--   Feb 2-6 -> Oct 5-9, Feb 9-13 -> Oct 12-16,
--   Feb 16-20 -> Oct 19-23, Feb 23-27 -> Oct 26-30.
-- Thursday Oct 1 / Friday Oct 2 reuse Feb 5 / Feb 6 a second time ('extra'
-- batch), so the whole month has shipments, Monday to Friday only.
-- Every PREP_DRY_ICE keeps its offset to its ERP_DOCUMENT (same week).
--
-- Lessons from migrations 016-022 applied here:
--   * erp_document_number is NOT copied verbatim: each source number gets
--     one fresh number per batch from generate_erp_document_number(), shared
--     by all rows of that event, so a PREP_DRY_ICE stays linked to its
--     shipment and no number is reused across unrelated shipments.
--   * temperature_group / temperature_conditions are copied (older copy
--     scripts dropped them, which broke dry-ice WU costing).
--
-- Status (as of 2026-10-07): days before today copy February's shipped
-- state (OUT, K2/PGI, CMR, K2 reference); today onward start as NEW with
-- K2/PGI/CMR reset, like the September copy. completed_at stays NULL.
--
-- Also closes September 2026 as shipped, same rule as migration_015 for
-- August (OUT + K2/PGI closed, PREP_DRY_ICE excluded).
--
-- October had 0 tasks when written. Run once only: re-running inserts the
-- copy again (the guard below aborts if October already has tasks).

begin;

do $$
begin
  if exists (select 1 from public.tasks
             where due_date between date '2026-10-01' and date '2026-10-31') then
    raise exception 'October 2026 already has tasks - aborting to avoid duplicates';
  end if;
end $$;

create temporary table oct_date_map (feb_date date, oct_date date, batch text) on commit drop;
insert into oct_date_map values
    (date '2026-02-02', date '2026-10-05', 'main'),
    (date '2026-02-03', date '2026-10-06', 'main'),
    (date '2026-02-04', date '2026-10-07', 'main'),
    (date '2026-02-05', date '2026-10-08', 'main'),
    (date '2026-02-06', date '2026-10-09', 'main'),
    (date '2026-02-09', date '2026-10-12', 'main'),
    (date '2026-02-10', date '2026-10-13', 'main'),
    (date '2026-02-11', date '2026-10-14', 'main'),
    (date '2026-02-12', date '2026-10-15', 'main'),
    (date '2026-02-13', date '2026-10-16', 'main'),
    (date '2026-02-16', date '2026-10-19', 'main'),
    (date '2026-02-17', date '2026-10-20', 'main'),
    (date '2026-02-18', date '2026-10-21', 'main'),
    (date '2026-02-19', date '2026-10-22', 'main'),
    (date '2026-02-20', date '2026-10-23', 'main'),
    (date '2026-02-23', date '2026-10-26', 'main'),
    (date '2026-02-24', date '2026-10-27', 'main'),
    (date '2026-02-25', date '2026-10-28', 'main'),
    (date '2026-02-26', date '2026-10-29', 'main'),
    (date '2026-02-27', date '2026-10-30', 'main'),
    (date '2026-02-05', date '2026-10-01', 'extra'),
    (date '2026-02-06', date '2026-10-02', 'extra');

-- One fresh number per (batch, source number).
create temporary table oct_number_map on commit drop as
select batch, erp_document_number as old_number,
       public.generate_erp_document_number() as new_number
from (
  select distinct dm.batch, t.erp_document_number
  from public.tasks t
  join oct_date_map dm on dm.feb_date = t.due_date
  where t.erp_document_number is not null
  order by dm.batch, t.erp_document_number
) s;

insert into public.tasks (
  building, type, status, priority, erp_document_number, carrier, carrier_other,
  destination_k, destination_k_other, destination_s, destination_s_other,
  due_date, due_time, bottle_count, pallet_count, package_count,
  dry_ice_carton_count, notes, created_by, is_bulk,
  other_shipment_category, other_shipment_category_other,
  temperature_conditions, temperature_group, transport_mode,
  k2_closed, pgi_done, cmr_status, k2_reference, sub_statuses
)
select
  t.building, t.type,
  case when past then t.status else 'NEW' end,
  t.priority, nm.new_number, t.carrier, t.carrier_other,
  t.destination_k, t.destination_k_other, t.destination_s, t.destination_s_other,
  dm.oct_date, t.due_time, t.bottle_count, t.pallet_count, t.package_count,
  t.dry_ice_carton_count, t.notes, t.created_by, t.is_bulk,
  t.other_shipment_category, t.other_shipment_category_other,
  t.temperature_conditions, t.temperature_group, t.transport_mode,
  case when past then t.k2_closed else false end,
  case when past then t.pgi_done else false end,
  case when past then t.cmr_status end,
  case when past then t.k2_reference end,
  case when past then t.sub_statuses end
from public.tasks t
join oct_date_map dm on dm.feb_date = t.due_date
left join oct_number_map nm
  on nm.batch = dm.batch and nm.old_number = t.erp_document_number
cross join lateral (select dm.oct_date < date '2026-10-07' as past) p;

update public.tasks
set status = 'OUT', k2_closed = true, pgi_done = true
where due_date between date '2026-09-01' and date '2026-09-30'
  and type <> 'PREP_DRY_ICE';

select due_date, status, count(*) from public.tasks
where due_date between date '2026-10-01' and date '2026-10-31'
group by due_date, status order by due_date, status;

-- Checks (last result shown): expected 196 October rows (183 + 13 for Oct 1-2), no weekend,
-- no October number shared with any other month, September has no LATE.
select 'october rows' as label, count(*)::text as value from public.tasks
  where due_date between date '2026-10-01' and date '2026-10-31'
union all
select 'october weekend rows', count(*)::text from public.tasks
  where due_date between date '2026-10-01' and date '2026-10-31'
    and extract(isodow from due_date) > 5
union all
select 'october numbers reused elsewhere', count(distinct o.erp_document_number)::text
  from public.tasks o join public.tasks x on x.erp_document_number = o.erp_document_number
  where o.due_date between date '2026-10-01' and date '2026-10-31'
    and x.due_date not between date '2026-10-01' and date '2026-10-31'
union all
select 'september LATE rows', count(*)::text from public.tasks
  where due_date between date '2026-09-01' and date '2026-09-30' and status = 'LATE';

commit;
