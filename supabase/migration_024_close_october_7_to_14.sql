-- Migration 024 — clôture des jours écoulés jusqu'au 14 octobre 2026 (données de démo).
--
-- 1) Les tâches d'octobre créées en NEW par la migration 023 sont passées en
--    LATE (useLateDetection) faute d'avoir été clôturées au fil des jours.
--    Même règle que la clôture de septembre dans la migration 023 :
--    OUT + K2 clôturé + PGI fait. 30 lignes attendues.
-- 2) Les PREP_DRY_ICE ne passent jamais en LATE : celles restées NEW avec une
--    échéance passée (depuis le 18 août) passent en OUT (statut seulement, K2/PGI
--    ne concernent pas les préparations). 29 lignes attendues.
-- Le 15 octobre (jour de la migration) n'est pas touché.
-- Comptes vérifiés en lecture seule le 2026-10-15.

begin;

update public.tasks
set status = 'OUT', k2_closed = true, pgi_done = true
where status = 'LATE'
  and due_date between date '2026-10-07' and date '2026-10-14'
  and type <> 'PREP_DRY_ICE';

update public.tasks
set status = 'OUT'
where status = 'NEW'
  and type = 'PREP_DRY_ICE'
  and due_date < date '2026-10-15';

-- Vérification : 0 LATE et 0 tâche NEW échue avant le 15 octobre.
select 'LATE restantes' as label, count(*) as value from public.tasks where status = 'LATE'
union all
select 'NEW échues avant le 15/10', count(*) from public.tasks
  where status = 'NEW' and due_date < date '2026-10-15';

commit;
