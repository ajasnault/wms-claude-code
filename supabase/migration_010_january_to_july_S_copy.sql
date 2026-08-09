-- Copies January 2026 Bâtiment S tasks into July 2026 (same weekday-position
-- mapping as migration_005, e.g. the 2nd Monday of January -> the 2nd
-- Monday of July). Added alongside existing July 2026 data (no delete),
-- so July now contains both the original tasks (status OUT, see
-- migration_008) and these copies (also status OUT).
--
-- Copied tasks get status = 'OUT' directly, no completed_at (the app only
-- sets completed_at on a transition to DONE, see useTasks.tsx). Since
-- July is more than 10 days in the past, these rows will be immediately
-- hidden from the dashboard (see OUT_MAX_AGE_DAYS in taskGrouping.ts) —
-- same as the rest of July's OUT data.
--
-- Run once only — no de-dup key exists, re-running will duplicate rows.

begin;

with date_map (jan_date, jul_date) as (
  values
    (date '2026-01-01', date '2026-07-02'),
    (date '2026-01-02', date '2026-07-03'),
    (date '2026-01-03', date '2026-07-04'),
    (date '2026-01-04', date '2026-07-05'),
    (date '2026-01-05', date '2026-07-06'),
    (date '2026-01-06', date '2026-07-07'),
    (date '2026-01-07', date '2026-07-01'),
    (date '2026-01-08', date '2026-07-09'),
    (date '2026-01-09', date '2026-07-10'),
    (date '2026-01-10', date '2026-07-11'),
    (date '2026-01-11', date '2026-07-12'),
    (date '2026-01-12', date '2026-07-13'),
    (date '2026-01-13', date '2026-07-14'),
    (date '2026-01-14', date '2026-07-08'),
    (date '2026-01-15', date '2026-07-16'),
    (date '2026-01-16', date '2026-07-17'),
    (date '2026-01-17', date '2026-07-18'),
    (date '2026-01-18', date '2026-07-19'),
    (date '2026-01-19', date '2026-07-20'),
    (date '2026-01-20', date '2026-07-21'),
    (date '2026-01-21', date '2026-07-15'),
    (date '2026-01-22', date '2026-07-23'),
    (date '2026-01-23', date '2026-07-24'),
    (date '2026-01-24', date '2026-07-25'),
    (date '2026-01-25', date '2026-07-26'),
    (date '2026-01-26', date '2026-07-27'),
    (date '2026-01-27', date '2026-07-28'),
    (date '2026-01-28', date '2026-07-22'),
    (date '2026-01-29', date '2026-07-30'),
    (date '2026-01-30', date '2026-07-31'),
    -- January has a 5th Saturday (31st); July only has 4 Saturdays, so it
    -- falls back to the last one (2026-07-25), same target as January 24.
    (date '2026-01-31', date '2026-07-25')
)
insert into public.tasks (
  building, type, status, priority, erp_document_number, carrier,
  destination_k, destination_s, due_date, due_time, bottle_count,
  pallet_count, package_count, dry_ice_carton_count, notes, created_by
)
select
  t.building, t.type, 'OUT', t.priority, t.erp_document_number, t.carrier,
  t.destination_k, t.destination_s, dm.jul_date, t.due_time,
  t.bottle_count, t.pallet_count, t.package_count, t.dry_ice_carton_count,
  t.notes, t.created_by
from public.tasks t
join date_map dm on dm.jan_date = t.due_date
where t.due_date between date '2026-01-01' and date '2026-01-31'
  and t.building = 'S';

select due_date, count(*) from public.tasks
where due_date between date '2026-07-01' and date '2026-07-31'
group by due_date order by due_date;

commit;
