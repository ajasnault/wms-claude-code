-- Marks all August 2026 tasks as shipped: status -> 'OUT', k2_closed and
-- pgi_done -> true. Excludes PREP_DRY_ICE tasks, since the K2/PGI toggles
-- aren't shown for that type in the Backoffice UI (see task.type !==
-- "PREP_DRY_ICE" guards in Backoffice.tsx) — they represent dry ice prep,
-- not a shipment.
--
-- Applies uniformly regardless of current status (NEW, LATE, DONE, or
-- already OUT), per explicit request to uniformize August as fully OUT.
--
-- completed_at is left untouched — the app only sets it on a transition
-- to DONE (see useTasks.tsx), and OUT is not that transition (same
-- convention as migration_010/011).
--
-- Idempotent: safe to re-run, this is a plain UPDATE (no inserts).

begin;

update public.tasks
set status = 'OUT',
    k2_closed = true,
    pgi_done = true
where due_date between date '2026-08-01' and date '2026-08-31'
  and type <> 'PREP_DRY_ICE';

select type, status, count(*) from public.tasks
where due_date between date '2026-08-01' and date '2026-08-31'
group by type, status order by type, status;

commit;
