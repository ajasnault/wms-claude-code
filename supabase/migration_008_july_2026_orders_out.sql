-- Moves all July 2026 tasks (orders) from DONE to OUT.
--
-- status -> 'OUT'. completed_at is left as-is (set by migration_006 when
-- these were marked DONE) since the app never clears it on other status
-- transitions (see useTasks.tsx) and OUT tasks older than 10 days are
-- hidden from the dashboard regardless (see taskGrouping.ts).

begin;

update public.tasks
set status = 'OUT'
where due_date between date '2026-07-01' and date '2026-07-31';

select status, count(*) from public.tasks
where due_date between date '2026-07-01' and date '2026-07-31'
group by status;

commit;
