-- Copies January 2026 tasks (both buildings, K and S) into September 2026
-- using the same weekday-position mapping as migration_005/010/011, e.g.
-- the 2nd Monday of January -> the 2nd Monday of September.
--
-- September 2026 has 0 existing tasks as of writing, so this is a plain
-- seed (no building filter, no de-dup concern with existing rows) meant
-- to give the dashboards/analytics a realistic-looking data set to demo
-- the tool's capabilities.
--
-- Copied tasks are reset to status = 'NEW' with no completed_at, since
-- most of September is still in the future relative to today (2026-09-02).
--
-- Run once only — no de-dup key exists, re-running will duplicate rows.

begin;

with date_map (jan_date, sep_date) as (
  values
    (date '2026-01-01', date '2026-09-03'),
    (date '2026-01-02', date '2026-09-04'),
    (date '2026-01-03', date '2026-09-05'),
    (date '2026-01-04', date '2026-09-06'),
    (date '2026-01-05', date '2026-09-07'),
    (date '2026-01-06', date '2026-09-01'),
    (date '2026-01-07', date '2026-09-02'),
    (date '2026-01-08', date '2026-09-10'),
    (date '2026-01-09', date '2026-09-11'),
    (date '2026-01-10', date '2026-09-12'),
    (date '2026-01-11', date '2026-09-13'),
    (date '2026-01-12', date '2026-09-14'),
    (date '2026-01-13', date '2026-09-08'),
    (date '2026-01-14', date '2026-09-09'),
    (date '2026-01-15', date '2026-09-17'),
    (date '2026-01-16', date '2026-09-18'),
    (date '2026-01-17', date '2026-09-19'),
    (date '2026-01-18', date '2026-09-20'),
    (date '2026-01-19', date '2026-09-21'),
    (date '2026-01-20', date '2026-09-15'),
    (date '2026-01-21', date '2026-09-16'),
    (date '2026-01-22', date '2026-09-24'),
    (date '2026-01-23', date '2026-09-25'),
    (date '2026-01-24', date '2026-09-26'),
    (date '2026-01-25', date '2026-09-27'),
    (date '2026-01-26', date '2026-09-28'),
    (date '2026-01-27', date '2026-09-22'),
    (date '2026-01-28', date '2026-09-23'),
    -- January has a 5th Thu/Fri/Sat (29/30/31); September only has 4 of
    -- each, so they fall back to the last one, same targets as Jan 22/23/24.
    (date '2026-01-29', date '2026-09-24'),
    (date '2026-01-30', date '2026-09-25'),
    (date '2026-01-31', date '2026-09-26')
)
insert into public.tasks (
  building, type, status, priority, erp_document_number, carrier,
  destination_k, destination_s, due_date, due_time, bottle_count,
  pallet_count, package_count, dry_ice_carton_count, notes, created_by
)
select
  t.building, t.type, 'NEW', t.priority, t.erp_document_number, t.carrier,
  t.destination_k, t.destination_s, dm.sep_date, t.due_time,
  t.bottle_count, t.pallet_count, t.package_count, t.dry_ice_carton_count,
  t.notes, t.created_by
from public.tasks t
join date_map dm on dm.jan_date = t.due_date
where t.due_date between date '2026-01-01' and date '2026-01-31';

select due_date, count(*) from public.tasks
where due_date between date '2026-09-01' and date '2026-09-30'
group by due_date order by due_date;

commit;
