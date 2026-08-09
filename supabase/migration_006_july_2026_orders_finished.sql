-- Marks all July 2026 tasks (orders) as finished.
--
-- status -> 'DONE', completed_at -> the task's own due_date/due_time
-- (falls back to end-of-day when due_time is null), since this is a
-- historical backfill rather than a live "mark as done" action.

update public.tasks
set status = 'DONE',
    completed_at = (due_date + coalesce(due_time, time '23:59:59'))::timestamptz
where due_date between date '2026-07-01' and date '2026-07-31';

-- Review the result below, then run `commit;` or `rollback;` yourself.
select status, count(*) from public.tasks
where due_date between date '2026-07-01' and date '2026-07-31'
group by status;
