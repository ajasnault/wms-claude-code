-- Migration 026 — clôture des jours du 15 au 22 octobre 2026 (données de démo).
--
-- Même règle que la migration 024 (7-14 octobre) :
-- 1) Les tâches passées en LATE (useLateDetection) faute d'avoir été clôturées
--    passent en OUT + K2 clôturé + PGI fait. 37 lignes attendues
--    (15 ERP_DOCUMENT, 14 TRUCK_LOADING, 6 OTHER_SHIPMENTS, 2 RE_SUPPLY).
-- 2) Les PREP_DRY_ICE ne passent jamais en LATE : celles restées NEW avec une
--    échéance au plus tard le 22 octobre passent en OUT (statut seulement, K2/PGI
--    ne concernent pas les préparations). 5 lignes attendues, toutes le 19.
-- Le 22 octobre (jour de la migration) est inclus, à la demande de l'utilisateur.
-- Comptes vérifiés en lecture seule le 2026-10-22.

begin;

update public.tasks
set status = 'OUT', k2_closed = true, pgi_done = true
where status = 'LATE'
  and due_date between date '2026-10-15' and date '2026-10-22'
  and type <> 'PREP_DRY_ICE';

update public.tasks
set status = 'OUT'
where status = 'NEW'
  and type = 'PREP_DRY_ICE'
  and due_date <= date '2026-10-22';

-- Vérification : 0 LATE et 0 tâche NEW échue au plus tard le 22 octobre.
select 'LATE restantes' as label, count(*) as value from public.tasks where status = 'LATE'
union all
select 'NEW échues au plus tard le 22/10', count(*) from public.tasks
  where status = 'NEW' and due_date <= date '2026-10-22';

commit;
