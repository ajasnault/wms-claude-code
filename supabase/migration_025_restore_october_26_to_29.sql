-- Migration 025 — restaure les tâches du 26 au 29 octobre 2026 supprimées à la main
-- (données de démo, copiées de février par la migration 023).
--
-- Constat en lecture seule le 2026-10-22 : octobre compte 159 lignes au lieu de 196.
-- Les 159 restantes correspondent une à une à leur source de février ; les 37
-- manquantes sont toutes du bâtiment K (8 lignes restent sur ces 4 jours) : 7 le 26 (source 23/02), 13 le 27 (24/02),
-- 11 le 28 (25/02), 6 le 29 (26/02). Le 30 octobre est complet.
--
-- Chaque ligne est recopiée depuis sa tâche source de février (id ci-dessous),
-- mêmes champs que la migration 023, statut NEW (dates futures) avec K2/PGI/CMR
-- remis à zéro. Les numéros ERP sont ceux d'origine : les 17 numéros libérés par
-- la suppression (WMS1000380, 431-432, 448-450, 454-456, 458-464, 469) ne sont plus
-- utilisés nulle part et s'intercalent exactement dans l'ordre d'attribution de la
-- 023 ; une PREP_DRY_ICE et son ERP_DOCUMENT gardent le même numéro.
--
-- À lancer une seule fois : les gardes ci-dessous l'arrêtent si les jours ont
-- changé depuis le constat ou si un numéro est déjà repris.

begin;

create temporary table oct_restore (source_id uuid, oct_date date, new_number text) on commit drop;
insert into oct_restore values
    ('9e1d70d1-d82f-4bb9-9aca-4e72de1d336a'::uuid, date '2026-10-26', null::text),
    ('4ff4c70e-d3e5-4cd0-b3b1-eed085edd087'::uuid, date '2026-10-26', 'WMS1000431'),
    ('f25bce9f-da4d-4ab7-83bc-447d9d95dfe3'::uuid, date '2026-10-26', 'WMS1000432'),
    ('fab6f4c5-2f4f-47f1-87c8-9dd46927a0d7'::uuid, date '2026-10-26', 'WMS1000448'),
    ('cc470234-5030-44da-aff9-9a3916552b39'::uuid, date '2026-10-26', 'WMS1000449'),
    ('962129aa-0354-4a2c-bd3d-2a60bdf29bb2'::uuid, date '2026-10-26', 'WMS1000450'),
    ('a0f387ef-875a-4eb0-ade2-371fbc56a77c'::uuid, date '2026-10-26', 'WMS1000456'),
    ('00728506-8dac-48c9-b7fb-d658bb830513'::uuid, date '2026-10-27', null::text),
    ('f9a92c71-8c1c-42d3-bcd8-02a72ccece0c'::uuid, date '2026-10-27', null::text),
    ('fcd44e96-8827-4392-8143-922d60ab1b28'::uuid, date '2026-10-27', null::text),
    ('5b45238c-c23d-4fbb-bfb0-61dc89babeb7'::uuid, date '2026-10-27', 'WMS1000380'),
    ('eb85a47a-103c-4565-84f1-6974bbf354df'::uuid, date '2026-10-27', 'WMS1000448'),
    ('4f1411ff-d074-4e41-96e9-7c4a17bbf5d9'::uuid, date '2026-10-27', 'WMS1000449'),
    ('48a4ab57-a445-462e-b8e3-16eecf5ac211'::uuid, date '2026-10-27', 'WMS1000450'),
    ('08e95070-07e4-45aa-9ec2-029f38bcdcdb'::uuid, date '2026-10-27', 'WMS1000455'),
    ('15ceec22-03ab-428b-8774-4c215e1c89b2'::uuid, date '2026-10-27', 'WMS1000456'),
    ('09c44cf2-90e9-4625-ba78-51512bb8f9f3'::uuid, date '2026-10-27', 'WMS1000458'),
    ('e41e853d-2c19-423e-a1b0-ca8c48a4547b'::uuid, date '2026-10-27', 'WMS1000459'),
    ('8392b0fd-31ac-44bc-b017-1ec85105ffc4'::uuid, date '2026-10-27', 'WMS1000463'),
    ('e19b581c-2617-445d-915a-0358d3a8b75a'::uuid, date '2026-10-27', 'WMS1000464'),
    ('47101fe1-6dc9-4428-a59c-31a3aa2326bc'::uuid, date '2026-10-28', null::text),
    ('1bb6a8a4-e93a-4cdd-bcda-d012d7fa838a'::uuid, date '2026-10-28', null::text),
    ('0e5ecad4-f2de-4b48-8a7b-83c7d9b848b9'::uuid, date '2026-10-28', 'WMS1000454'),
    ('088c083d-a206-46e3-a527-f67c7795ecaf'::uuid, date '2026-10-28', 'WMS1000454'),
    ('9f63bada-cc13-423c-904d-15b39449d1bf'::uuid, date '2026-10-28', 'WMS1000459'),
    ('35e7afe6-efce-4206-842e-2d8a257c23ce'::uuid, date '2026-10-28', 'WMS1000460'),
    ('0a238f50-854b-4beb-b1cf-b346dde11cf4'::uuid, date '2026-10-28', 'WMS1000461'),
    ('a7959c78-0d61-4ee3-9890-7f475f153be7'::uuid, date '2026-10-28', 'WMS1000462'),
    ('18bb4384-4625-484f-93de-e690cf1086c8'::uuid, date '2026-10-28', 'WMS1000463'),
    ('39b6ccd1-40bd-4478-8e20-ae4b2205ebe2'::uuid, date '2026-10-28', 'WMS1000469'),
    ('4cff0cef-427a-4211-8208-a842c7a4e18c'::uuid, date '2026-10-28', 'WMS1000469'),
    ('c4765f63-7de8-4cbe-8b44-0e1a708df519'::uuid, date '2026-10-29', null::text),
    ('6528284f-ca1c-43ca-9e8d-65d05b5ac821'::uuid, date '2026-10-29', null::text),
    ('96cc3460-4583-44a1-b61f-c840bfe6cfcf'::uuid, date '2026-10-29', null::text),
    ('b84c8bb6-2436-4d2b-bf2d-346164aca3f8'::uuid, date '2026-10-29', null::text),
    ('4ebe56a9-3cea-4ada-9209-42089573c50f'::uuid, date '2026-10-29', null::text),
    ('90e07bb4-cef4-4ae2-8cd9-25337b9d9d03'::uuid, date '2026-10-29', null::text);

do $$
begin
  if (select count(*) from public.tasks
      where due_date between date '2026-10-26' and date '2026-10-29') <> 8 then
    raise exception 'Le 26-29 octobre ne compte plus 8 lignes - arrêt (état changé depuis le constat)';
  end if;
  if exists (select 1 from public.tasks t join oct_restore r on r.new_number = t.erp_document_number) then
    raise exception 'Un numéro ERP à restaurer est déjà utilisé - arrêt';
  end if;
  if (select count(*) from public.tasks t join oct_restore r on r.source_id = t.id) <> 37 then
    raise exception 'Tâches sources de février introuvables - arrêt';
  end if;
end $$;

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
  t.building, t.type, 'NEW', t.priority, r.new_number, t.carrier, t.carrier_other,
  t.destination_k, t.destination_k_other, t.destination_s, t.destination_s_other,
  r.oct_date, t.due_time, t.bottle_count, t.pallet_count, t.package_count,
  t.dry_ice_carton_count, t.notes, t.created_by, t.is_bulk,
  t.other_shipment_category, t.other_shipment_category_other,
  t.temperature_conditions, t.temperature_group, t.transport_mode,
  false, false
from public.tasks t
join oct_restore r on r.source_id = t.id;

-- Vérification : 196 lignes en octobre ; 10 / 14 / 13 / 8 / 5 du 26 au 30 (comme février 23-27).
select due_date::text as label, count(*) as value from public.tasks
  where due_date between date '2026-10-26' and date '2026-10-30' group by due_date
union all
select 'octobre total', count(*) from public.tasks
  where due_date between date '2026-10-01' and date '2026-10-31'
order by label;

commit;
