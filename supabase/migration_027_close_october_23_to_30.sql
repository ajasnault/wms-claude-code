-- Migration 027 — clôture des jours du 23 au 30 octobre 2026 (données de démo).
--
-- Même règle que les migrations 024 et 026, élargie à la demande de
-- l'utilisateur (2026-11-02) : toutes les tâches non OUT de la fin d'octobre
-- passent en OUT, quel que soit leur statut actuel. Cela inclut les 4 DONE,
-- 10 IN_PROGRESS et 1 STANDBY réglés à la main le 22 octobre au soir, en plus
-- des LATE et des NEW.
-- 1) Hors PREP_DRY_ICE : OUT + K2 clôturé + PGI fait. 60 lignes attendues
--    (15 LATE le 23, 4 DONE, 10 IN_PROGRESS, 1 STANDBY, 30 NEW).
-- 2) PREP_DRY_ICE : OUT, statut seulement (K2/PGI ne concernent pas les
--    préparations). 8 lignes attendues, toutes NEW.
-- Après cette migration, octobre est entièrement OUT (195 lignes).
-- Comptes vérifiés en lecture seule le 2026-11-02.

begin;

update public.tasks
set status = 'OUT', k2_closed = true, pgi_done = true
where status <> 'OUT'
  and due_date between date '2026-10-23' and date '2026-10-31'
  and type <> 'PREP_DRY_ICE';

update public.tasks
set status = 'OUT'
where status <> 'OUT'
  and type = 'PREP_DRY_ICE'
  and due_date <= date '2026-10-31';

-- Vérification : 0 tâche non OUT échue au plus tard le 31 octobre.
select 'non OUT échues au plus tard le 31/10' as label, count(*) as value from public.tasks
  where status <> 'OUT' and due_date <= date '2026-10-31'
union all
select 'octobre OUT', count(*) from public.tasks
  where status = 'OUT' and due_date between date '2026-10-01' and date '2026-10-31';

commit;
