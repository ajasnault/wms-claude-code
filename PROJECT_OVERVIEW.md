# WMS — Project Overview & Rebuild Spec

A presentation of the WMS project as it stands, written to be handed to a fresh build process (human or AI) that needs to reconstruct or extend it without re-discovering everything the hard way.

## 1. What this is

An internal warehouse management tool for a pharma/biotech logistics operation, covering two physical warehouses/buildings — **K** and **S** — each with its own task types, dashboard, and workload profile. Destinations include clinical/lab sites (e.g. EUROFINS) and manufacturing sites across Europe; a recurring theme is temperature-controlled shipping, in particular dry-ice-packed shipments.

The tool's two jobs:
- **Operational tracking** — every unit of warehouse work (an outbound shipment, a dry-ice prep, a truck loading, a maintenance slot...) is a row in one `tasks` table, editable from a Backoffice UI and visible on public TV/kiosk dashboards on the warehouse floor.
- **Workload accounting** — every task earns a computed number of **Work Units (WU)**, a synthetic effort measure used to forecast and track capacity against available staffing.

## 2. Tech stack

- **React 19 + TypeScript**, built with **Vite 8**
- **React Router v7** for client-side routing
- **TanStack React Query v5** for server-state/caching, kept live via **Supabase Realtime** (`postgres_changes` subscriptions)
- **Supabase** (Postgres + Auth + Realtime + PostgREST) as the entire backend — there is no custom server; the client talks to Postgres directly through PostgREST and RLS policies
- **Tailwind CSS + Radix UI primitives** (shadcn-style component library) for UI
- **react-hook-form + zod** for forms and validation
- **recharts** for charts (Analytics, Capacity)
- **xlsx** for CSV/Excel export

## 3. Domain model

### Buildings
`K` and `S` — each building has its own subset of `task_type` values and its own dashboard route. K deals with ERP shipments, dry-ice prep, other shipments, re-supply, maintenance; S deals mainly with `SHIPMENT` and `TRUCK_LOADING`.

### task_type
`ERP_DOCUMENT`, `PREP_DRY_ICE`, `OTHER_SHIPMENTS`, `RE_SUPPLY`, `MAINTENANCE`, `PICKING`, `PACKING`, `TRUCK_LOADING`, `SHIPMENT`

The two types with the most business logic:
- **`ERP_DOCUMENT`** — an outbound shipment sourced from the ERP. Carries `carrier`, `destination_k`/`destination_s`, `temperature_group`, and quantity fields (`package_count`, `pallet_count`, `bottle_count`).
- **`PREP_DRY_ICE`** — the dry-ice packing step for a shipment. Linked to its `ERP_DOCUMENT` sibling by sharing the same `erp_document_number` (and, in practice, being due **one day earlier**). Tracks `dry_ice_carton_count`.

### temperature_group
`AMBIENT`, `DRY_ICE`, `MONITORED` — classifies an `ERP_DOCUMENT` shipment's temperature handling. This is the single field that determines which `work_unit_matrix` rate applies, so its correctness is load-bearing (see §7.3).

### Status lifecycle
`NEW → IN_PROGRESS → DONE / LATE / STANDBY / OUT` (`OUT` = shipped/closed).

### Carriers & destinations
`carrier_type`: DHL, KUEHNE_NAGEL, WORLD_COURIER, ESSERS, DUPERREX, TNT_FEDEX, OTHER
`destination_k`: GUIDONIA_IT, COLERETTO_IT, MODUGNO_IT, EUROFINS, ANGERS_FR, MALAGA_ES, WAVRE_BE, OTHER
`destination_s`: GLG, SANTA_PALOMBA, TURKEY, SWITZERLAND, USA, CHINA, KOREA, GUIDONIA, PHARMALOG_KGAA, OTHER

## 4. Database schema (Supabase/Postgres)

### Tables
- **`tasks`** — the central table; every task type across both buildings lives here. ~40 columns covering identity (building, type, status, priority), the ERP link (`erp_document_number`), shipping details (carrier, destination, temperature_group, transport_mode), quantities (bottle/pallet/package/dry-ice-carton counts), and operational flags (k2_reference, k2_closed, pgi_done, cmr_status, sub_statuses).
- **`work_unit_matrix`** — the WU pricing table. Each row: `task_type` + optional `carrier`/`destination_k`/`destination_s`/`temperature_group`/`other_shipment_category` filters, plus `unit_type` (BOTTLE/PALLET/PACKAGE/CARTON/FIXED) and `work_unit_value`.
- **`collaborators`, `collaborator_availability`, `capacity_forecasts`** — staffing and capacity-planning inputs for the Capacity page.
- **`profiles`, `user_roles`** — auth identity and RBAC (`admin` vs `operator`, via a `has_role()` SECURITY DEFINER function to avoid RLS recursion).

### Row-Level Security
- `tasks`: `SELECT` is open to everyone, unauthenticated — the dashboards are public TV/kiosk screens with no login. `INSERT`/`UPDATE` require an authenticated session (any role). `DELETE` requires `admin`.
- `work_unit_matrix` and the capacity tables: `SELECT` requires authentication; writes require `admin`.

### Realtime
`tasks` is registered on the `supabase_realtime` publication — the Backoffice and dashboards subscribe to `postgres_changes` and patch their local React Query cache live.

## 5. The Work Unit (WU) system — core business logic

Every task earns a WU value via `calculateWorkUnits()` (`src/lib/workUnitCalculator.ts`), evaluated against `work_unit_matrix`:

1. Filter matrix rows matching the task's `task_type`, and — for each matrix row that specifies them — `carrier`, `destination` (k or s, matching the task's building), `temperature_group`, `other_shipment_category`. A `null` filter column on a matrix row means "matches anything."
2. Among the matches, keep only the **most specific** ones (most non-null filter columns set).
3. Multiply the winning row's `work_unit_value` by the task's quantity for that row's `unit_type`:
   `BOTTLE→bottle_count, PALLET→pallet_count, PACKAGE→package_count, CARTON→dry_ice_carton_count, FIXED→1`.

**The known design flaw**: when two matrix rows tie in specificity for the same task (e.g. both a `PACKAGE` and a `PALLET` row exist for the same carrier+destination+temperature_group), step 2 doesn't produce a single winner. The current tie-break falls back to "whichever `unit_type` the task actually has non-zero data for" — but real shipments routinely have **both** `package_count` and `pallet_count` populated (a shipment is both "N packages" and "on M pallets"), so the tie becomes a coin flip on undefined Postgres row order. See §7.1 for the incident this caused and the fix.

**Rule for a rebuild**: the matrix should never allow two rows to tie in specificity for the same `(task_type, carrier, destination, temperature_group, other_shipment_category)` combination. Enforce it with a database constraint, not application logic.

## 6. Pages / routes

| Route | Access | Purpose |
|---|---|---|
| `/backoffice` | authenticated | Main operational view: create/edit/delete tasks, filter by building/status/search/date range, "Orphan Dry Ice" filter (a `PREP_DRY_ICE` with no matched `ERP_DOCUMENT`), CSV export, per-task WU badge. |
| `/dashboard/k`, `/dashboard/s` | **public** (no login — TV/kiosk) | Today's/upcoming tasks grouped by destination or carrier, inline status changes, late-task highlighting. |
| `/analytics` | authenticated | Historical task volume and status charts over a selectable period (7/14/30/60/90 days). |
| `/capacity` | authenticated | Staffing capacity vs. forecasted WU load over the next 10 working days per building, with collaborator availability inputs. |
| `/customer-service` | authenticated | Look up a shipment by ERP document number for status inquiries. |
| `/admin/work-units` | authenticated, **admin only** | CRUD UI for the `work_unit_matrix` pricing table. |

## 7. Hard-won lessons from operating this project (read before rebuilding)

The current dataset and some of the schema carry scars from an evolving demo/seed setup layered with real-world-shaped data. A rebuild should actively avoid re-introducing these:

### 7.1 — Never let `calculateWorkUnits()` need a tie-break
Discovered via a support ticket where a dry-ice shipment showed 0.02 WU instead of 4.00: the matrix had both a `PACKAGE=2.00` and a `PALLET=0.01` row for the same carrier+destination+temperature_group, and undefined row order picked the wrong one. The same ambiguity existed for `AMBIENT` shipments too (77% and 100%+ of tasks respectively had both counts populated). Fixed by removing the redundant/placeholder rows so each combo has exactly one candidate — but the real fix for a rebuild is a **uniqueness constraint** on the matrix that makes ties impossible to create in the first place.

### 7.2 — `erp_document_number` must be unique per real shipment event
It was reused across unrelated shipments (296 of 530 distinct numbers, 75% of task rows) because "copy tasks into another month" demo-data seed scripts copied the source row's `erp_document_number` verbatim instead of minting a fresh one per copy. This broke every consumer that joins on it: a `temperature_group`-sync trigger, the `PREP_DRY_ICE`↔`ERP_DOCUMENT` linking logic (`taskGrouping.ts`'s `linkPrepDryIce()`, which had to work around it with a "closest due date" heuristic), and search. **If seed/demo data needs duplicating across time periods, mint a fresh business key per copy** — never reuse one that's meant to be unique.

### 7.3 — `temperature_group` needs a real source of truth
It's a free, optional dropdown in the UI with no default and no ongoing sync mechanism. A legacy `temperature_conditions` jsonb field also encodes the same fact for older rows, but nothing keeps the two in sync — and one-off backfill migrations only ever fixed data as of the moment they ran, not going forward, so the same class of bug (ticket "WMS749370", then "WMS711977") recurred. **If rebuilt: derive it automatically** (e.g. from a linked `PREP_DRY_ICE` task at write time) instead of leaving it to manual, optional entry.

### 7.4 — Every field the WU calculator reads needs a form input
`package_count` drives WU for `ERP_DOCUMENT` tasks but had **no input at all** in `TaskFormDialog.tsx` for building K — only `bottle_count` and `dry_ice_carton_count` were exposed, which don't feed the shipment's own WU. Shipments could sit at 0 WU indefinitely with no way to fix it from the UI.

### 7.5 — Postgres trigger gotchas (statement-level, `REFERENCING NEW TABLE`)
- Can't combine `REFERENCING NEW TABLE` with multiple trigger events (`insert or update`) in one trigger — split into separate triggers per event.
- Can't combine it with a column list (`UPDATE OF col1, col2`) either — fire on every update and filter inside the function instead.
- If the trigger function itself issues an `UPDATE` on the same table, it **re-fires the same statement-level trigger**, regardless of how many rows the inner update actually changed (statement-level triggers fire per statement execution, not per row affected). Without a guard this recurses until `stack depth limit exceeded`, silently rolling back the *entire* triggering transaction — including whatever the user was trying to save. Guard with `if pg_trigger_depth() > 1 then return null; end if;` at the top of the function.

### 7.6 — `NOT (x @> y)` and friends are a NULL trap
`NOT (nullable_column @> some_jsonb)` evaluates to `NULL` — not `TRUE` — whenever `nullable_column` is `NULL`, so the row is silently excluded from the `WHERE` clause with **no error at all**. A migration built this way reported success while updating zero rows. Use `coalesce(x @> y, false) = false` or `IS DISTINCT FROM` for any negated comparison on a nullable column.

### 7.7 — Undefined row order is a real bug surface
`useWorkUnitMatrix.tsx` fetches with only `.order("task_type")` — no secondary sort — so the order of rows within a `task_type` (and therefore which one wins a tie in `calculateWorkUnits()`) is whatever Postgres happens to return, which is not guaranteed stable. Any code that relies on array order for a *correctness-relevant* decision (not just display order) is fragile by construction, even when it happens to "work" today.

### 7.8 — Data-quality issues compound silently
Duplicate rows (two identical `PREP_DRY_ICE` tasks for one prep event, propagated by copy-migrations into 8 duplicate pairs across the dataset), reused business keys, and matrix mispricing all produced *plausible-looking but wrong* numbers with no error message anywhere — every one of them was found by manually cross-checking one support ticket against live data, not by any automated check. **Build in periodic consistency checks** (e.g. a scheduled query for duplicate `(erp_document_number, due_date)` pairs, or matrix rows tied in specificity) rather than relying on someone noticing a wrong number on a dashboard.

## 8. Current live state (as of 2026-09-08)

Migrations `002` through `022` have been run against the live Supabase project (`supabase/migration_0XX_*.sql`, in order). Concretely, this means the following now exist in production that a rebuild — or anyone continuing to build on this same Supabase project — should know about:

**Functions & triggers currently live on `public.tasks`:**
- `handle_new_user()` — `AFTER INSERT on auth.users`, seeds `profiles`/`user_roles`.
- `update_updated_at()` — `BEFORE UPDATE on tasks`, stamps `updated_at`.
- `sync_dry_ice_temperature_group()` — two triggers, `tasks_sync_dry_ice_temperature_group_ins` (`AFTER INSERT`) and `tasks_sync_dry_ice_temperature_group_upd` (`AFTER UPDATE`, fires on every update, no column filter — see §7.5 for why), both using `REFERENCING NEW TABLE` and guarded by `pg_trigger_depth() > 1`. Keeps `temperature_group = 'DRY_ICE'` in sync whenever an `ERP_DOCUMENT` and a `PREP_DRY_ICE` share an `erp_document_number`.
- `generate_erp_document_number()` + `erp_document_number_seq` (currently past `1000345`) — mints numbers like `WMS1000345` for any future "copy tasks" seed script. **Any new copy-migration must use this instead of copying the source row's number verbatim.**

**`work_unit_matrix` shape:**
- `ERP_DOCUMENT`/`DRY_ICE` combos now have **only** a `PACKAGE` rate — no more competing `PALLET` rows.
- `ERP_DOCUMENT`/`AMBIENT`: ESSERS, KUEHNE_NAGEL, DUPERREX, WORLD_COURIER, TNT_FEDEX now have a single unambiguous rate per combo; DHL bills by `PACKAGE` (its `PALLET=1.00` row was removed per an explicit business-rule decision, not a placeholder-value heuristic). The `OTHER` carrier and the ESSERS/KUEHNE_NAGEL `EUROFINS`-destination rows still have two rows tied at equal value (0.50/0.50 and 0.01/0.01) — left alone deliberately, since neither answer is wrong there.

**`tasks.erp_document_number`:** a mix of legacy `WMS######` (6-digit) values and 345 freshly-minted `WMS1000000`–`WMS1000344` (7-digit) values from the dedup migration — the digit-count difference is intentional, so the two eras are visually distinguishable in the UI.

**What was NOT checked or touched this session** (real gaps, not lessons — worth auditing before relying on them):
- **`MONITORED` temperature_group**: never audited for the same `PACKAGE`/`PALLET` tie-break risk described in §7.1/§7.7. No current task happens to hit a tie there, but that was also true of `TNT_FEDEX`/`AMBIENT` before it was checked — absence of a current incident isn't evidence the matrix is safe.
- **Building S** (`SHIPMENT`, `TRUCK_LOADING`): matrix entries are `PALLET`-only (added by `migration_012`) so no tie-break risk today, but the broader data-quality classes in §7.2/§7.8 (`erp_document_number` reuse, duplicate rows) were only audited for building K.
- **The `WMS1000320`-style duplicate-`PREP_DRY_ICE` cleanup (§7.8) only covered `PREP_DRY_ICE`** — other task types weren't checked for the same exact-duplicate-row pattern.

## 9. Suggested schema/architecture improvements for a rebuild

- Add a `UNIQUE` (or partial unique) index on `work_unit_matrix (task_type, carrier, destination_k, destination_s, temperature_group, other_shipment_category, unit_type)` scoped so it's impossible to insert two rows with identical filter columns but different `unit_type` — the actual invariant that must hold is "at most one applicable rate per combo," which today's schema doesn't enforce at all.
- Give `temperature_group` a real derivation path (trigger or write-time logic from a linked `PREP_DRY_ICE`) instead of manual/optional entry.
- Consider a proper `shipments` table that `tasks` reference via foreign key, instead of a loose `erp_document_number` text field duplicated and matched across rows — this removes the entire class of reuse/collision bugs in §7.2.
- Add the missing `package_count` input to `TaskFormDialog.tsx` for every task type/building combination the WU calculator actually reads it for, and audit the rest of the form for the same gap.
- Consider a lightweight scheduled integrity-check (SQL query or edge function) that flags: duplicate `(erp_document_number, due_date)` pairs, matrix rows tied in specificity, and `ERP_DOCUMENT` tasks with `temperature_group IS NULL` that have a linked `PREP_DRY_ICE` — surfacing these proactively rather than waiting for a support ticket.
