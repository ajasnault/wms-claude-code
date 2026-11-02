-- Migration 030 — donne des unités de travail aux 310 tâches à 0 WU.
--
-- Demande de l'utilisateur (2026-11-02) : « 1 carton par envoi » pour toutes
-- les tâches qui affichent 0 WU, sur tous les mois. Calculé en lecture seule
-- avec la logique exacte de calculateWorkUnits() et la work_unit_matrix live.
-- Une ligne n'est modifiée que là où il le faut, dans cet ordre :
-- 1) temperature_group NULL sur une ERP_DOCUMENT (anciennes copies) ->
--    AMBIENT (choix utilisateur). Aucune n'a de préparation de carboglace à
--    moins de 3 jours. 95 lignes.
-- 2) other_shipment_category NULL sur une OTHER_SHIPMENTS -> TNT_FEDEX :
--    DOMESTIC_SHIPMENT (comme les 203 autres TNT/FedEx), DUPERREX et OTHER :
--    OTHER (toutes leurs catégories valent 1 WU). 51 lignes.
-- 3) carrier NULL sur une ERP_DOCUMENT -> OTHER (aucune ligne de la matrice
--    sans transporteur). 4 lignes.
-- 4) Puis, si la tâche est toujours à 0 WU : 1 dans l'unité attendue par la
--    matrice (choix utilisateur) - 1 palette pour Essers/KN/World Courier/
--    Duperrex AMBIENT, 1 colis pour DHL/TNT et DRY_ICE, 1 carton pour les 2
--    PREP_DRY_ICE. Seulement là où le champ est vide ou à 0.
-- Résultat attendu : 0 tâche à 0 WU, +392.25 WU au total.
-- Les valeurs NULL de la liste veulent dire « inchangé ».

begin;

create temporary table wu_fix (
  id uuid primary key,
  carrier text, temperature_group text, other_shipment_category text,
  pallet_count int, package_count int, dry_ice_carton_count int
) on commit drop;
insert into wu_fix values
  ('28b6dc29-d07a-4bc9-a2f0-97f41c56ef4a'::uuid, null, null, null, 1, null, null),  -- 2025-12-02 ERP_DOCUMENT
  ('41ef5158-a9fb-4f33-ba0e-e6484016da41'::uuid, null, null, null, null, 1, null),  -- 2025-12-02 ERP_DOCUMENT
  ('46160dd9-b88a-4201-9ae8-876fa71341e9'::uuid, null, null, null, null, 1, null),  -- 2025-12-02 ERP_DOCUMENT
  ('9cf0bea0-c932-46fa-aff5-ea868f910bb2'::uuid, null, null, null, 1, null, null),  -- 2025-12-02 ERP_DOCUMENT
  ('ae5d6d3e-a8e6-4266-88ce-e52502e9a037'::uuid, null, null, null, null, 1, null),  -- 2025-12-02 ERP_DOCUMENT
  ('f3264e8f-ae42-40fc-a7c9-74c21a3fbeee'::uuid, null, null, null, null, 1, null),  -- 2025-12-02 ERP_DOCUMENT
  ('1a3699dd-5798-49c7-8dd5-cd7bf5e625b7'::uuid, null, null, null, 1, null, null),  -- 2025-12-03 ERP_DOCUMENT
  ('2345b3a4-80f6-4d41-baf2-de61b9d383e1'::uuid, null, null, null, 1, null, null),  -- 2025-12-03 ERP_DOCUMENT
  ('23c90b30-1517-402a-86c1-e456ecdfebe2'::uuid, null, null, null, 1, null, null),  -- 2025-12-03 ERP_DOCUMENT
  ('4c941d57-982e-44e0-8646-74f79267a34c'::uuid, null, null, null, 1, null, null),  -- 2025-12-03 ERP_DOCUMENT
  ('5583618e-a063-4beb-a25e-4af8c45cc16c'::uuid, null, null, null, 1, null, null),  -- 2025-12-03 ERP_DOCUMENT
  ('956860eb-a793-49a1-afb4-6fb6a1cebdf6'::uuid, null, null, null, 1, null, null),  -- 2025-12-03 ERP_DOCUMENT
  ('b6628fcc-3481-41f1-9af5-5ace82861e2f'::uuid, null, null, null, 1, null, null),  -- 2025-12-03 ERP_DOCUMENT
  ('3c955ed0-50ea-4741-9e36-8336c298952e'::uuid, null, null, null, null, 1, null),  -- 2025-12-05 ERP_DOCUMENT
  ('fad9b268-a740-424a-adb6-80ffc37bd821'::uuid, null, null, null, 1, null, null),  -- 2025-12-05 ERP_DOCUMENT
  ('1d74f6f7-a820-4aac-92ff-f09ae4aa2acb'::uuid, null, null, null, null, 1, null),  -- 2025-12-08 ERP_DOCUMENT
  ('b9b314e2-2a55-4a4d-b2af-426281723c9a'::uuid, null, null, null, 1, null, null),  -- 2025-12-08 ERP_DOCUMENT
  ('0aafe074-5cce-4d7a-81b7-4cc927453ef6'::uuid, null, null, null, null, 1, null),  -- 2025-12-09 ERP_DOCUMENT
  ('285280ed-274f-4131-8e8a-c8dfaeb873bc'::uuid, null, null, null, null, 1, null),  -- 2025-12-09 ERP_DOCUMENT
  ('59627a6c-82f0-4b32-986a-836c798ef06d'::uuid, null, null, null, null, 1, null),  -- 2025-12-09 ERP_DOCUMENT
  ('5f8ba8b0-c0e9-4051-9f21-a21bea4c9a6b'::uuid, null, null, null, null, 1, null),  -- 2025-12-09 ERP_DOCUMENT
  ('a052a077-9c6f-48ca-b3c4-6229f15b5b21'::uuid, 'OTHER', null, null, null, 1, null),  -- 2025-12-09 ERP_DOCUMENT
  ('bba4f496-cbef-4a99-a717-94bfcbe41409'::uuid, null, null, null, null, 1, null),  -- 2025-12-09 ERP_DOCUMENT
  ('f041bef2-55bb-4bda-a0db-b981f128fc15'::uuid, null, null, null, null, 1, null),  -- 2025-12-09 ERP_DOCUMENT
  ('190085fd-8265-4e92-bea1-37f00c52f43a'::uuid, null, null, null, null, null, 1),  -- 2025-12-09 PREP_DRY_ICE
  ('6003b2f9-5ee9-4641-a5b8-14f8b07c92f2'::uuid, null, null, null, null, null, 1),  -- 2025-12-09 PREP_DRY_ICE
  ('11029015-31a3-4759-bf3b-6e1f6223217a'::uuid, null, null, null, 1, null, null),  -- 2025-12-10 ERP_DOCUMENT
  ('490bf429-c288-48a4-bf5f-1a30b3541455'::uuid, null, null, null, 1, null, null),  -- 2025-12-10 ERP_DOCUMENT
  ('91b07989-62b7-4dc2-82a3-12481b4ba8bb'::uuid, null, null, null, null, 1, null),  -- 2025-12-10 ERP_DOCUMENT
  ('9a79c64d-082c-49fa-a187-fb6b91c422fa'::uuid, null, null, null, null, 1, null),  -- 2025-12-10 ERP_DOCUMENT
  ('a0b324c4-3ddb-4a6e-8986-68e507832ebf'::uuid, null, null, null, null, 1, null),  -- 2025-12-10 ERP_DOCUMENT
  ('cce5bb31-8f5f-465d-8423-27e91bfa5098'::uuid, null, null, null, 1, null, null),  -- 2025-12-10 ERP_DOCUMENT
  ('e9bf33db-87f4-4204-8773-6db825bfe2ea'::uuid, null, null, null, 1, null, null),  -- 2025-12-10 ERP_DOCUMENT
  ('fc633109-b414-42bb-93c7-e6cda3ac881b'::uuid, null, null, null, null, 1, null),  -- 2025-12-10 ERP_DOCUMENT
  ('1267ddf5-aacb-4f8e-8aec-0a97846c7943'::uuid, null, null, null, 1, null, null),  -- 2025-12-15 ERP_DOCUMENT
  ('46177810-92a2-4f40-9ef6-a9938c3685e7'::uuid, null, null, null, null, 1, null),  -- 2025-12-15 ERP_DOCUMENT
  ('7392f255-0889-443e-bb41-9832e9c620f0'::uuid, null, null, null, null, 1, null),  -- 2025-12-15 ERP_DOCUMENT
  ('7c1169fc-b30d-4cd0-b372-82fd811e1c55'::uuid, null, null, null, null, 1, null),  -- 2025-12-15 ERP_DOCUMENT
  ('9f9e76f1-6eb6-429c-ab6c-d47af12f5d04'::uuid, null, null, null, 1, null, null),  -- 2025-12-15 ERP_DOCUMENT
  ('c66d21bf-950a-458e-8569-0898803afb4d'::uuid, null, null, null, 1, null, null),  -- 2025-12-15 ERP_DOCUMENT
  ('02f63381-81e2-4821-bf73-a57d43d53eba'::uuid, null, null, null, null, 1, null),  -- 2025-12-17 ERP_DOCUMENT
  ('2366ba78-d61d-4f15-808c-b8eee2b6f618'::uuid, null, null, null, null, 1, null),  -- 2025-12-17 ERP_DOCUMENT
  ('4a9ac9c7-bb54-46a1-a1d3-123c80ae3763'::uuid, null, null, null, 1, null, null),  -- 2025-12-17 ERP_DOCUMENT
  ('7ed2e277-0310-4ccd-9b7f-2e56dd112e05'::uuid, null, null, null, 1, null, null),  -- 2025-12-17 ERP_DOCUMENT
  ('aa4b5b31-7854-4d7e-8471-0eb52c340afe'::uuid, null, null, null, 1, null, null),  -- 2025-12-17 ERP_DOCUMENT
  ('af8981f6-38fd-4646-8f51-5cfd22c8bd3c'::uuid, null, null, null, null, 1, null),  -- 2025-12-17 ERP_DOCUMENT
  ('bafde0fe-ac95-41a1-9251-1367145bbc15'::uuid, null, null, null, null, 1, null),  -- 2025-12-17 ERP_DOCUMENT
  ('cb34dc23-bea4-45b5-8494-f03987e70263'::uuid, null, null, null, null, 1, null),  -- 2025-12-17 ERP_DOCUMENT
  ('d32a3daf-2468-464e-b81e-854de9c2f303'::uuid, null, null, null, null, 1, null),  -- 2025-12-17 ERP_DOCUMENT
  ('e10c93b1-59c8-47f8-84b5-d4cd7edf9557'::uuid, null, null, null, null, 1, null),  -- 2025-12-17 ERP_DOCUMENT
  ('f847fca3-6111-4581-a73c-28c24789923a'::uuid, null, null, null, 1, null, null),  -- 2025-12-17 ERP_DOCUMENT
  ('b2f64e16-f681-4445-9e4e-127847caa11f'::uuid, null, null, null, null, 1, null),  -- 2025-12-18 ERP_DOCUMENT
  ('99c2609b-7357-4178-b9e4-438500fb8962'::uuid, null, null, null, 1, null, null),  -- 2025-12-19 ERP_DOCUMENT
  ('8a668809-a70c-47da-b923-4f3d0d50c570'::uuid, null, null, null, 1, null, null),  -- 2025-12-22 ERP_DOCUMENT
  ('ba776c51-f7ce-4fdd-a8e6-6f8c11ee57d9'::uuid, null, null, null, null, 1, null),  -- 2025-12-22 ERP_DOCUMENT
  ('d74d0f6d-e4c8-42b9-b532-3ba922a88ae6'::uuid, null, null, null, null, 1, null),  -- 2025-12-22 ERP_DOCUMENT
  ('0a19216c-9697-4ea4-a4d5-d25ad136be58'::uuid, null, null, null, null, 1, null),  -- 2026-01-05 ERP_DOCUMENT
  ('f77079dd-5242-4bd8-ac6d-8a984470aa76'::uuid, null, null, null, null, 1, null),  -- 2026-01-05 ERP_DOCUMENT
  ('2779fab3-f977-465a-ad12-26f17019347e'::uuid, null, null, null, 1, null, null),  -- 2026-01-07 ERP_DOCUMENT
  ('474b7216-0cca-4cba-a139-776401f79d9e'::uuid, null, null, null, 1, null, null),  -- 2026-01-07 ERP_DOCUMENT
  ('4efd84ae-b36b-49c2-b6b8-69719a964958'::uuid, null, null, null, null, 1, null),  -- 2026-01-07 ERP_DOCUMENT
  ('88e58bc3-4a4d-418a-80e4-1108cb112c2b'::uuid, null, null, null, null, 1, null),  -- 2026-01-07 ERP_DOCUMENT
  ('904c24a3-4549-4365-9d5c-9a27f20b5295'::uuid, null, null, null, null, 1, null),  -- 2026-01-07 ERP_DOCUMENT
  ('ca65c618-d985-487c-a8ed-4d590010a8ff'::uuid, null, null, null, 1, null, null),  -- 2026-01-07 ERP_DOCUMENT
  ('b64d73ea-2f03-44fc-aa43-36ab1c0c9f5f'::uuid, null, null, null, null, 1, null),  -- 2026-01-08 ERP_DOCUMENT
  ('e5cf1169-1f6e-47f6-8e52-14a2b216653a'::uuid, null, null, null, 1, null, null),  -- 2026-01-13 ERP_DOCUMENT
  ('818dd2d6-97ec-4792-9cc9-5df1011b2116'::uuid, null, null, null, 1, null, null),  -- 2026-01-14 ERP_DOCUMENT
  ('ad56da0f-7337-4cab-ab47-4705aa765d29'::uuid, null, null, null, 1, null, null),  -- 2026-01-14 ERP_DOCUMENT
  ('ae23f416-aab4-486a-b941-0413122c3ad4'::uuid, null, null, null, null, 1, null),  -- 2026-01-19 ERP_DOCUMENT
  ('3487c3d1-84d8-47b7-a2fd-8d0513562bbf'::uuid, null, null, null, 1, null, null),  -- 2026-01-21 ERP_DOCUMENT
  ('3c0abd24-2e82-451c-a369-3a5844611390'::uuid, null, null, null, 1, null, null),  -- 2026-01-21 ERP_DOCUMENT
  ('109dca0a-826a-45df-871b-ecf5d68897c6'::uuid, null, null, null, 1, null, null),  -- 2026-01-28 ERP_DOCUMENT
  ('480a070a-b326-43a3-b190-821c407fdc7f'::uuid, null, null, null, 1, null, null),  -- 2026-01-28 ERP_DOCUMENT
  ('73ddc464-6549-4fdb-abed-422af6b3a59c'::uuid, null, null, null, 1, null, null),  -- 2026-01-28 ERP_DOCUMENT
  ('ba4578ad-55a6-4eba-a2a0-bf961b85b98b'::uuid, null, null, null, 1, null, null),  -- 2026-02-04 ERP_DOCUMENT
  ('e05ad517-260d-4d5c-8f7f-3f8f829a07e6'::uuid, null, null, null, 1, null, null),  -- 2026-02-04 ERP_DOCUMENT
  ('e4746c02-9967-4c80-98c2-b71f87393d9a'::uuid, null, null, null, 1, null, null),  -- 2026-02-10 ERP_DOCUMENT
  ('e72b212d-2fb2-41b9-b483-b18852ced953'::uuid, null, null, null, 1, null, null),  -- 2026-02-11 ERP_DOCUMENT
  ('540ab627-2add-4c50-81a5-3923e3a6141f'::uuid, null, null, null, 1, null, null),  -- 2026-02-16 ERP_DOCUMENT
  ('651a775c-7a56-4f1d-b6cc-8b8585956521'::uuid, null, null, null, 1, null, null),  -- 2026-02-18 ERP_DOCUMENT
  ('a69e9500-0658-43d7-b2d1-1b39aaf09a1f'::uuid, null, null, null, 1, null, null),  -- 2026-02-18 ERP_DOCUMENT
  ('e758fb12-fd5d-425b-b874-0c8d4f0ec671'::uuid, null, null, null, 1, null, null),  -- 2026-02-18 ERP_DOCUMENT
  ('4ff4c70e-d3e5-4cd0-b3b1-eed085edd087'::uuid, 'OTHER', null, null, null, null, null),  -- 2026-02-23 ERP_DOCUMENT
  ('35e7afe6-efce-4206-842e-2d8a257c23ce'::uuid, null, null, null, 1, null, null),  -- 2026-02-25 ERP_DOCUMENT
  ('a7959c78-0d61-4ee3-9890-7f475f153be7'::uuid, null, null, null, 1, null, null),  -- 2026-02-25 ERP_DOCUMENT
  ('1b2f7004-59e2-4dab-8044-de067b681ba3'::uuid, null, null, null, 1, null, null),  -- 2026-03-03 ERP_DOCUMENT
  ('5bb6b683-dfdc-446a-91fb-0c5c2d7042b0'::uuid, null, null, null, 1, null, null),  -- 2026-03-11 ERP_DOCUMENT
  ('aeeb9972-60fb-440f-ad7e-a30c4c0fb23b'::uuid, null, null, null, 1, null, null),  -- 2026-03-11 ERP_DOCUMENT
  ('fa5518ff-bf2f-47ff-b22b-db5f152d933c'::uuid, null, null, null, null, 1, null),  -- 2026-03-11 ERP_DOCUMENT
  ('503e6a71-05ae-4ba8-9454-1f6b5122c97e'::uuid, null, null, null, 1, null, null),  -- 2026-03-12 ERP_DOCUMENT
  ('3893c810-2f17-4e61-920a-6daaac865cc8'::uuid, null, null, null, 1, null, null),  -- 2026-03-18 ERP_DOCUMENT
  ('4c20d31e-7730-4bc8-ae88-897b83aa0087'::uuid, null, null, null, 1, null, null),  -- 2026-03-18 ERP_DOCUMENT
  ('60d42917-5eb4-42ac-8e0f-9ef649bbc8fe'::uuid, null, null, null, 1, null, null),  -- 2026-03-18 ERP_DOCUMENT
  ('75cd4d10-2ee4-4df7-a94c-3ee2eb57da0c'::uuid, null, null, null, 1, null, null),  -- 2026-03-18 ERP_DOCUMENT
  ('22116054-c225-400b-97c0-4b857000e682'::uuid, null, null, null, 1, null, null),  -- 2026-03-25 ERP_DOCUMENT
  ('bb8f1490-da32-49f7-ad11-4915200176b2'::uuid, null, null, null, 1, null, null),  -- 2026-03-25 ERP_DOCUMENT
  ('98ebdce7-40b1-48ac-8b08-b48f83327d53'::uuid, null, null, null, 1, null, null),  -- 2026-03-27 ERP_DOCUMENT
  ('05ad5d76-cfd0-44d0-96ca-9602971ccace'::uuid, null, null, null, 1, null, null),  -- 2026-04-01 ERP_DOCUMENT
  ('9763b9b6-5fb7-48d7-b399-1e9298e2eae5'::uuid, null, null, null, 1, null, null),  -- 2026-04-01 ERP_DOCUMENT
  ('527ecdf6-5779-4aa7-86df-e2a87b9c013b'::uuid, null, null, null, 1, null, null),  -- 2026-04-17 ERP_DOCUMENT
  ('f517ccfc-7f98-41fa-9450-8879b54f4105'::uuid, null, null, null, 1, null, null),  -- 2026-04-17 ERP_DOCUMENT
  ('1b44c849-0594-4a39-943d-4158218172e1'::uuid, null, null, null, 1, null, null),  -- 2026-04-21 ERP_DOCUMENT
  ('49cc572c-f510-4bfd-b327-ff18e3a678ae'::uuid, null, null, null, 1, null, null),  -- 2026-04-21 ERP_DOCUMENT
  ('07c0f65a-9ec9-43f7-a2fa-22e398571cc6'::uuid, null, null, null, 1, null, null),  -- 2026-04-28 ERP_DOCUMENT
  ('40181ce6-6176-4b8d-8764-52a23b668408'::uuid, null, null, null, 1, null, null),  -- 2026-04-28 ERP_DOCUMENT
  ('dbd7acfa-5410-4e5b-af43-0e35c68636af'::uuid, null, null, null, 1, null, null),  -- 2026-04-28 ERP_DOCUMENT
  ('fd3d3724-0e38-45ff-bc30-60c9d19c5074'::uuid, null, null, null, 1, null, null),  -- 2026-05-05 ERP_DOCUMENT
  ('2c485672-7c1f-4a63-b68b-7527671c2e06'::uuid, null, null, null, 1, null, null),  -- 2026-05-06 ERP_DOCUMENT
  ('5c760ca8-5ec9-478a-83a6-a21ad41ff56f'::uuid, null, null, null, 1, null, null),  -- 2026-05-06 ERP_DOCUMENT
  ('8267b016-4c2f-4bd4-97e3-1ec9244e09da'::uuid, null, null, null, 1, null, null),  -- 2026-05-06 ERP_DOCUMENT
  ('9bab44fa-7138-4b7b-9d86-3993e871d149'::uuid, null, null, null, 1, null, null),  -- 2026-05-20 ERP_DOCUMENT
  ('194584b7-1325-4f6f-a631-e89780bf25a8'::uuid, null, null, null, 1, null, null),  -- 2026-05-28 ERP_DOCUMENT
  ('23d56fbc-ac41-4bf8-b8ac-a5f5675eb6a1'::uuid, null, null, null, 1, null, null),  -- 2026-05-28 ERP_DOCUMENT
  ('3bb1f623-bff7-43cc-9c9e-7d2c4180a447'::uuid, null, null, null, 1, null, null),  -- 2026-05-28 ERP_DOCUMENT
  ('3578ab7f-c20a-4ffc-88d0-807ba7a52df9'::uuid, null, null, null, 1, null, null),  -- 2026-06-03 ERP_DOCUMENT
  ('b022f6f3-107e-4a71-ae38-a5bccfe2dd03'::uuid, null, null, null, 1, null, null),  -- 2026-06-03 ERP_DOCUMENT
  ('e227d993-b060-45a1-93f8-2b7fe659cd24'::uuid, null, null, null, 1, null, null),  -- 2026-06-03 ERP_DOCUMENT
  ('37ac7227-4b50-4423-8ed9-f76e47696400'::uuid, null, null, null, 1, null, null),  -- 2026-06-10 ERP_DOCUMENT
  ('4e98b1d6-d02a-462b-959b-aee70f81b1f9'::uuid, null, null, null, 1, null, null),  -- 2026-06-10 ERP_DOCUMENT
  ('1f7c9803-ae63-408b-95db-7b5ecba8b762'::uuid, null, null, null, 1, null, null),  -- 2026-06-17 ERP_DOCUMENT
  ('215e2309-af83-40d9-8fe8-8359849d35b1'::uuid, null, null, null, 1, null, null),  -- 2026-06-17 ERP_DOCUMENT
  ('b76f52f6-c896-43e5-80d9-b7875c1d24ac'::uuid, 'OTHER', null, null, null, 1, null),  -- 2026-06-19 ERP_DOCUMENT
  ('f4a2d720-bdf2-4a55-a0d2-9d0f4b8154c9'::uuid, null, null, null, 1, null, null),  -- 2026-06-23 ERP_DOCUMENT
  ('4c7cfa52-5405-47a9-bd9f-70d707829a69'::uuid, null, null, null, 1, null, null),  -- 2026-06-24 ERP_DOCUMENT
  ('8564c634-1af5-49cb-af07-82d0179883cc'::uuid, null, null, null, 1, null, null),  -- 2026-06-30 ERP_DOCUMENT
  ('31754427-bbaa-4470-ae1b-0f5cede1a072'::uuid, null, null, null, 1, null, null),  -- 2026-07-03 ERP_DOCUMENT
  ('6cb1a479-d5c0-425f-b8f3-c0b5a6a297a2'::uuid, null, null, null, 1, null, null),  -- 2026-07-11 ERP_DOCUMENT
  ('ae9e6acc-0929-415c-b9a0-d8ba4534c945'::uuid, null, null, null, 1, null, null),  -- 2026-07-11 ERP_DOCUMENT
  ('c242c67a-80d8-4c99-ada4-daccf45f2d25'::uuid, null, null, null, null, 1, null),  -- 2026-07-11 ERP_DOCUMENT
  ('6dc111af-ba55-4016-81f1-957fb94ae356'::uuid, null, null, null, 1, null, null),  -- 2026-07-12 ERP_DOCUMENT
  ('35f8bf7c-96e2-496e-b096-0a24cd81098b'::uuid, null, null, null, 1, null, null),  -- 2026-07-18 ERP_DOCUMENT
  ('55b71584-44e3-4fd0-872d-3c509b98ffa4'::uuid, null, null, null, 1, null, null),  -- 2026-07-18 ERP_DOCUMENT
  ('9dc4b5cb-7ec9-47b5-bea3-2501fd384dd2'::uuid, null, null, null, 1, null, null),  -- 2026-07-18 ERP_DOCUMENT
  ('cb325a16-0fdd-4664-91bf-91281ad3c24c'::uuid, null, null, null, 1, null, null),  -- 2026-07-18 ERP_DOCUMENT
  ('4acaccce-d5e6-4570-b3cc-28e39db556dd'::uuid, null, null, null, 1, null, null),  -- 2026-07-25 ERP_DOCUMENT
  ('e4637a83-3096-4e39-ad52-e4cac6141ade'::uuid, null, null, null, 1, null, null),  -- 2026-07-25 ERP_DOCUMENT
  ('d42e106c-a39e-4b43-9f07-1cd5ee94153d'::uuid, null, null, null, 1, null, null),  -- 2026-07-27 ERP_DOCUMENT
  ('b07760bc-5e6e-4e78-8c1e-986b45a4c449'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-03 ERP_DOCUMENT
  ('3f38f43d-262a-4051-b927-99f24ef6e419'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-04 ERP_DOCUMENT
  ('793faacc-9251-4bef-92d9-30624a3a3fdb'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-04 ERP_DOCUMENT
  ('890b02ef-f076-4c4b-b2cc-31f02fd83f68'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-04 ERP_DOCUMENT
  ('bbdfad7c-0310-4da1-9020-eb42b5f33403'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-04 ERP_DOCUMENT
  ('df195fd8-b9cb-40f0-b243-0c9926a7bc77'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-04 ERP_DOCUMENT
  ('09ac4f7a-80ad-4fb6-bb4e-96f0422b3b1e'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-04 OTHER_SHIPMENTS
  ('6fc8755c-5437-49b3-9250-2e66ac797a48'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-05 OTHER_SHIPMENTS
  ('fa553caf-e0db-44b8-9923-a77b246f59b6'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-06 ERP_DOCUMENT
  ('05c16e27-cb16-469d-848e-94df38c8ddf4'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-07 ERP_DOCUMENT
  ('141236eb-d7fb-4d62-8df0-5241e25eca18'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-07 ERP_DOCUMENT
  ('86beb82f-f8b1-4a8f-94f8-018a2868a1f6'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-11 ERP_DOCUMENT
  ('ebedeadb-2db6-40c1-ba15-60ba778c5cea'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-11 ERP_DOCUMENT
  ('26c2a238-9aad-47d4-9c23-086fe81736b5'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-11 OTHER_SHIPMENTS
  ('53de5765-b288-4dc0-8a53-61c371c9bc40'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-11 OTHER_SHIPMENTS
  ('80a310e0-39af-420a-9d0d-b12640f7d5c2'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-11 OTHER_SHIPMENTS
  ('dc8b5adc-8ac9-4b2f-b072-93025c6f2da6'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-11 OTHER_SHIPMENTS
  ('30055a0b-adb5-4a9b-ab60-6c11b4fbd9e8'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-12 ERP_DOCUMENT
  ('36c43be5-d2aa-451d-a84d-bfe34e5422f9'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-12 ERP_DOCUMENT
  ('8a04926a-2541-4322-a509-d4d82bfcefe0'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-12 ERP_DOCUMENT
  ('9691896c-63d0-430c-898e-acbdbd749171'::uuid, null, null, null, null, 1, null),  -- 2026-08-12 ERP_DOCUMENT
  ('ded86e3a-1095-40e1-9570-6b1c2158ad25'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-12 ERP_DOCUMENT
  ('e9df008f-f4b6-473f-9351-754cbf529ce1'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-12 ERP_DOCUMENT
  ('a6b1fc5d-a3db-4bfd-b455-534517876390'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-12 OTHER_SHIPMENTS
  ('0f54c6b0-2c55-405e-af08-efd6b39045d4'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-13 ERP_DOCUMENT
  ('519a910e-00d2-4034-a93c-e65245e32c80'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-14 ERP_DOCUMENT
  ('c0a53d7c-8cd3-48f2-b56e-8f74c2972385'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-17 ERP_DOCUMENT
  ('c24e6985-17a4-43aa-b722-7c224ddac25e'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-17 OTHER_SHIPMENTS
  ('d9b2cca4-afb6-46c6-a969-3aa3b19d2db2'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-17 OTHER_SHIPMENTS
  ('e8d05f81-a9c5-4642-b7f3-c65a8dc28e6b'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-17 OTHER_SHIPMENTS
  ('4328dc7a-246b-442a-9cc9-630562307b39'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-18 ERP_DOCUMENT
  ('6bc1431c-325e-4300-a354-b1ff22e07f83'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-18 ERP_DOCUMENT
  ('a21a28a8-a1d8-456c-9cac-ecb0f9db61ad'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-18 ERP_DOCUMENT
  ('a86a7aeb-2673-485f-ab36-c1340798ccfc'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-18 ERP_DOCUMENT
  ('908905f3-cd58-4abd-a6dc-6632ac2ac57d'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-18 OTHER_SHIPMENTS
  ('23c82c01-10af-4707-a42e-e44cdf0c8b57'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-19 ERP_DOCUMENT
  ('29e57122-60c5-4ac1-a7b1-a9c8108978a3'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-19 ERP_DOCUMENT
  ('6d42fa03-5426-4cbe-8613-8a437f29d353'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-19 ERP_DOCUMENT
  ('8182284d-076c-45e3-992f-fa51ef1078f6'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-19 ERP_DOCUMENT
  ('c3a931e0-5eec-4ee8-bf1b-c70d00909eec'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-19 ERP_DOCUMENT
  ('96100d37-bd06-432f-8563-35b5356f80bb'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-19 OTHER_SHIPMENTS
  ('273e1a4b-1878-4633-8b62-f35222d1d314'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-20 ERP_DOCUMENT
  ('f536031d-8be1-4b12-a0ab-a96b3795c2d6'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-20 ERP_DOCUMENT
  ('9c8b7c42-e42d-44e0-b60c-e93cf857fd6b'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-21 ERP_DOCUMENT
  ('e9c7f96d-622d-46fd-8def-bbca029a5233'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-21 ERP_DOCUMENT
  ('4bb40371-ff8f-4695-8ac0-577a348c9196'::uuid, null, null, 'OTHER', null, null, null),  -- 2026-08-21 OTHER_SHIPMENTS
  ('6c9c80fc-e5a7-43d2-8f9b-e39930b4afe6'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-21 OTHER_SHIPMENTS
  ('7dee964c-5e91-4c9b-8a45-7e03d783ceb1'::uuid, null, null, 'OTHER', null, null, null),  -- 2026-08-21 OTHER_SHIPMENTS
  ('75ca487e-2760-4581-a123-384f0dc167cf'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-24 ERP_DOCUMENT
  ('11471348-1a2e-4ce0-908c-1dcfaed37b5c'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-25 ERP_DOCUMENT
  ('49cd7964-bd20-4adb-8527-3139c6b77f65'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-25 ERP_DOCUMENT
  ('4daaeb56-5e7f-43a9-8083-99e222c55f45'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-25 ERP_DOCUMENT
  ('4fcee6ec-0b22-4969-901a-4995ede03ece'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-25 ERP_DOCUMENT
  ('756158dd-3b1d-459d-b8df-e6b89861569b'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-25 ERP_DOCUMENT
  ('cf56b5de-56e4-4dfd-a269-64b5c34cdf29'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-25 ERP_DOCUMENT
  ('f01aafc5-8493-4c40-9109-a0dcb1fdb4d5'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-25 ERP_DOCUMENT
  ('26c00fc5-47a6-4355-a1a3-4d434e4b47f0'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-25 OTHER_SHIPMENTS
  ('75606459-69ef-47af-9f61-b606a6b9871e'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-25 OTHER_SHIPMENTS
  ('85caa094-123f-485b-854d-ab96810ac70b'::uuid, null, null, 'OTHER', null, null, null),  -- 2026-08-25 OTHER_SHIPMENTS
  ('a3ed7d64-eb48-4549-9e43-0c0ede39c79c'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-25 OTHER_SHIPMENTS
  ('bf898ea4-ba2b-4518-8dd2-88ad3b6794f8'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-25 OTHER_SHIPMENTS
  ('eec7cd7e-693b-49e6-babc-53ae8285044f'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-25 OTHER_SHIPMENTS
  ('009226a2-1958-4912-bfb2-a42163883d2e'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-26 ERP_DOCUMENT
  ('2c97888a-fae0-4fee-9fd0-820e20f238d5'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-26 ERP_DOCUMENT
  ('d4cd40f0-56e9-48ce-b1ee-7148e9092300'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-26 ERP_DOCUMENT
  ('e941a504-c28c-4f26-9842-122186329947'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-26 ERP_DOCUMENT
  ('019d7eb8-59b7-4ffb-96f9-d7f003a6d730'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-26 OTHER_SHIPMENTS
  ('23e9d33c-c9d6-480f-a34a-efef1324405d'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-26 OTHER_SHIPMENTS
  ('844ddd90-084e-4a23-a773-4a2bdff9a57f'::uuid, null, null, 'OTHER', null, null, null),  -- 2026-08-26 OTHER_SHIPMENTS
  ('ae3faccc-8346-45b9-a38d-5ae5e81907cc'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-26 OTHER_SHIPMENTS
  ('19cb5a61-7847-4932-a8dc-c6bcdd4120e2'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-27 OTHER_SHIPMENTS
  ('6aa2ce33-65ed-4c59-83a9-4508778d061c'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-08-28 ERP_DOCUMENT
  ('e916f973-73cb-4006-b8a9-c4e3821738c0'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-08-28 ERP_DOCUMENT
  ('3e2865c6-f0fa-4528-942c-52983de472d1'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-28 OTHER_SHIPMENTS
  ('61539977-af79-43e5-815c-bf7e17bc3d56'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-08-28 OTHER_SHIPMENTS
  ('73eec317-dfae-4c15-b27d-0e8d1c039298'::uuid, null, null, 'OTHER', null, null, null),  -- 2026-08-28 OTHER_SHIPMENTS
  ('94e84b9f-295f-4ae1-ade9-2d2c0f39c357'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-01 OTHER_SHIPMENTS
  ('0c158892-e20d-426b-a61f-14c6a8fadcd8'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-02 ERP_DOCUMENT
  ('1848dd56-d4c8-408b-bd22-a9f8278b6bb3'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-02 ERP_DOCUMENT
  ('4c3f7091-dae8-4c8f-be83-737b2482d5c9'::uuid, null, null, null, null, 1, null),  -- 2026-09-02 ERP_DOCUMENT
  ('5e47ed27-dfaf-4833-b7e6-c6e11ec34ae5'::uuid, null, null, null, null, 1, null),  -- 2026-09-02 ERP_DOCUMENT
  ('8f788231-13f6-4db8-ba07-a79216571e14'::uuid, null, null, null, null, 1, null),  -- 2026-09-02 ERP_DOCUMENT
  ('f38dca36-9937-4d98-9fbc-a60313bf434e'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-02 ERP_DOCUMENT
  ('4bc30624-06cd-462c-ab78-43603e099877'::uuid, null, 'AMBIENT', null, null, 1, null),  -- 2026-09-07 ERP_DOCUMENT
  ('1253a587-887f-472a-8972-4fa918c76e63'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-08 ERP_DOCUMENT
  ('3500117c-5c8f-417c-87fb-a841dc4136b5'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-08 ERP_DOCUMENT
  ('c63b0929-86bd-4053-bd99-a357220a4cba'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-08 ERP_DOCUMENT
  ('cd7dc5f6-c102-4ceb-9e97-22b3872098ac'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-08 ERP_DOCUMENT
  ('e28d75e0-b1c1-4388-a55e-4f573ab9601b'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-08 ERP_DOCUMENT
  ('e5706e6e-3ee9-4001-bdaa-2d60c543911c'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-08 ERP_DOCUMENT
  ('4bdf90ed-020f-4526-acb3-485a88f61834'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-08 OTHER_SHIPMENTS
  ('7268559d-2351-4709-9607-fa16b385d410'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-08 OTHER_SHIPMENTS
  ('ec108c5f-96d7-48a0-af1d-1b9bd5530706'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-08 OTHER_SHIPMENTS
  ('03267532-a2ed-453c-b2bb-d147ebcf7614'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-09 ERP_DOCUMENT
  ('524bf596-a296-47e8-bc09-13784411eb95'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-09 ERP_DOCUMENT
  ('71bf198f-3880-40b6-925a-834fabd54295'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-09 ERP_DOCUMENT
  ('c72cfd98-1f73-4467-87e7-b6fa4136bcd6'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-09 ERP_DOCUMENT
  ('d5f88003-3c03-417d-a966-291f0c9dd97a'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-09 ERP_DOCUMENT
  ('27abdab5-cd61-4a16-8c13-b4bee122680c'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-09 OTHER_SHIPMENTS
  ('e8721f60-fa0f-4f73-9999-c53453281d4c'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-10 ERP_DOCUMENT
  ('e2dab64c-2679-4567-8c57-0f9e8285e9a7'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-14 ERP_DOCUMENT
  ('50619d60-dc8a-4196-97e2-f242eb3aa35f'::uuid, null, null, 'OTHER', null, null, null),  -- 2026-09-14 OTHER_SHIPMENTS
  ('d2a3a510-cf26-4133-8991-f44c376d6956'::uuid, null, null, 'OTHER', null, null, null),  -- 2026-09-14 OTHER_SHIPMENTS
  ('9ad3859a-81db-4f9f-9cf4-81a232ad63b7'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-15 ERP_DOCUMENT
  ('acbbb817-7612-4a57-a9d6-04cae66244ff'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-15 ERP_DOCUMENT
  ('c13e6897-d8f0-41ec-b768-4ddec7298fcd'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-15 ERP_DOCUMENT
  ('e5eb35ec-f245-41c7-87ec-a8d3569d3c99'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-15 ERP_DOCUMENT
  ('f1a6966e-d389-48cc-be3d-2f409aa93108'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-15 ERP_DOCUMENT
  ('02d47c1f-df2a-48db-a3fb-0fcd702313c5'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-16 ERP_DOCUMENT
  ('22c5ec1c-e1d6-43b2-9de3-51ab34e1ebe7'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-16 ERP_DOCUMENT
  ('445e1f3c-6551-4800-abab-a8baab45d55e'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-16 ERP_DOCUMENT
  ('7d4fbd7e-7edf-485d-8969-b194fd9c65e4'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-16 ERP_DOCUMENT
  ('c9bd7c04-4db1-440a-910e-3835d4e883f5'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-16 ERP_DOCUMENT
  ('e64102e5-8d5f-4608-8bbd-987aeddf6472'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-16 ERP_DOCUMENT
  ('ff0ab740-8d17-4167-98b7-038e4623c013'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-16 ERP_DOCUMENT
  ('2967528e-4188-44b5-b716-04d39adff204'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-16 OTHER_SHIPMENTS
  ('346f0e8a-66cf-4b4a-84e7-b79124ac9671'::uuid, null, null, 'OTHER', null, null, null),  -- 2026-09-17 OTHER_SHIPMENTS
  ('313741d1-7dcf-49d1-b411-c4b688e8d1ac'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-21 ERP_DOCUMENT
  ('367feea8-cd0b-4d45-af81-b28556bce318'::uuid, null, 'AMBIENT', null, null, 1, null),  -- 2026-09-21 ERP_DOCUMENT
  ('3996ab6e-57c4-4ece-9cf8-db26ed21eb45'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-21 OTHER_SHIPMENTS
  ('57484299-317f-4b7b-b3c9-5700a809c499'::uuid, null, null, 'OTHER', null, null, null),  -- 2026-09-21 OTHER_SHIPMENTS
  ('11310e14-2381-422b-b606-92579c867e64'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-22 ERP_DOCUMENT
  ('6688fda7-4c33-4d68-92e6-bd89c5c4ddc1'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-22 ERP_DOCUMENT
  ('d274394e-fb21-4f26-be7e-105b0de026ab'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-22 ERP_DOCUMENT
  ('4f65136e-b0be-4c59-88e3-19004fd2ab48'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-22 OTHER_SHIPMENTS
  ('ebd82c7e-e2db-47d0-909f-45b2e1f66419'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-22 OTHER_SHIPMENTS
  ('0aef489a-6369-4a7d-9fdc-192f2bf72a80'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-23 ERP_DOCUMENT
  ('576b392e-043d-4da2-a9b7-e7b4c0c7bb02'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-23 ERP_DOCUMENT
  ('69065880-78bb-4479-83eb-38b1c2ee2886'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-23 ERP_DOCUMENT
  ('6d2d28cd-f299-4ea0-b590-731317ab4fea'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-23 ERP_DOCUMENT
  ('8131278c-640a-4e2b-987d-6509e2eebae3'::uuid, null, 'AMBIENT', null, 1, null, null),  -- 2026-09-23 ERP_DOCUMENT
  ('f7071e11-cd99-4f3c-96df-8f6aa4134a7b'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-23 ERP_DOCUMENT
  ('14505a09-0aa0-480b-9781-16daa39806a6'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-24 ERP_DOCUMENT
  ('1ab858f5-8a16-485b-a1f5-700dea9f4c0c'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-24 ERP_DOCUMENT
  ('235dfe13-f7db-41f7-9285-433ebcef88d2'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-24 ERP_DOCUMENT
  ('a28eb48f-cb21-4ff1-93bb-90e0077ff26a'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-24 ERP_DOCUMENT
  ('c7ca361d-a3e7-4743-ad31-a666433e4c64'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-24 ERP_DOCUMENT
  ('c972cfe5-32cd-4f60-88a5-8bb1a9468229'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-24 ERP_DOCUMENT
  ('f99e0379-5d29-4924-8e99-90bc73952b08'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-24 ERP_DOCUMENT
  ('24c2a7ed-3dcc-4f1b-99b3-21f2d531eb32'::uuid, null, null, 'OTHER', null, null, null),  -- 2026-09-24 OTHER_SHIPMENTS
  ('2c0f19b2-e6d7-4786-b4c3-e59618757693'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-24 OTHER_SHIPMENTS
  ('793d9b15-71e1-407b-933f-5fd62adf860b'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-24 OTHER_SHIPMENTS
  ('5bfc44be-f495-4d2a-b7fc-cb831c55baaf'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-25 ERP_DOCUMENT
  ('09cd99e1-a4ff-43fa-a733-fb6bd50eac72'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-25 OTHER_SHIPMENTS
  ('5df263b3-e061-4eca-8929-b75a9800ce73'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-25 OTHER_SHIPMENTS
  ('64a115fc-84dc-4221-9393-97df01d8568e'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-25 OTHER_SHIPMENTS
  ('d277accd-451e-46c0-b1a1-496722459792'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-25 OTHER_SHIPMENTS
  ('d3c3328c-d680-4c59-83e4-c1434bd6c975'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-25 OTHER_SHIPMENTS
  ('e48a9f65-34ce-404c-98e5-831b36c7c363'::uuid, null, null, 'DOMESTIC_SHIPMENT', null, null, null),  -- 2026-09-25 OTHER_SHIPMENTS
  ('5aaf731e-fd67-4065-8174-38320712316a'::uuid, null, 'AMBIENT', null, null, null, null),  -- 2026-09-28 ERP_DOCUMENT
  ('9025567d-bd7a-42b5-a067-dc5c84b07965'::uuid, null, null, null, 1, null, null),  -- 2026-10-07 ERP_DOCUMENT
  ('a855dba9-ad4d-4f0b-a2d5-7660d569e115'::uuid, null, null, null, 1, null, null),  -- 2026-10-07 ERP_DOCUMENT
  ('8a4e1cba-f2c6-4e10-8ee6-35eb2b2c63b2'::uuid, null, null, null, 1, null, null),  -- 2026-10-13 ERP_DOCUMENT
  ('af344429-eabd-4b03-8675-98fe2815c311'::uuid, null, null, null, 1, null, null),  -- 2026-10-14 ERP_DOCUMENT
  ('5001a825-3862-4b5f-bba3-38bf0f67dc48'::uuid, null, null, null, 1, null, null),  -- 2026-10-19 ERP_DOCUMENT
  ('647d2f36-b759-4036-8318-4d68a33afee3'::uuid, null, null, null, 1, null, null),  -- 2026-10-21 ERP_DOCUMENT
  ('82f25e76-1f90-4404-9efb-6ff9ba559704'::uuid, null, null, null, 1, null, null),  -- 2026-10-21 ERP_DOCUMENT
  ('8a337e68-6b2a-4941-8e25-9294a0f91134'::uuid, null, null, null, 1, null, null),  -- 2026-10-21 ERP_DOCUMENT
  ('de692b61-5e47-42a5-9bb2-0c6d58a8e47f'::uuid, 'OTHER', null, null, null, null, null),  -- 2026-10-26 ERP_DOCUMENT
  ('01829ed2-54e5-4b1a-93e7-f59592df2cec'::uuid, null, null, null, 1, null, null),  -- 2026-10-28 ERP_DOCUMENT
  ('a0efdc01-16ea-4e72-a530-c5ada116fea5'::uuid, null, null, null, 1, null, null),  -- 2026-10-28 ERP_DOCUMENT
  ('34c64fac-de95-4f0d-a039-3eab7c6ecf9a'::uuid, null, null, null, 1, null, null),  -- 2026-11-03 ERP_DOCUMENT
  ('0f791a8a-a5a9-445c-93da-566624d660ed'::uuid, null, null, null, null, 1, null),  -- 2026-11-11 ERP_DOCUMENT
  ('d3497820-19fc-43c6-9826-f8a34d3d4cbf'::uuid, null, null, null, 1, null, null),  -- 2026-11-11 ERP_DOCUMENT
  ('ed71956a-7ebd-4d54-a2d5-f6d4cec7371b'::uuid, null, null, null, 1, null, null),  -- 2026-11-11 ERP_DOCUMENT
  ('9585fd70-63bf-44cf-853d-ac64c017dce3'::uuid, null, null, null, 1, null, null),  -- 2026-11-12 ERP_DOCUMENT
  ('7677241a-972f-404e-91f4-2f57e5d92e50'::uuid, null, null, null, 1, null, null),  -- 2026-11-18 ERP_DOCUMENT
  ('84d48802-0ce1-4d21-bccc-25dfb22821e6'::uuid, null, null, null, 1, null, null),  -- 2026-11-18 ERP_DOCUMENT
  ('a8831c00-9eac-4ddd-b8f2-b46615210d5b'::uuid, null, null, null, 1, null, null),  -- 2026-11-18 ERP_DOCUMENT
  ('f6ae0975-b8df-4493-b79c-6c5b54797853'::uuid, null, null, null, 1, null, null),  -- 2026-11-18 ERP_DOCUMENT
  ('355bc124-7a04-4374-9314-b8d5f5461c6b'::uuid, null, null, null, 1, null, null),  -- 2026-11-25 ERP_DOCUMENT
  ('76b1abb3-552d-434c-b456-b718e969ffbe'::uuid, null, null, null, 1, null, null),  -- 2026-11-25 ERP_DOCUMENT
  ('c87814d8-7581-49af-98db-5843d598c89d'::uuid, null, null, null, 1, null, null)  -- 2026-11-27 ERP_DOCUMENT
;

-- Garde-fou : 310 lignes, et chaque champ modifié doit être vide (ou 0 pour
-- les quantités) avant la mise à jour, sinon tout est annulé.
do $$
declare n int; bad int;
begin
  select count(*) into n from wu_fix f join public.tasks t on t.id = f.id;
  select count(*) into bad from wu_fix f join public.tasks t on t.id = f.id
  where (f.carrier is not null and t.carrier is not null)
     or (f.temperature_group is not null and t.temperature_group is not null)
     or (f.other_shipment_category is not null and t.other_shipment_category is not null)
     or (f.pallet_count is not null and coalesce(t.pallet_count, 0) <> 0)
     or (f.package_count is not null and coalesce(t.package_count, 0) <> 0)
     or (f.dry_ice_carton_count is not null and coalesce(t.dry_ice_carton_count, 0) <> 0);
  if n <> 310 or bad <> 0 then
    raise exception 'Attendu 310 lignes modifiables, trouvé % (dont % déjà renseignées) - annulation', n, bad;
  end if;
end $$;

update public.tasks t
set carrier                 = coalesce(f.carrier::carrier_type, t.carrier),
    temperature_group       = coalesce(f.temperature_group::temperature_group, t.temperature_group),
    other_shipment_category = coalesce(f.other_shipment_category::other_shipment_category, t.other_shipment_category),
    pallet_count            = coalesce(f.pallet_count, t.pallet_count),
    package_count           = coalesce(f.package_count, t.package_count),
    dry_ice_carton_count    = coalesce(f.dry_ice_carton_count, t.dry_ice_carton_count)
from wu_fix f
where t.id = f.id;

-- Vérification : répartition des changements (le contrôle 0 WU se fait
-- ensuite dans l'appli, la matrice n'étant pas lisible ici simplement).
select 'lignes modifiées' as label, count(*) as value from wu_fix
union all
select 'passées en AMBIENT', count(*) from public.tasks t join wu_fix f on f.id = t.id
  where f.temperature_group = 'AMBIENT' and t.temperature_group = 'AMBIENT'
union all
select 'repassées en DRY_ICE par le trigger', count(*) from public.tasks t join wu_fix f on f.id = t.id
  where f.temperature_group = 'AMBIENT' and t.temperature_group = 'DRY_ICE';

commit;
