-- WMS — Hotfix: migration_016's tasks_sync_dry_ice_temperature_group_upd
-- trigger recurses infinitely and breaks every UPDATE on `tasks`.
--
-- Root cause: the trigger fires on ANY update to `tasks` (no column list —
-- required to combine with a transition table, see migration_016's
-- comments), and the trigger function itself issues an `update public.tasks
-- ...` to do its sync. That internal UPDATE is itself a statement-level
-- UPDATE on `tasks`, so it re-fires the same trigger — regardless of how
-- many rows it actually changed, since statement-level AFTER triggers fire
-- once per statement execution, not once per row affected. This recurses
-- until Postgres raises "stack depth limit exceeded" and rolls back the
-- whole transaction, including whatever the user was actually trying to
-- save. Confirmed live: editing WMS711977's dry-ice carton count in the
-- Backoffice UI threw exactly this error (unhandledrejection, "stack depth
-- limit exceeded"), and the edit never persisted.
--
-- Fix: guard the function body with pg_trigger_depth() > 1 — this is only
-- true when the function is running because of its OWN internal UPDATE
-- (nested one level deeper), so that invocation becomes a no-op and the
-- recursion stops after a single extra (harmless) bounce. The outer,
-- user-initiated UPDATE still runs the real sync logic at depth 1.
--
-- Run in the Supabase SQL Editor immediately — every task UPDATE is
-- currently failing.

begin;

create or replace function public.sync_dry_ice_temperature_group()
returns trigger
language plpgsql
as $$
begin
  if pg_trigger_depth() > 1 then
    return null;
  end if;

  update public.tasks t
  set temperature_group = 'DRY_ICE'
  from (
    select distinct erp_document_number
    from new_rows
    where erp_document_number is not null
  ) touched
  where t.type = 'ERP_DOCUMENT'
    and t.erp_document_number = touched.erp_document_number
    and t.temperature_group is distinct from 'DRY_ICE'
    and exists (
      select 1 from public.tasks p
      where p.type = 'PREP_DRY_ICE'
        and p.erp_document_number = t.erp_document_number
    );
  return null;
end;
$$;

commit;

-- Verification: this plain update must now succeed without error (it's a
-- no-op WHERE clause — no row actually has this id — so nothing is
-- changed, it just proves the trigger no longer blows the stack).
update public.tasks set updated_at = updated_at where id = '00000000-0000-0000-0000-000000000000';
