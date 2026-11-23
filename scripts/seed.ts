// Generates the WMS demo dataset: 12 months of history plus the next two
// weeks, for both buildings. Every name and number is invented; the output
// only depends on SEED and on the anchor date ("today"), so two runs with
// the same anchor produce exactly the same rows.
//
// Usage (Node >= 23, which runs TypeScript directly):
//   DATABASE_URL=postgres://… node scripts/seed.ts            # replace demo data
//   DATABASE_URL=postgres://… node scripts/seed.ts --schema   # rebuild schema first
//   node scripts/seed.ts --dry-run                            # print stats only
//
// Options (environment variables):
//   SEED_ANCHOR=2026-11-23    anchor date, defaults to today
//   ADMIN_EMAIL=you@…         existing account to grant the admin role

import fs from "node:fs"
import path from "node:path"
import pg from "pg"
import { RECIPIENTS, type Recipient } from "../src/data/recipients.ts"

const SEED = 20260101
const HISTORY_MONTHS = 12
const FUTURE_WORKING_DAYS = 10
const FIRST_ERP_NUMBER = 2000001
const FIRST_RDR26_REFERENCE = 40001

// ---------------------------------------------------------------------------
// Deterministic randomness
// ---------------------------------------------------------------------------
function mulberry32(seed: number) {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
const rand = mulberry32(SEED)
const int = (min: number, max: number) => min + Math.floor(rand() * (max - min + 1))
const chance = (p: number) => rand() < p
const pick = <T,>(items: readonly T[]): T => items[Math.floor(rand() * items.length)]
function weighted<T>(pairs: readonly (readonly [T, number])[]): T {
  const total = pairs.reduce((sum, [, w]) => sum + w, 0)
  let r = rand() * total
  for (const [value, w] of pairs) {
    r -= w
    if (r < 0) return value
  }
  return pairs[pairs.length - 1][0]
}
/** Small Poisson-like count around `mean`. */
function count(mean: number): number {
  let n = 0
  const steps = 20
  for (let i = 0; i < steps; i++) if (rand() < mean / steps) n++
  return n
}

// Stable UUIDs derived from the PRNG so reruns reuse the same ids
function uuid(): string {
  const hex = Array.from({ length: 32 }, () => Math.floor(rand() * 16).toString(16))
  hex[12] = "4"
  hex[16] = ((parseInt(hex[16], 16) & 0x3) | 0x8).toString(16)
  const h = hex.join("")
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`
}

// ---------------------------------------------------------------------------
// Dates
// ---------------------------------------------------------------------------
const iso = (d: Date) => d.toISOString().slice(0, 10)
function parseDay(s: string): Date {
  const [y, m, d] = s.split("-").map(Number)
  return new Date(Date.UTC(y, m - 1, d))
}
function addDays(d: Date, n: number): Date {
  const out = new Date(d)
  out.setUTCDate(out.getUTCDate() + n)
  return out
}
const CLOSED_DAYS = new Set(["12-25", "12-26", "01-01", "01-02"])
function isWorkingDay(d: Date): boolean {
  const dow = d.getUTCDay()
  return dow !== 0 && dow !== 6 && !CLOSED_DAYS.has(iso(d).slice(5))
}

const anchorArg = process.env.SEED_ANCHOR ?? iso(new Date())
const ANCHOR = parseDay(anchorArg)
const TODAY = iso(ANCHOR)
const start = new Date(ANCHOR)
start.setUTCMonth(start.getUTCMonth() - HISTORY_MONTHS)

const days: string[] = []
for (let d = start; ; d = addDays(d, 1)) {
  if (isWorkingDay(d)) days.push(iso(d))
  if (iso(d) >= TODAY && days.filter((x) => x > TODAY).length >= FUTURE_WORKING_DAYS) break
}
const futureDays = days.filter((d) => d >= TODAY)

// Lower activity in August and around the end of the year
const MONTH_FACTOR = [0.85, 1, 1.05, 1, 1, 1.05, 0.9, 0.7, 1.05, 1.1, 1.1, 0.85]
const WEEKDAY_FACTOR = [0, 1.15, 1.05, 1, 1, 0.8, 0]
const dayFactor = (day: string) => {
  const d = parseDay(day)
  return MONTH_FACTOR[d.getUTCMonth()] * WEEKDAY_FACTOR[d.getUTCDay()]
}

// ---------------------------------------------------------------------------
// Reference data
// ---------------------------------------------------------------------------
type Building = "PJ01" | "FG01"
type Carrier = "DHL" | "FEDEX" | "UPS" | "LEMAN_EXPRESS" | "CERVIN_CARGO" | "AZUR_FRET"
type Status = "NEW" | "IN_PROGRESS" | "DONE" | "LATE" | "STANDBY" | "OUT"

const PJ01_RECIPIENTS = RECIPIENTS.filter((r) => r.building === "PJ01")
const FG01_RECIPIENTS = RECIPIENTS.filter((r) => r.building === "FG01")
const recipientWeights = (list: Recipient[]) =>
  list.map((r) => [r, r.accent ? 4 : 1 + (r.code.charCodeAt(0) % 3)] as const)

const ROAD_CARRIERS: Carrier[] = ["LEMAN_EXPRESS", "CERVIN_CARGO", "AZUR_FRET"]

function carrierFor(r: Recipient): Carrier {
  if (r.country === "CH") return weighted([["LEMAN_EXPRESS", 5], ["CERVIN_CARGO", 2], ["DHL", 3]])
  if (["FR", "IT", "ES", "PT", "BE"].includes(r.country))
    return weighted([["DHL", 3], ["FEDEX", 2], ["UPS", 2], ["AZUR_FRET", 3]])
  if (["DE", "AT", "NL", "DK"].includes(r.country))
    return weighted([["DHL", 3], ["UPS", 2], ["FEDEX", 1], ["CERVIN_CARGO", 3]])
  return weighted([["FEDEX", 4], ["DHL", 4], ["UPS", 3]])
}

function transportFor(carrier: Carrier, r: Recipient | undefined, building: Building) {
  if (ROAD_CARRIERS.includes(carrier)) return "ROAD"
  if (r && r.country === "US") return building === "FG01" && chance(0.4) ? "SEA" : "AIR"
  return chance(0.55) ? "ROAD" : "AIR"
}

const DUE_TIMES = ["09:30", "11:00", "12:00", "14:00", "15:30", "17:00"]
const PRIORITY = [[1, 8], [2, 15], [3, 50], [4, 17], [5, 10]] as const

const NOTES = [
  "Call recipient 30 min before delivery",
  "Fragile: glass vials",
  "Customs documents attached",
  "Deliver to goods-in dock 3",
  "Temperature logger inside box 1",
  "Recipient closed after 16:00",
  "Use returnable cool boxes",
  "Proforma invoice required",
  "Tail-lift truck needed",
  "Partial shipment, balance next week",
]
const RESUPPLY_NOTES = ["Packaging material", "Dry-ice carton restock", "Labels and thermal boxes", "Pallet wrap and corner boards"]
const MAINTENANCE_NOTES = ["Cold room temperature mapping", "Forklift inspection", "Freezer defrost", "Dock door service"]

// ---------------------------------------------------------------------------
// Task generation
// ---------------------------------------------------------------------------
interface TaskRow {
  id: string
  building: Building
  type: string
  status: Status
  priority: string
  erp_document_number: string | null
  carrier: Carrier | null
  recipient: string | null
  transport_mode: string | null
  temperature_group: string | null
  other_shipment_category: string | null
  due_date: string
  due_time: string | null
  bottle_count: number | null
  pallet_count: number | null
  package_count: number | null
  dry_ice_carton_count: number | null
  cmr_status: string | null
  rdr26_reference: string | null
  rdr26_closed: boolean
  pgi_done: boolean
  notes: string | null
  created_at: string
  updated_at: string
  completed_at: string | null
}

let erpCounter = FIRST_ERP_NUMBER
let rdr26Counter = FIRST_RDR26_REFERENCE
const tasks: TaskRow[] = []
const recentDays = new Set(days.filter((d) => d < TODAY).slice(-15))

function statusFor(day: string): Status {
  if (day < TODAY) {
    if (recentDays.has(day)) return weighted([["OUT", 90], ["LATE", 5], ["DONE", 3], ["STANDBY", 2]])
    return weighted([["OUT", 995], ["STANDBY", 5]])
  }
  if (day === TODAY) return weighted([["NEW", 45], ["IN_PROGRESS", 25], ["DONE", 15], ["OUT", 10], ["STANDBY", 5]])
  return weighted([["NEW", 95], ["STANDBY", 5]])
}

function makeTask(
  building: Building,
  type: string,
  day: string,
  fields: Partial<TaskRow> = {}
): TaskRow {
  const status = fields.status ?? statusFor(day)
  const dueTime = fields.due_time ?? pick(DUE_TIMES)
  const created = addDays(parseDay(day), -int(1, 7))
  created.setUTCHours(int(7, 16), int(0, 59), int(0, 59))
  const finished = status === "OUT" || status === "DONE"
  const completed = finished ? `${day}T${dueTime}:00Z` : null
  const isShipping = type === "ERP_DOCUMENT" || type === "SHIPMENT" || type === "TRUCK_LOADING"
  const isPast = day <= TODAY
  return {
    id: uuid(),
    building,
    type,
    status,
    priority: String(weighted(PRIORITY)),
    erp_document_number: null,
    carrier: null,
    recipient: null,
    transport_mode: null,
    temperature_group: null,
    other_shipment_category: null,
    due_date: day,
    due_time: dueTime,
    bottle_count: null,
    pallet_count: null,
    package_count: null,
    dry_ice_carton_count: null,
    cmr_status: null,
    rdr26_reference: isShipping && isPast ? String(rdr26Counter++) : null,
    rdr26_closed: isShipping && status === "OUT",
    pgi_done: isShipping && status === "OUT",
    notes: chance(0.12) ? pick(NOTES) : null,
    created_at: created.toISOString(),
    updated_at: completed ?? created.toISOString(),
    completed_at: completed,
    ...fields,
  }
}

function cmrFor(mode: string | null, day: string): string | null {
  if (mode !== "ROAD") return null
  if (day > TODAY) return chance(0.5) ? "IN_WAITING" : null
  if (day === TODAY) return weighted([["IN_WAITING", 4], ["RECEIVED", 3], ["TO_BE_MODIFIED", 1]])
  return weighted([["CHECKED_APPROVED", 85], ["MANUAL", 10], ["NA", 5]])
}

function pj01Shipment(day: string, recipient: Recipient, carrier: Carrier) {
  const mode = transportFor(carrier, recipient, "PJ01")
  const dryIce = chance(0.28)
  const onPallet = chance(0.15)
  const erp = `WMS${erpCounter++}`
  const shipment = makeTask("PJ01", "ERP_DOCUMENT", day, {
    erp_document_number: erp,
    carrier,
    recipient: recipient.code,
    transport_mode: mode,
    temperature_group: dryIce ? "DRY_ICE" : chance(0.3) ? "MONITORED" : "AMBIENT",
    bottle_count: int(6, 240),
    package_count: onPallet ? null : int(1, 6),
    pallet_count: onPallet ? int(1, 2) : null,
    cmr_status: cmrFor(mode, day),
  })
  tasks.push(shipment)
  if (dryIce) {
    const prepTime = DUE_TIMES[Math.max(0, DUE_TIMES.indexOf(shipment.due_time ?? "12:00") - 1)]
    tasks.push(
      makeTask("PJ01", "PREP_DRY_ICE", day, {
        status: shipment.status === "LATE" ? "DONE" : shipment.status,
        priority: shipment.priority,
        erp_document_number: erp,
        recipient: recipient.code,
        due_time: prepTime,
        dry_ice_carton_count: int(1, 4),
        notes: null,
      })
    )
  }
}

for (const day of days) {
  const f = dayFactor(day)
  const weekday = parseDay(day).getUTCDay()

  // ---------------- PJ01: clinical & lab flows ----------------
  const erpCount = count(4.2 * f)
  for (let i = 0; i < erpCount; i++) {
    const recipient = weighted(recipientWeights(PJ01_RECIPIENTS))
    const carrier = carrierFor(recipient)
    // Groupage: several documents leaving together for the same recipient
    const batch = chance(0.12) ? int(2, 4) : 1
    for (let b = 0; b < batch; b++) pj01Shipment(day, recipient, carrier)
  }

  const otherCount = count(1.3 * f)
  for (let i = 0; i < otherCount; i++) {
    const category = weighted([
      ["DOMESTIC_SHIPMENT", 45],
      ["SAMPLES", 20],
      ["CHEMICALS", 15],
      ["HARVEST_BAG", 8],
      ["OTHER", 4],
    ])
    const recipient = category === "DOMESTIC_SHIPMENT"
      ? pick(PJ01_RECIPIENTS.filter((r) => r.country === "CH"))
      : pick(PJ01_RECIPIENTS)
    const carrier = carrierFor(recipient)
    tasks.push(
      makeTask("PJ01", "OTHER_SHIPMENTS", day, {
        other_shipment_category: category,
        recipient: recipient.code,
        carrier,
        transport_mode: transportFor(carrier, recipient, "PJ01"),
        package_count: int(1, 3),
      })
    )
  }
  // Fixed inter-site shuttle every Tuesday and Thursday morning
  if (weekday === 2 || weekday === 4) {
    tasks.push(
      makeTask("PJ01", "OTHER_SHIPMENTS", day, {
        other_shipment_category: "INTERSITE_SHUTTLE",
        carrier: "LEMAN_EXPRESS",
        transport_mode: "ROAD",
        due_time: "09:30",
        priority: "2",
        notes: "Inter-site shuttle PJ01 → FG01",
      })
    )
  }
  if (chance(0.2)) tasks.push(makeTask("PJ01", "RE_SUPPLY", day, { notes: pick(RESUPPLY_NOTES) }))
  if ((weekday === 1 && parseDay(day).getUTCDate() <= 7) || chance(0.03))
    tasks.push(makeTask("PJ01", "MAINTENANCE", day, { due_time: "07:30", notes: pick(MAINTENANCE_NOTES) }))

  // ---------------- FG01: commercial finished goods ----------------
  const shipmentCount = count(1.6 * f)
  for (let i = 0; i < shipmentCount; i++) {
    const recipient = weighted(recipientWeights(FG01_RECIPIENTS))
    const carrier = recipient.country === "US" ? pick<Carrier>(["DHL", "FEDEX", "UPS"]) : carrierFor(recipient)
    const mode = transportFor(carrier, recipient, "FG01")
    tasks.push(
      makeTask("FG01", "SHIPMENT", day, {
        erp_document_number: `WMS${erpCounter++}`,
        recipient: recipient.code,
        carrier,
        transport_mode: mode,
        pallet_count: int(2, 18),
        cmr_status: cmrFor(mode, day),
      })
    )
  }
  const loadingCount = count(3 * f)
  for (let i = 0; i < loadingCount; i++) {
    const recipient = weighted(recipientWeights(FG01_RECIPIENTS.filter((r) => r.country !== "US")))
    const carrier = pick(ROAD_CARRIERS)
    const batch = chance(0.15) ? int(2, 3) : 1
    for (let b = 0; b < batch; b++) {
      tasks.push(
        makeTask("FG01", "TRUCK_LOADING", day, {
          recipient: recipient.code,
          carrier,
          transport_mode: "ROAD",
          pallet_count: int(4, 26),
          cmr_status: cmrFor("ROAD", day),
        })
      )
    }
  }
  if (chance(0.1)) tasks.push(makeTask("FG01", "RE_SUPPLY", day, { notes: pick(RESUPPLY_NOTES) }))
}

// Make sure the demo always shows a few urgent jobs today and tomorrow
for (const day of futureDays.slice(0, 2)) {
  const open = tasks.filter((t) => t.due_date === day && t.status === "NEW")
  for (const t of open.slice(0, 3)) t.priority = "1"
}

// ---------------------------------------------------------------------------
// Work unit matrix, collaborators, availability, forecasts
// ---------------------------------------------------------------------------
const matrix = [
  ["ERP_DOCUMENT", null, "AMBIENT", null, "PACKAGE", 0.8],
  ["ERP_DOCUMENT", null, "AMBIENT", null, "PALLET", 2.5],
  ["ERP_DOCUMENT", "UPS", "AMBIENT", null, "PACKAGE", 0.7],
  ["ERP_DOCUMENT", null, "MONITORED", null, "PACKAGE", 1.1],
  ["ERP_DOCUMENT", null, "MONITORED", null, "PALLET", 3],
  ["ERP_DOCUMENT", null, "DRY_ICE", null, "PACKAGE", 1.4],
  ["ERP_DOCUMENT", null, "DRY_ICE", null, "PALLET", 3.5],
  ["PREP_DRY_ICE", null, null, null, "CARTON", 0.6],
  ["OTHER_SHIPMENTS", null, null, null, "FIXED", 1],
  ["OTHER_SHIPMENTS", null, null, "CHEMICALS", "FIXED", 1.8],
  ["OTHER_SHIPMENTS", null, null, "HARVEST_BAG", "FIXED", 1.5],
  ["OTHER_SHIPMENTS", null, null, "INTERSITE_SHUTTLE", "FIXED", 2.5],
  ["RE_SUPPLY", null, null, null, "FIXED", 1.5],
  ["MAINTENANCE", null, null, null, "FIXED", 4],
  ["SHIPMENT", null, null, null, "PALLET", 0.9],
  ["TRUCK_LOADING", null, null, null, "PALLET", 0.45],
] as const

const FTE: Record<Building, number> = { PJ01: 10, FG01: 12 }
const COLLABORATORS: [string, Building][] = [
  ["Léa Fontanel", "PJ01"],
  ["Marco Bellandi", "PJ01"],
  ["Sofia Krajnc", "PJ01"],
  ["Yanis Dufresne", "PJ01"],
  ["Nora Lindholm", "FG01"],
  ["Tiago Ferraz", "FG01"],
  ["Ines Varga", "FG01"],
  ["Bastien Royer", "FG01"],
  ["Amira Haddou", "FG01"],
]
const collaborators = COLLABORATORS.map(([name, building]) => ({
  id: uuid(),
  name,
  building,
  base_capacity: FTE[building],
  default_percentage: 100,
}))

const availability: { id: string; collaborator_id: string; date: string; percentage: number }[] = []
const holidayTaker = collaborators[int(0, collaborators.length - 1)]
const holidayStart = int(3, 6)
for (const c of collaborators) {
  futureDays.forEach((date, i) => {
    let pct: number | null = null
    if (c === holidayTaker && i >= holidayStart && i < holidayStart + 5) pct = 0
    else if (chance(0.04)) pct = 50
    else if (chance(0.02)) pct = 0
    if (pct !== null) availability.push({ id: uuid(), collaborator_id: c.id, date, percentage: pct })
  })
}

const forecasts = futureDays.flatMap((date) => [
  { id: uuid(), building: "PJ01", date, value: int(2, 8) },
  { id: uuid(), building: "FG01", date, value: int(3, 10) },
])

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------
function workUnits(t: TaskRow): number {
  const qty = (unit: string) =>
    unit === "PALLET" ? t.pallet_count ?? 0
      : unit === "PACKAGE" ? t.package_count ?? 0
      : unit === "CARTON" ? t.dry_ice_carton_count ?? 0
      : unit === "BOTTLE" ? t.bottle_count ?? 0
      : 1
  const candidates = matrix.filter(
    ([type, carrier, temp, cat]) =>
      type === t.type &&
      (carrier === null || carrier === t.carrier) &&
      (temp === null || temp === t.temperature_group) &&
      (cat === null || cat === t.other_shipment_category)
  )
  if (candidates.length === 0) return 0
  const spec = (e: (typeof matrix)[number]) => [e[1], e[2], e[3]].filter((x) => x !== null).length
  const top = Math.max(...candidates.map(spec))
  const best = candidates.filter((e) => spec(e) === top)
  const entry = best.find((e) => qty(e[4]) > 0) ?? best[0]
  return entry[5] * qty(entry[4])
}

function printStats() {
  const by = (key: (t: TaskRow) => string) => {
    const m = new Map<string, number>()
    for (const t of tasks) m.set(key(t), (m.get(key(t)) ?? 0) + 1)
    return Object.fromEntries([...m.entries()].sort())
  }
  console.log(`anchor ${TODAY} · ${days[0]} → ${days[days.length - 1]} · ${days.length} working days`)
  console.log(`tasks: ${tasks.length}`, by((t) => t.building))
  console.log("types:", by((t) => t.type))
  console.log("statuses:", by((t) => t.status))
  console.log("priorities:", by((t) => t.priority))
  console.log("carriers:", by((t) => t.carrier ?? "-"))
  console.log(`recipients used: ${new Set(tasks.map((t) => t.recipient).filter(Boolean)).size}`)
  console.log(`ERP numbers: WMS${FIRST_ERP_NUMBER} → WMS${erpCounter - 1}`)
  for (const b of ["PJ01", "FG01"] as const) {
    const cap = collaborators.filter((c) => c.building === b).reduce((s, c) => s + c.base_capacity, 0)
    const hist = days.filter((d) => d < TODAY)
    const load = tasks.filter((t) => t.building === b && t.due_date < TODAY).reduce((s, t) => s + workUnits(t), 0)
    console.log(`${b}: avg ${(load / hist.length).toFixed(1)} WU/day vs capacity ${cap} WU/day`)
  }
}

// ---------------------------------------------------------------------------
// Write to the database
// ---------------------------------------------------------------------------
async function insertRows(client: pg.Client, table: string, rows: Record<string, unknown>[]) {
  if (rows.length === 0) return
  const columns = Object.keys(rows[0])
  for (let i = 0; i < rows.length; i += 500) {
    const chunk = rows.slice(i, i + 500)
    const values: unknown[] = []
    const tuples = chunk.map((row) => {
      const placeholders = columns.map((c) => {
        values.push(row[c])
        return `$${values.length}`
      })
      return `(${placeholders.join(",")})`
    })
    await client.query(`insert into public.${table} (${columns.join(",")}) values ${tuples.join(",")}`, values)
  }
}

async function main() {
  printStats()
  if (process.argv.includes("--dry-run")) return

  const url = process.env.DATABASE_URL
  if (!url) throw new Error("DATABASE_URL is not set")
  const client = new pg.Client({ connectionString: url, ssl: { rejectUnauthorized: false } })
  await client.connect()
  try {
    if (process.argv.includes("--schema")) {
      const schema = fs.readFileSync(path.join(import.meta.dirname, "../supabase/schema.sql"), "utf8")
      await client.query(schema)
      console.log("schema rebuilt")
    }

    await client.query("begin")
    await client.query(
      "truncate public.tasks, public.work_unit_matrix, public.collaborator_availability, public.collaborators, public.capacity_forecasts"
    )
    await insertRows(
      client,
      "work_unit_matrix",
      matrix.map(([task_type, carrier, temperature_group, other_shipment_category, unit_type, work_unit_value]) => ({
        id: uuid(),
        task_type,
        carrier,
        temperature_group,
        other_shipment_category,
        unit_type,
        work_unit_value,
      }))
    )
    await insertRows(client, "collaborators", collaborators)
    await insertRows(client, "collaborator_availability", availability)
    await insertRows(client, "capacity_forecasts", forecasts)
    await insertRows(client, "tasks", tasks as unknown as Record<string, unknown>[])
    await client.query("select setval('public.erp_document_number_seq', $1, false)", [erpCounter])

    if (process.env.ADMIN_EMAIL) {
      const res = await client.query(
        `insert into public.user_roles (user_id, role)
         select id, 'admin' from auth.users where lower(email) = lower($1)
         on conflict do nothing`,
        [process.env.ADMIN_EMAIL]
      )
      console.log(`admin role granted: ${res.rowCount ?? 0} account(s)`)
    }
    await client.query("commit")
    console.log(`inserted ${tasks.length} tasks, ${collaborators.length} collaborators, ${matrix.length} matrix entries`)
  } catch (err) {
    await client.query("rollback").catch(() => {})
    throw err
  } finally {
    await client.end()
  }
}

await main()
