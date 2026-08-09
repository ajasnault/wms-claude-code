-- Marks all June 2026 tasks (orders) as OUT.
--
-- status -> 'OUT'. completed_at is left untouched, since the app only sets
-- it on a transition to DONE (see useTasks.tsx), not OUT.
-- Applies to every current status (LATE, NEW, IN_PROGRESS, STANDBY, OUT).

begin;

update public.tasks
set status = 'OUT'
where due_date between date '2026-06-01' and date '2026-06-30';

select status, count(*) from public.tasks
where due_date between date '2026-06-01' and date '2026-06-30'
group by status;

commit;
