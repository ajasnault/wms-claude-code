-- Copies March 2026 tasks into August 2026 (same weekday-position mapping,
-- e.g. the 2nd Monday of March -> the 2nd Monday of August) so the
-- Capacity/Analytics dashboards have forecast visibility for August.
--
-- Copied tasks are reset to status = 'NEW' with no completed_at, since they
-- represent expected future load, not completed work.
--
-- Run once only — no de-dup key exists, re-running will duplicate rows.
-- As of writing, August 2026 has 0 existing tasks in this table.

with date_map (march_date, august_date) as (
  values
    (date '2026-03-01', date '2026-08-02'),
    (date '2026-03-02', date '2026-08-03'),
    (date '2026-03-03', date '2026-08-04'),
    (date '2026-03-04', date '2026-08-05'),
    (date '2026-03-05', date '2026-08-06'),
    (date '2026-03-06', date '2026-08-07'),
    (date '2026-03-07', date '2026-08-01'),
    (date '2026-03-08', date '2026-08-09'),
    (date '2026-03-09', date '2026-08-10'),
    (date '2026-03-10', date '2026-08-11'),
    (date '2026-03-11', date '2026-08-12'),
    (date '2026-03-12', date '2026-08-13'),
    (date '2026-03-13', date '2026-08-14'),
    (date '2026-03-14', date '2026-08-08'),
    (date '2026-03-15', date '2026-08-16'),
    (date '2026-03-16', date '2026-08-17'),
    (date '2026-03-17', date '2026-08-18'),
    (date '2026-03-18', date '2026-08-19'),
    (date '2026-03-19', date '2026-08-20'),
    (date '2026-03-20', date '2026-08-21'),
    (date '2026-03-21', date '2026-08-15'),
    (date '2026-03-22', date '2026-08-23'),
    (date '2026-03-23', date '2026-08-24'),
    (date '2026-03-24', date '2026-08-25'),
    (date '2026-03-25', date '2026-08-26'),
    (date '2026-03-26', date '2026-08-27'),
    (date '2026-03-27', date '2026-08-28'),
    (date '2026-03-28', date '2026-08-22'),
    (date '2026-03-29', date '2026-08-30'),
    (date '2026-03-30', date '2026-08-31'),
    -- March has a 5th Tuesday (31st); August only has 4 Tuesdays, so it
    -- falls back to the last one (2026-08-25), same target as March 24.
    (date '2026-03-31', date '2026-08-25')
)
insert into public.tasks (
  building, type, status, priority, erp_document_number, carrier,
  destination_k, destination_s, due_date, due_time, bottle_count,
  pallet_count, package_count, dry_ice_carton_count, notes, created_by
)
select
  t.building, t.type, 'NEW', t.priority, t.erp_document_number, t.carrier,
  t.destination_k, t.destination_s, dm.august_date, t.due_time,
  t.bottle_count, t.pallet_count, t.package_count, t.dry_ice_carton_count,
  t.notes, t.created_by
from public.tasks t
join date_map dm on dm.march_date = t.due_date
where t.due_date between date '2026-03-01' and date '2026-03-31';

-- Review the result below, then run `commit;` or `rollback;` yourself.
select due_date, count(*) from public.tasks
where due_date between date '2026-08-01' and date '2026-08-31'
group by due_date order by due_date;
