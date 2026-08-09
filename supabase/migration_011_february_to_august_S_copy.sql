-- Copies February 2026 Bâtiment S tasks into August 2026 (same
-- weekday-position mapping as migration_005, e.g. the 2nd Monday of
-- February -> the 2nd Monday of August). Added alongside existing August
-- 2026 data (no delete) — August already contains the March 2026 forecast
-- copy from migration_005; this adds the February 2026 copy on top.
--
-- Copied tasks are reset to status = 'NEW' with no completed_at.
--
-- Run once only — no de-dup key exists, re-running will duplicate rows.
-- February 2026 has no 29th (2026 is not a leap year), so it maps 28 days.

begin;

with date_map (feb_date, aug_date) as (
  values
    (date '2026-02-01', date '2026-08-02'),
    (date '2026-02-02', date '2026-08-03'),
    (date '2026-02-03', date '2026-08-04'),
    (date '2026-02-04', date '2026-08-05'),
    (date '2026-02-05', date '2026-08-06'),
    (date '2026-02-06', date '2026-08-07'),
    (date '2026-02-07', date '2026-08-01'),
    (date '2026-02-08', date '2026-08-09'),
    (date '2026-02-09', date '2026-08-10'),
    (date '2026-02-10', date '2026-08-11'),
    (date '2026-02-11', date '2026-08-12'),
    (date '2026-02-12', date '2026-08-13'),
    (date '2026-02-13', date '2026-08-14'),
    (date '2026-02-14', date '2026-08-08'),
    (date '2026-02-15', date '2026-08-16'),
    (date '2026-02-16', date '2026-08-17'),
    (date '2026-02-17', date '2026-08-18'),
    (date '2026-02-18', date '2026-08-19'),
    (date '2026-02-19', date '2026-08-20'),
    (date '2026-02-20', date '2026-08-21'),
    (date '2026-02-21', date '2026-08-15'),
    (date '2026-02-22', date '2026-08-23'),
    (date '2026-02-23', date '2026-08-24'),
    (date '2026-02-24', date '2026-08-25'),
    (date '2026-02-25', date '2026-08-26'),
    (date '2026-02-26', date '2026-08-27'),
    (date '2026-02-27', date '2026-08-28'),
    (date '2026-02-28', date '2026-08-22')
)
insert into public.tasks (
  building, type, status, priority, erp_document_number, carrier,
  destination_k, destination_s, due_date, due_time, bottle_count,
  pallet_count, package_count, dry_ice_carton_count, notes, created_by
)
select
  t.building, t.type, 'NEW', t.priority, t.erp_document_number, t.carrier,
  t.destination_k, t.destination_s, dm.aug_date, t.due_time,
  t.bottle_count, t.pallet_count, t.package_count, t.dry_ice_carton_count,
  t.notes, t.created_by
from public.tasks t
join date_map dm on dm.feb_date = t.due_date
where t.due_date between date '2026-02-01' and date '2026-02-28'
  and t.building = 'S';

select due_date, count(*) from public.tasks
where due_date between date '2026-08-01' and date '2026-08-31'
group by due_date order by due_date;

commit;
