-- Migration 028 — remplit novembre 2026 à partir de mars 2026 (bâtiments K et S).
--
-- Choix de l'utilisateur (2026-11-02) :
-- * Mars est copié jour pour jour, même jour de la semaine : +245 jours
--   (35 semaines). Lundi 2 mars -> lundi 2 novembre ... mardi 31 mars ->
--   mardi 1er décembre (le 31 est gardé pour que les 4 préparations du 30 mars
--   restent liées à leurs expéditions).
-- * Mars a 3 préparations de carboglace un dimanche (8, 22, 29 mars), chacune
--   la veille de son expédition du lundi. Pas de dimanche en novembre : la
--   préparation passe au lundi et son expédition au mardi (+246 jours pour ces
--   6 lignes : WMS749370, WMS757405, WMS761747). Elles restent à 1 jour d'écart.
-- * La préparation WMS761502 du 30 mars sert une expédition du 1er avril, qui
--   n'est pas copiée : elle est exclue (elle serait orpheline).
--   170 lignes copiées (171 en mars - 1).
--
-- Comme pour la migration 023 :
-- * erp_document_number n'est pas recopié : chaque numéro source reçoit un
--   numéro neuf via generate_erp_document_number(), partagé par toutes les
--   lignes de l'événement (préparation + expédition restent liées).
--   107 numéros neufs (WMS1000470 à WMS1000576 si la séquence n'a pas bougé).
-- * temperature_group / temperature_conditions sont recopiés.
-- * Tout novembre démarre en NEW, K2/PGI/CMR/référence K2/sous-statuts remis
--   à zéro (aucun jour copié n'est antérieur au 2 novembre). completed_at et
--   picking_date restent NULL.
--
-- À lancer une seule fois : le garde-fou ci-dessous annule si novembre ou le
-- 1er décembre contient déjà des tâches.

begin;

do $$
begin
  if exists (select 1 from public.tasks
             where due_date between date '2026-11-01' and date '2026-12-01') then
    raise exception 'Novembre 2026 / 1er décembre contient déjà des tâches - annulation pour éviter les doublons';
  end if;
end $$;

-- Lignes de mars à copier, avec leur date cible.
create temporary table nov_source on commit drop as
select t.*,
       t.due_date + case
         when (t.due_date, t.erp_document_number) in (
           (date '2026-03-08', 'WMS749370'), (date '2026-03-09', 'WMS749370'),
           (date '2026-03-22', 'WMS757405'), (date '2026-03-23', 'WMS757405'),
           (date '2026-03-29', 'WMS761747'), (date '2026-03-30', 'WMS761747'))
         then 246 else 245 end as nov_date
from public.tasks t
where t.due_date between date '2026-03-01' and date '2026-03-31'
  and not (t.type = 'PREP_DRY_ICE'
           and t.due_date = date '2026-03-30'
           and t.erp_document_number = 'WMS761502');

do $$
declare n int;
begin
  select count(*) into n from nov_source;
  if n <> 170 then
    raise exception 'Attendu 170 lignes sources en mars, trouvé %', n;
  end if;
  select count(*) into n from nov_source
    where nov_date <> due_date + 245;
  if n <> 6 then
    raise exception 'Attendu 6 lignes décalées d''un jour (dimanches), trouvé %', n;
  end if;
end $$;

-- Un numéro neuf par numéro source.
create temporary table nov_number_map on commit drop as
select erp_document_number as old_number,
       public.generate_erp_document_number() as new_number
from (
  select distinct erp_document_number
  from nov_source
  where erp_document_number is not null
  order by erp_document_number
) s;

insert into public.tasks (
  building, type, status, priority, erp_document_number, carrier, carrier_other,
  destination_k, destination_k_other, destination_s, destination_s_other,
  due_date, due_time, bottle_count, pallet_count, package_count,
  dry_ice_carton_count, notes, created_by, is_bulk,
  other_shipment_category, other_shipment_category_other,
  temperature_conditions, temperature_group, transport_mode,
  k2_closed, pgi_done
)
select
  s.building, s.type, 'NEW', s.priority, nm.new_number, s.carrier, s.carrier_other,
  s.destination_k, s.destination_k_other, s.destination_s, s.destination_s_other,
  s.nov_date, s.due_time, s.bottle_count, s.pallet_count, s.package_count,
  s.dry_ice_carton_count, s.notes, s.created_by, s.is_bulk,
  s.other_shipment_category, s.other_shipment_category_other,
  s.temperature_conditions, s.temperature_group, s.transport_mode,
  false, false
from nov_source s
left join nov_number_map nm on nm.old_number = s.erp_document_number;

select due_date, count(*) from public.tasks
where due_date between date '2026-11-01' and date '2026-12-01'
group by due_date order by due_date;

-- Vérifications (dernier résultat affiché) : 170 lignes, 0 week-end, 0 numéro
-- partagé avec un autre mois, 0 préparation sans expédition le lendemain.
select 'lignes copiées' as label, count(*)::text as value from public.tasks
  where due_date between date '2026-11-01' and date '2026-12-01'
union all
select 'lignes le week-end', count(*)::text from public.tasks
  where due_date between date '2026-11-01' and date '2026-12-01'
    and extract(isodow from due_date) > 5
union all
select 'numéros réutilisés ailleurs', count(distinct o.erp_document_number)::text
  from public.tasks o join public.tasks x on x.erp_document_number = o.erp_document_number
  where o.due_date between date '2026-11-01' and date '2026-12-01'
    and x.due_date not between date '2026-11-01' and date '2026-12-01'
union all
select 'préparations orphelines', count(*)::text from public.tasks p
  where p.type = 'PREP_DRY_ICE'
    and p.due_date between date '2026-11-01' and date '2026-12-01'
    and not exists (select 1 from public.tasks e
                    where e.type = 'ERP_DOCUMENT'
                      and e.erp_document_number = p.erp_document_number
                      and e.due_date between p.due_date and p.due_date + 1)
union all
select 'statuts non NEW', count(*)::text from public.tasks
  where due_date between date '2026-11-01' and date '2026-12-01' and status <> 'NEW';

commit;
