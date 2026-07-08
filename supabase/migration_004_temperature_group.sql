-- WMS — Temperature group + full work_unit_matrix import
-- Run in Supabase SQL Editor after migration_003_extended_task_fields.sql

-- 1. New enum ---------------------------------------------------------------

create type temperature_group as enum ('AMBIENT', 'DRY_ICE', 'MONITORED');

-- 2. Extend other_shipment_category with value present in production CSV ----

alter type other_shipment_category add value if not exists 'GUITTERS_ERBITUX_DP';

-- 3. Add temperature_group to tasks -----------------------------------------

alter table public.tasks
  add column if not exists temperature_group temperature_group;

-- 4. Extend work_unit_matrix ------------------------------------------------

alter table public.work_unit_matrix
  add column if not exists temperature_group temperature_group,
  add column if not exists other_shipment_category other_shipment_category;

-- 5. Auto-infer temperature_group for PREP_DRY_ICE tasks -------------------

update public.tasks
  set temperature_group = 'DRY_ICE'
  where type = 'PREP_DRY_ICE' and temperature_group is null;

-- 6. Replace placeholder matrix with production data -----------------------

truncate public.work_unit_matrix;

insert into public.work_unit_matrix
  (id, task_type, other_shipment_category, carrier, destination_k, temperature_group, unit_type, work_unit_value)
values
  ('dc3a59ec-4b79-4192-a077-4226e3365785','ERP_DOCUMENT'::task_type,NULL,'DHL'::carrier_type,NULL,'AMBIENT'::temperature_group,'PALLET',1.00),
  ('cba9ee0f-7160-4d4a-8afe-a5d71be694c1','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'OTHER'::destination_k,'AMBIENT'::temperature_group,'PALLET',1.00),
  ('0f9ffa24-ce28-45e8-b101-b6fa05b376ca','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'OTHER'::destination_k,'AMBIENT'::temperature_group,'PALLET',1.00),
  ('c014ea2d-f858-48e6-af92-b339d0d7f95c','ERP_DOCUMENT'::task_type,NULL,'DHL'::carrier_type,NULL,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('eb4ac430-2171-4653-8baf-1785ad93b39e','ERP_DOCUMENT'::task_type,NULL,'DHL'::carrier_type,NULL,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('b4b80da0-97a5-4cb1-aa70-01d86da040bc','ERP_DOCUMENT'::task_type,NULL,'DHL'::carrier_type,NULL,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('c20cf876-04ce-43f6-ace5-0ee76a14d948','ERP_DOCUMENT'::task_type,NULL,'DHL'::carrier_type,NULL,'MONITORED'::temperature_group,'PALLET',0.01),
  ('aa76ac8a-b4d3-48a0-a7e3-fc3662ceb89e','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'EUROFINS'::destination_k,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('d52fc52f-960f-421b-b855-70643b33f6d7','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'EUROFINS'::destination_k,'AMBIENT'::temperature_group,'PALLET',0.01),
  ('49a50da7-7896-4cf5-8201-ee1873f2b84b','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'WAVRE_BE'::destination_k,'AMBIENT'::temperature_group,'PALLET',1.00),
  ('2bd583cb-3b6c-4a1f-9e62-899c638047d8','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'OTHER'::destination_k,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('4f9f4d81-8bff-4227-b854-e0d0d8908725','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'EUROFINS'::destination_k,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('ab665108-d6bb-42f9-a76f-07a8a0e385f3','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'WAVRE_BE'::destination_k,'AMBIENT'::temperature_group,'PALLET',1.00),
  ('665fc086-4840-4bac-8362-db6781f7fba4','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'OTHER'::destination_k,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('cff05617-e1e9-4b89-8230-408a1255d14b','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'EUROFINS'::destination_k,'MONITORED'::temperature_group,'PALLET',0.01),
  ('fc42d2b1-9caa-497e-87ef-0e05f82cfc68','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'WAVRE_BE'::destination_k,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('e8a2a78f-6711-4f08-882b-3c43ccbf37ae','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'OTHER'::destination_k,'MONITORED'::temperature_group,'PALLET',2.00),
  ('a1d15c86-2844-4def-ac19-19a885cac1a6','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'EUROFINS'::destination_k,'DRY_ICE'::temperature_group,'PACKAGE',0.01),
  ('a3eb8a08-ed6f-4938-8b94-c60bb3d5e37e','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'EUROFINS'::destination_k,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('ea523c1b-5175-4131-b8f0-ce878fe20199','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'EUROFINS'::destination_k,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('6f9d5ff2-9484-4504-a77e-327f4aceb4ec','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'EUROFINS'::destination_k,'AMBIENT'::temperature_group,'PALLET',0.01),
  ('77bd762b-5ce7-42f0-9329-104edde3da1d','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'EUROFINS'::destination_k,'DRY_ICE'::temperature_group,'PACKAGE',0.01),
  ('46ef6ac4-c9d2-49fd-88ba-1bac31405332','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'EUROFINS'::destination_k,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('fd6caa46-ebc6-4046-9206-7c83470e6d21','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'EUROFINS'::destination_k,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('a68cb899-70fb-4435-b4aa-e94f268a8501','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'EUROFINS'::destination_k,'MONITORED'::temperature_group,'PALLET',0.01),
  ('30fc68a6-b5a7-47f1-983c-1d5293fb5137','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'OTHER'::destination_k,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('ed7c1bb2-f255-4eba-aac1-2a29109983eb','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'WAVRE_BE'::destination_k,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('c1183b74-a03e-4fc3-ba33-477ea236510c','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'WAVRE_BE'::destination_k,'MONITORED'::temperature_group,'PALLET',2.00),
  ('b2139a23-9203-4ab4-acf3-022df73e469a','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'WAVRE_BE'::destination_k,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('b9b0e63d-5d31-4f19-800b-9c44ca89fb17','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'WAVRE_BE'::destination_k,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('f8b80838-cf0d-430d-a94a-ec35c25116c3','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'WAVRE_BE'::destination_k,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('220239a3-212b-4723-914c-64aff85c5a14','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'WAVRE_BE'::destination_k,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('de892247-17b5-4c73-9416-f957089b5ef3','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'WAVRE_BE'::destination_k,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('8446d317-a666-47d1-b1bf-bc11ab9be5d3','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'OTHER'::destination_k,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('1626ed51-d13a-46be-b03b-d013bfdc8a2c','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'OTHER'::destination_k,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('8a249496-0290-4b59-9209-308637a70b95','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'OTHER'::destination_k,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('c819ec11-f069-48bd-bcb1-0925d9ac4c18','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'OTHER'::destination_k,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('327649af-1a66-4518-9a92-42aa1e18c640','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'OTHER'::destination_k,'MONITORED'::temperature_group,'PALLET',2.00),
  ('ec6c9051-a52b-4b14-b87c-98031d058832','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'ANGERS_FR'::destination_k,'AMBIENT'::temperature_group,'PALLET',1.00),
  ('53c2ed5c-4f9e-436d-a4d1-5c1a1e6b9bcd','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'WAVRE_BE'::destination_k,'MONITORED'::temperature_group,'PALLET',2.00),
  ('44b7f699-fe22-4f38-9241-0f35a3e178b6','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'MALAGA_ES'::destination_k,'AMBIENT'::temperature_group,'PALLET',1.00),
  ('955d51a0-80ca-431f-bcc1-8ed86cd50ebd','ERP_DOCUMENT'::task_type,NULL,'WORLD_COURIER'::carrier_type,NULL,'AMBIENT'::temperature_group,'PALLET',1.00),
  ('c6154ac1-7bba-40ef-ad0a-a541358f8838','OTHER_SHIPMENTS'::task_type,'MARTI'::other_shipment_category,NULL,NULL,NULL,'FIXED',1.00),
  ('581eba8f-dfc4-4079-9ae4-d6d7826e4a37','OTHER_SHIPMENTS'::task_type,'CHEMICALS'::other_shipment_category,NULL,NULL,NULL,'FIXED',1.00),
  ('a4725e93-58e7-4e49-ba07-7e243fda8d61','OTHER_SHIPMENTS'::task_type,'HARVEST_BAG'::other_shipment_category,NULL,NULL,NULL,'FIXED',1.00),
  ('2a2643f4-3702-4478-8a5a-c29f5b0fce51','OTHER_SHIPMENTS'::task_type,'NAVETTE_AUBONNE_VEVEY'::other_shipment_category,NULL,NULL,NULL,'FIXED',1.00),
  ('aa76ec91-cc23-4cca-aa3c-bb0e54676635','OTHER_SHIPMENTS'::task_type,'OTHER'::other_shipment_category,NULL,NULL,NULL,'FIXED',1.00),
  ('93ec6905-f568-4eda-b6dc-128e29743fa0','RE_SUPPLY'::task_type,NULL,NULL,NULL,NULL,'FIXED',1.00),
  ('4f941339-4f5c-47b3-a36a-d9176c9adc12','MAINTENANCE'::task_type,NULL,NULL,NULL,NULL,'FIXED',1.00),
  ('a5e92c5b-6ca9-4f2a-be26-fc5838e0e0db','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'WAVRE_BE'::destination_k,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('6423de98-ebc9-4b90-b5e5-625e5cff020c','ERP_DOCUMENT'::task_type,NULL,'DUPERREX'::carrier_type,NULL,'AMBIENT'::temperature_group,'PALLET',2.00),
  ('8fd39a02-282c-4ea1-8d1f-ef343873e10c','ERP_DOCUMENT'::task_type,NULL,'TNT_FEDEX'::carrier_type,NULL,'AMBIENT'::temperature_group,'PACKAGE',2.00),
  ('b86b0d06-2e3d-4bb7-bfe8-91fde64a86da','ERP_DOCUMENT'::task_type,NULL,'DHL'::carrier_type,NULL,'AMBIENT'::temperature_group,'PACKAGE',0.25),
  ('01d34f51-e99a-41bd-8647-93e98b7a4aed','ERP_DOCUMENT'::task_type,NULL,'TNT_FEDEX'::carrier_type,NULL,'AMBIENT'::temperature_group,'PALLET',0.01),
  ('b5e215a0-eeb4-451b-9881-94839b43fbc8','PREP_DRY_ICE'::task_type,NULL,NULL,NULL,NULL,'CARTON',2.00),
  ('c23fce88-e9d7-4aad-b91a-85f5297e2747','ERP_DOCUMENT'::task_type,NULL,'TNT_FEDEX'::carrier_type,NULL,'DRY_ICE'::temperature_group,'PACKAGE',0.01),
  ('58ce0576-881b-4d9a-bca7-4e11431fff40','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'MALAGA_ES'::destination_k,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('850f59d2-5ff4-43f1-97c8-20c1b8aed9b4','ERP_DOCUMENT'::task_type,NULL,'DUPERREX'::carrier_type,NULL,'MONITORED'::temperature_group,'PALLET',2.00),
  ('a1ff1ed2-8818-43fb-9c7b-21a3bc6a6ddb','ERP_DOCUMENT'::task_type,NULL,'DUPERREX'::carrier_type,NULL,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('70fa8796-8352-49df-b0fd-3b388a282149','ERP_DOCUMENT'::task_type,NULL,'TNT_FEDEX'::carrier_type,NULL,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('1d2db458-93df-4ab1-86a5-231e69cbb870','ERP_DOCUMENT'::task_type,NULL,'DUPERREX'::carrier_type,NULL,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('7cabfc12-6b12-4f0b-9757-10aa76b2e51f','OTHER_SHIPMENTS'::task_type,'GUITTERS_ERBITUX_DP'::other_shipment_category,NULL,NULL,NULL,'FIXED',2.00),
  ('cd8be0c6-3884-4f45-8e4a-804ddde25329','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'OTHER'::destination_k,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('b4fbe6df-40cf-4b1a-8be9-32dfe82a7130','ERP_DOCUMENT'::task_type,NULL,'WORLD_COURIER'::carrier_type,NULL,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('dd0d2fd6-341f-4e3c-b2e4-1fef00743635','ERP_DOCUMENT'::task_type,NULL,'TNT_FEDEX'::carrier_type,NULL,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('2ae2514a-1d37-408b-9abc-32eb608a15bc','ERP_DOCUMENT'::task_type,NULL,'TNT_FEDEX'::carrier_type,NULL,'MONITORED'::temperature_group,'PALLET',0.01),
  ('e3d4d014-96f2-438f-bbfd-bc2fcfb30771','ERP_DOCUMENT'::task_type,NULL,'WORLD_COURIER'::carrier_type,NULL,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('23e5de11-b948-445f-9456-fa33afd3b838','ERP_DOCUMENT'::task_type,NULL,'WORLD_COURIER'::carrier_type,NULL,'MONITORED'::temperature_group,'PACKAGE',4.00),
  ('b6d3e878-46a5-468e-9754-46e0b3a91fbd','ERP_DOCUMENT'::task_type,NULL,'WORLD_COURIER'::carrier_type,NULL,'MONITORED'::temperature_group,'PALLET',4.00),
  ('0011bfa3-ba1d-4dc5-95a3-1b69116a415b','ERP_DOCUMENT'::task_type,NULL,'WORLD_COURIER'::carrier_type,NULL,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('cc33ff1c-89be-424a-9777-c9fa47d55940','ERP_DOCUMENT'::task_type,NULL,'DUPERREX'::carrier_type,NULL,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('b94e6a2a-5cda-42a3-8d91-cf59542a7937','ERP_DOCUMENT'::task_type,NULL,'DUPERREX'::carrier_type,NULL,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('0c748026-c275-4ed1-a370-831c65bd7f86','ERP_DOCUMENT'::task_type,NULL,'OTHER'::carrier_type,NULL,'DRY_ICE'::temperature_group,'PACKAGE',0.01),
  ('02560a8c-b997-48c4-90c7-f7b8f2258ce9','ERP_DOCUMENT'::task_type,NULL,'OTHER'::carrier_type,NULL,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('20fc2245-abeb-44ce-9dab-ee7e98e0f299','ERP_DOCUMENT'::task_type,NULL,'OTHER'::carrier_type,NULL,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('79a132ca-cf38-4b0c-b32d-fb465326ada8','ERP_DOCUMENT'::task_type,NULL,'OTHER'::carrier_type,NULL,'MONITORED'::temperature_group,'PALLET',2.00),
  ('ea7f132b-99f0-4bfb-95f7-7b183a706a45','OTHER_SHIPMENTS'::task_type,'DOMESTIC_SHIPMENT'::other_shipment_category,NULL,NULL,NULL,'FIXED',2.00),
  ('813a1da2-55e0-4979-8f23-bf8d18f2f493','ERP_DOCUMENT'::task_type,NULL,'OTHER'::carrier_type,NULL,'AMBIENT'::temperature_group,'PALLET',0.50),
  ('6a1cb663-b877-4633-9875-6870409553ad','ERP_DOCUMENT'::task_type,NULL,'OTHER'::carrier_type,NULL,'AMBIENT'::temperature_group,'PACKAGE',0.50),
  ('e18025dc-8da8-4d21-998f-fc8593ca5cec','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'ANGERS_FR'::destination_k,'AMBIENT'::temperature_group,'PALLET',1.00),
  ('4a6173ba-7608-4f14-bc49-f5d107e9d4af','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'ANGERS_FR'::destination_k,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('5dba80d3-076f-4fbb-8520-642e9d7df405','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'ANGERS_FR'::destination_k,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('55dae443-f8c6-4b26-a826-94d03bb98b09','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'ANGERS_FR'::destination_k,'MONITORED'::temperature_group,'PALLET',2.00),
  ('d00b777c-955c-4b9e-8a54-b875b890e886','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'ANGERS_FR'::destination_k,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('26191593-5fcd-4754-b0c3-1ad9f4cbe2ea','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'ANGERS_FR'::destination_k,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('9f7c6504-2cbc-4d06-9258-701a4a3826c5','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'ANGERS_FR'::destination_k,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('2437ecb7-1488-4ad9-9612-5252d6e279e2','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'ANGERS_FR'::destination_k,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('644efb59-3103-492a-a5de-2845a112cfc8','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'ANGERS_FR'::destination_k,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('75d920d6-31e7-4e5c-9641-b15dea53b2cd','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'ANGERS_FR'::destination_k,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('e2de917b-a175-48ac-9618-54c64535640f','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'ANGERS_FR'::destination_k,'MONITORED'::temperature_group,'PALLET',2.00),
  ('cc396d3f-e59e-4512-9d74-9c4d5454b6d2','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'MALAGA_ES'::destination_k,'AMBIENT'::temperature_group,'PALLET',1.00),
  ('6f5325c3-7b37-47f4-bc64-f95f1ef8446d','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'MALAGA_ES'::destination_k,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('9b633d1f-5789-44bf-bbf4-57943bee29ba','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'MALAGA_ES'::destination_k,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('dfc5c76f-0b22-49e7-bff4-538a9dc13e24','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'MALAGA_ES'::destination_k,'MONITORED'::temperature_group,'PALLET',2.00),
  ('30dc8da1-cacf-44d4-8445-9d0663b1f49b','ERP_DOCUMENT'::task_type,NULL,'ESSERS'::carrier_type,'MALAGA_ES'::destination_k,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('d6b8a85e-f5aa-42ac-b1c4-e65a2356911a','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'MALAGA_ES'::destination_k,'AMBIENT'::temperature_group,'PACKAGE',0.01),
  ('d922c228-3998-4573-bf37-fce56a313370','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'MALAGA_ES'::destination_k,'DRY_ICE'::temperature_group,'PACKAGE',2.00),
  ('67039047-5973-4f65-bb67-70e7e92960c3','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'MALAGA_ES'::destination_k,'DRY_ICE'::temperature_group,'PALLET',0.01),
  ('700e1a0d-a59d-4e74-bc65-e92266688dab','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'MALAGA_ES'::destination_k,'MONITORED'::temperature_group,'PACKAGE',0.01),
  ('89ca0042-8bf2-452a-a96d-8627827c0cc1','ERP_DOCUMENT'::task_type,NULL,'KUEHNE_NAGEL'::carrier_type,'MALAGA_ES'::destination_k,'MONITORED'::temperature_group,'PALLET',2.00);
