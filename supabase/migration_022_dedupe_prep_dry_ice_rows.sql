-- WMS -- Remove duplicate PREP_DRY_ICE rows (spotted via WMS1000320's
-- double WU on Backoffice: "2 cart / 4.00 WU" for what should be one
-- 1-carton prep).
--
-- Traced to 3 original duplicate data-entry events, each created a few
-- days apart (not a copy-migration artifact at the source):
--   - WMS719271 / 2026-01-20: created 2026-01-15 and 2026-01-21
--   - WMS742435 / 2026-03-10: created 2026-03-02 and 2026-03-06
--   - WMS757266 / 2026-03-24: created 2026-03-20 and 2026-03-23
-- Each pair is identical in every field but id and created_at (same
-- erp_document_number, same due_date, dry_ice_carton_count=1, no notes
-- or other distinguishing data) -- confirmed with the user as duplicate
-- entries, not two real separate preparations.
--
-- The migration_005/010/014 "copy tasks into another month" scripts then
-- faithfully propagated each duplicate pair forward, producing 5 more
-- duplicate pairs: WMS1000320 (2026-08-25), WMS1000168 (2026-09-15),
-- WMS1000264 (2026-07-10), WMS1000319 (2026-07-24), and a second
-- WMS742435 occurrence (2026-08-11). 8 pairs total, 8 rows to delete
-- (keeping the earliest-created row of each pair).

begin;

delete from public.tasks
where type = 'PREP_DRY_ICE'
  and dry_ice_carton_count = 1
  and id in (
    '3135d3bb-a5f3-4df1-8a69-093c5c372b54', -- WMS719271 / 2026-01-20 (dup of ca276f80..., created 2026-01-21)
    '22cf653d-4235-41eb-a557-29626b519310', -- WMS742435 / 2026-03-10 (dup of 9ff0aa44..., created 2026-03-06)
    '82a42367-4fec-4179-a73c-9984adc6995d', -- WMS757266 / 2026-03-24 (dup of a255ad6d..., created 2026-03-23)
    '2f12e50c-4ad1-4b8d-b213-8e7c75d929bb', -- WMS1000264 / 2026-07-10
    '8380ad3d-8e44-4442-aa60-31bc07de6371', -- WMS1000168 / 2026-09-15
    '3babd0d6-be6c-4bab-8aca-30e8c241cb6d', -- WMS1000320 / 2026-08-25
    '7105cc39-d41b-403b-b2db-431b78c24e51', -- WMS1000319 / 2026-07-24
    'd071bf85-f1fc-4fe8-8410-b0d5b55b4231'  -- WMS742435 / 2026-08-11
  );

commit;

-- Verification: should return 0 rows (no more duplicate (number, date)
-- pairs among PREP_DRY_ICE tasks).
select erp_document_number, due_date, count(*)
from public.tasks
where type = 'PREP_DRY_ICE'
group by erp_document_number, due_date
having count(*) > 1;
