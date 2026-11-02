-- Migration 029 — suppression des 30 préparations de carboglace orphelines.
--
-- Demande de l'utilisateur (2026-11-02) : supprimer les PREP_DRY_ICE que le
-- Backoffice liste sous « Orphan Dry Ice (30) », c'est-à-dire celles sans
-- aucune ERP_DOCUMENT portant le même erp_document_number. Toutes sont OUT
-- (historique de février à septembre 2026), 105 cartons au total ; aucune en
-- octobre ou novembre. Effet sur l'historique : -210 WU (2 WU par carton).
-- Liste d'id explicite, calculée en lecture seule le 2026-11-02, plus un
-- garde-fou : chaque ligne doit toujours être une PREP_DRY_ICE orpheline,
-- sinon tout est annulé.

begin;

create temporary table orphan_prep (id uuid primary key) on commit drop;
insert into orphan_prep (id) values
  ('09c44cf2-90e9-4625-ba78-51512bb8f9f3'::uuid),  -- 2026-02-24 WMS740555 1 cart.
  ('6c77d20a-e394-4139-b383-d77f8e7f1adf'::uuid),  -- 2026-05-05 WMS780852 3 cart.
  ('da78042d-9dc6-49c4-a23d-aac50d880a18'::uuid),  -- 2026-05-05 WMS780854 1 cart.
  ('8f3f9871-3797-45e4-bd69-b08d696b0418'::uuid),  -- 2026-06-15 WMS1000221 5 cart.
  ('a721155e-cd8a-44b7-8903-4bb94f5a9a8c'::uuid),  -- 2026-06-15 WMS1000227 3 cart.
  ('eca8e0de-5073-46e7-ae46-c74fa9bcbab6'::uuid),  -- 2026-07-10 WMS1000276 4 cart.
  ('12b1b5cb-693f-45bb-8588-6f1446ced38c'::uuid),  -- 2026-07-17 WMS1000290 2 cart.
  ('862d3bb4-fecb-42a1-8338-54cf2e2b18ae'::uuid),  -- 2026-07-17 WMS1000292 2 cart.
  ('c570e262-7afd-4eed-a2d8-8f5eb9c5c37f'::uuid),  -- 2026-07-17 WMS1000294 4 cart.
  ('93e43c5c-bb0e-443b-aa68-27dffc0f78e2'::uuid),  -- 2026-07-17 WMS1000296 3 cart.
  ('2d1aa6fa-8edc-4c2d-88ce-50ce034e90b9'::uuid),  -- 2026-07-23 WMS1000310 2 cart.
  ('edfde23a-2b5e-4cc2-83d9-d53aaebbf1b9'::uuid),  -- 2026-07-23 WMS1000312 4 cart.
  ('400d4198-e2c4-4057-a714-b0dc6df39d6b'::uuid),  -- 2026-07-30 WMS1000333 4 cart.
  ('c2b290a1-6916-47c1-81ca-a1227e7a7182'::uuid),  -- 2026-07-30 WMS1000338 4 cart.
  ('e07c639a-2b1f-4143-bed7-92ec57036c12'::uuid),  -- 2026-08-11 WMS1000279 4 cart.
  ('136efffc-a49c-47d6-a4ac-0939e39e909f'::uuid),  -- 2026-08-31 WMS1000330 1 cart.
  ('9f7618c3-a627-4b98-bf26-084b97800c96'::uuid),  -- 2026-08-31 WMS1000332 5 cart.
  ('a5c6d6f5-3670-4208-99ff-f3a3c737ceae'::uuid),  -- 2026-08-31 WMS1000335 4 cart.
  ('c477e7b3-0b69-4d21-b3ec-9b46a041b80d'::uuid),  -- 2026-08-31 WMS1000340 4 cart.
  ('0a76bead-6fa5-4a23-b01d-ece01a51f054'::uuid),  -- 2026-08-31 WMS1000341 1 cart.
  ('e5916265-3e0a-4e30-b385-17fccc8888e6'::uuid),  -- 2026-09-14 WMS1000140 5 cart.
  ('078974dc-7354-4ee8-a95f-9d327f2a8674'::uuid),  -- 2026-09-14 WMS1000142 5 cart.
  ('6e300d27-57a0-4406-9af3-264ce6b9c5de'::uuid),  -- 2026-09-14 WMS1000144 5 cart.
  ('9d668a77-646c-4cf6-ba46-6c303222df9e'::uuid),  -- 2026-09-14 WMS1000146 4 cart.
  ('529b5af6-6654-4205-9bd6-018d91e14614'::uuid),  -- 2026-09-21 WMS1000158 4 cart.
  ('a79a0033-d73e-4ceb-92bc-5afa7aec2e3d'::uuid),  -- 2026-09-21 WMS1000159 5 cart.
  ('b4aa4df1-4544-4f2f-927b-d184a9e85fda'::uuid),  -- 2026-09-21 WMS1000161 5 cart.
  ('b60d4ecc-22de-4f57-b31d-369e7c56c683'::uuid),  -- 2026-09-21 WMS1000163 5 cart.
  ('80b011ea-29b4-4d0f-8d44-15162d5b5eae'::uuid),  -- 2026-09-28 WMS1000199 3 cart.
  ('a066828e-e211-43e9-913d-94f069760184'::uuid)  -- 2026-09-28 WMS1000201 3 cart.
;

do $$
declare n int;
begin
  select count(*) into n
  from orphan_prep o
  join public.tasks t on t.id = o.id
  where t.type = 'PREP_DRY_ICE'
    and not exists (select 1 from public.tasks e
                    where e.type = 'ERP_DOCUMENT'
                      and e.erp_document_number = t.erp_document_number);
  if n <> 30 then
    raise exception 'Attendu 30 préparations orphelines, trouvé % - annulation', n;
  end if;
end $$;

delete from public.tasks t
using orphan_prep o
where t.id = o.id;

-- Vérification : 0 préparation orpheline restante.
select 'préparations orphelines restantes' as label, count(*) as value
from public.tasks p
where p.type = 'PREP_DRY_ICE'
  and not exists (select 1 from public.tasks e
                  where e.type = 'ERP_DOCUMENT'
                    and e.erp_document_number = p.erp_document_number);

commit;
