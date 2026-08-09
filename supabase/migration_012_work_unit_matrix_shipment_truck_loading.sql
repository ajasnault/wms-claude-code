-- Adds SHIPMENT and TRUCK_LOADING entries to work_unit_matrix.
--
-- migration_004's full re-seed only covered Bâtiment K's task types
-- (ERP_DOCUMENT, OTHER_SHIPMENTS, MAINTENANCE, PREP_DRY_ICE, RE_SUPPLY) —
-- Bâtiment S almost exclusively uses SHIPMENT and TRUCK_LOADING, which had
-- no matching matrix entry, so calculateWorkUnits() always returned 0 for
-- them and the Capacity page showed a flat/zero "Charge" line for S.
--
-- 1 WU per pallet, no carrier/destination/temperature filter (generic
-- match for any Bâtiment S SHIPMENT or TRUCK_LOADING task).

begin;

insert into public.work_unit_matrix (task_type, unit_type, work_unit_value)
values
  ('SHIPMENT', 'PALLET', 1.00),
  ('TRUCK_LOADING', 'PALLET', 1.00);

select task_type, carrier, destination_k, destination_s, unit_type, work_unit_value
from public.work_unit_matrix
where task_type in ('SHIPMENT', 'TRUCK_LOADING');

commit;
