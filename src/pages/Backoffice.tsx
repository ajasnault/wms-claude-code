import { Archive, ArrowDown, ArrowUp, ChevronDown, ChevronRight, Snowflake, Truck } from "lucide-react"
import { Fragment, useMemo, useState } from "react"
import { useTasks, useTaskMutations } from "@/hooks/useTasks"
import { useAuth } from "@/hooks/useAuth"
import { useWorkUnitMatrix } from "@/hooks/useWorkUnitMatrix"
import { calculateWorkUnits } from "@/lib/workUnitCalculator"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { StatusBadge } from "@/components/dashboard/StatusBadge"
import { TaskFormDialog } from "@/components/backoffice/TaskFormDialog"
import { exportTasksToCsv } from "@/lib/exportCsv"
import { carrierLabel, destinationLabel, linkPrepDryIce } from "@/lib/taskGrouping"
import { cn } from "@/lib/utils"
import {
  CMR_STATUS_LABELS,
  PRIORITY_LABELS,
  STATUS_LABELS,
  TASK_TYPE_LABELS,
  TRANSPORT_MODE_LABELS,
  type Building,
  type CmrStatus,
  type Task,
  type TaskStatus,
  type WorkUnitMatrixEntry,
} from "@/types/database"

const CMR_STATUSES: CmrStatus[] = ["IN_WAITING", "RECEIVED", "CHECKED_APPROVED", "TO_BE_MODIFIED", "MANUAL", "NA"]

const STATUSES: TaskStatus[] = ["NEW", "IN_PROGRESS", "DONE", "LATE", "STANDBY", "OUT"]

const DRY_ICE_KG_PER_CARTON = 20 // documented: 3 cartons ≈ 60 kg

const OLD_SHIPMENT_DAYS = 45

const MONTH_LABEL_FORMAT = new Intl.DateTimeFormat("fr-FR", { month: "long", year: "numeric" })

function monthLabel(monthKey: string): string {
  const [year, month] = monthKey.split("-").map(Number)
  return MONTH_LABEL_FORMAT.format(new Date(year, month - 1, 1))
}

function cardClass(task: Task, fallback: string): string {
  if (task.destination_k === "WAVRE_BE") return cn(fallback, "bg-rose-100 border-rose-200")
  if (task.carrier === "DHL") return cn(fallback, "bg-yellow-100/60")
  if (task.destination_k === "ANGERS_FR") return cn(fallback, "bg-blue-100 border-blue-200")
  if (task.carrier === "TNT_FEDEX") return cn(fallback, "bg-purple-100 border-purple-200")
  return fallback
}

function groupKey(task: Task, building: Building): string | null {
  const dest = destinationLabel(task, building)
  const carrier = carrierLabel(task)
  if (!dest || !carrier) return null
  return `${task.due_date}|${dest}|${carrier}`
}

function dryIceTotals(tasks: Task[], childrenByParent: Map<string, Task[]>): { cartons: number; kg: number } | null {
  let cartons = 0
  for (const t of tasks) {
    for (const child of childrenByParent.get(t.id) ?? []) {
      cartons += child.dry_ice_carton_count ?? 0
    }
  }
  return cartons > 0 ? { cartons, kg: cartons * DRY_ICE_KG_PER_CARTON } : null
}

function workUnitsTotal(tasks: Task[], matrix: WorkUnitMatrixEntry[]): number {
  return tasks.reduce((sum, t) => sum + calculateWorkUnits(t, matrix), 0)
}

function quantityBadges(task: Task): string[] {
  const badges: string[] = []
  if (task.bottle_count) badges.push(`${task.bottle_count} btl`)
  if (task.pallet_count) badges.push(`${task.pallet_count} pal`)
  if (task.package_count) badges.push(`${task.package_count} pkg`)
  if (task.dry_ice_carton_count) badges.push(`${task.dry_ice_carton_count} cart`)
  return badges
}

type Row =
  | { kind: "single"; task: Task }
  | { kind: "common"; key: string; tasks: Task[] }
  | { kind: "month"; key: string; tasks: Task[] }

function groupCommonShipments(tasks: Task[], building: Building, oldCutoff: string): Row[] {
  const counts = new Map<string, number>()
  for (const t of tasks) {
    if (t.due_date < oldCutoff) continue
    const key = groupKey(t, building)
    if (key) counts.set(key, (counts.get(key) ?? 0) + 1)
  }

  const rows: Row[] = []
  const emittedCommon = new Set<string>()
  const emittedMonth = new Set<string>()
  for (const t of tasks) {
    if (t.due_date < oldCutoff) {
      const monthKey = t.due_date.slice(0, 7)
      if (emittedMonth.has(monthKey)) continue
      emittedMonth.add(monthKey)
      rows.push({
        kind: "month",
        key: `month:${monthKey}`,
        tasks: tasks.filter((other) => other.due_date < oldCutoff && other.due_date.slice(0, 7) === monthKey),
      })
      continue
    }

    const key = groupKey(t, building)
    if (key && (counts.get(key) ?? 0) > 1) {
      if (emittedCommon.has(key)) continue
      emittedCommon.add(key)
      rows.push({
        kind: "common",
        key,
        tasks: tasks.filter((other) => other.due_date >= oldCutoff && groupKey(other, building) === key),
      })
    } else {
      rows.push({ kind: "single", task: t })
    }
  }
  return rows
}

export default function Backoffice() {
  const [building, setBuilding] = useState<Building>("K")
  const [statusFilter, setStatusFilter] = useState<TaskStatus | "ALL">("ALL")
  const [search, setSearch] = useState("")
  const [orphanDryIceOnly, setOrphanDryIceOnly] = useState(false)
  const [sortDir, setSortDir] = useState<"asc" | "desc">("desc")
  const [formOpen, setFormOpen] = useState(false)
  const [editingTask, setEditingTask] = useState<Task | undefined>(undefined)
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set())

  function toggleGroup(key: string) {
    setExpandedGroups((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      return next
    })
  }

  const { tasks, isLoading } = useTasks(building)
  const { setStatus, updateTask, deleteTask } = useTaskMutations()
  const { isAdmin } = useAuth()
  const { entries: matrix } = useWorkUnitMatrix()

  const dryIceNeeded = useMemo(() => {
    const cartons = tasks
      .filter((t) => t.type === "PREP_DRY_ICE" && t.status !== "OUT" && t.status !== "DONE")
      .reduce((sum, t) => sum + (t.dry_ice_carton_count ?? 0), 0)
    return { cartons, kg: cartons * DRY_ICE_KG_PER_CARTON }
  }, [tasks])

  const filtered = useMemo(() => {
    const byStatus = statusFilter === "ALL" ? tasks : tasks.filter((t) => t.status === statusFilter)
    const q = search.trim().toLowerCase()
    const bySearch = q
      ? byStatus.filter((t) =>
          [t.erp_document_number, t.k2_reference, destinationLabel(t, building), carrierLabel(t), t.notes]
            .filter(Boolean)
            .some((field) => field!.toLowerCase().includes(q))
        )
      : byStatus
    const dir = sortDir === "asc" ? 1 : -1
    return [...bySearch].sort(
      (a, b) =>
        dir * (a.due_date.localeCompare(b.due_date) || (a.due_time ?? "").localeCompare(b.due_time ?? ""))
    )
  }, [tasks, statusFilter, search, building, sortDir])

  const { main, childrenByParent } = useMemo(() => linkPrepDryIce(filtered), [filtered])

  const orphanDryIce = useMemo(() => main.filter((t) => t.type === "PREP_DRY_ICE"), [main])

  const oldCutoff = useMemo(() => {
    const d = new Date()
    d.setDate(d.getDate() - OLD_SHIPMENT_DAYS)
    return d.toISOString().slice(0, 10)
  }, [])

  const rows = useMemo(
    () =>
      orphanDryIceOnly
        ? orphanDryIce.map((task) => ({ kind: "single", task }) as Row)
        : groupCommonShipments(main, building, oldCutoff),
    [orphanDryIceOnly, orphanDryIce, main, building, oldCutoff]
  )

  async function bulkSetStatus(tasks: Task[], status: TaskStatus) {
    await Promise.all(tasks.map((t) => setStatus(t.id, status)))
  }

  async function bulkSetCmrStatus(tasks: Task[], cmrStatus: CmrStatus) {
    await Promise.all(tasks.map((t) => updateTask(t.id, { cmr_status: cmrStatus })))
  }

  function openCreate() {
    setEditingTask(undefined)
    setFormOpen(true)
  }

  function openEdit(task: Task) {
    setEditingTask(task)
    setFormOpen(true)
  }

  function TaskCard({ task, linked = false }: { task: Task; linked?: boolean }) {
    const wu = calculateWorkUnits(task, matrix)
    const hasDryIce = (childrenByParent.get(task.id) ?? []).length > 0 || task.type === "PREP_DRY_ICE"

    return (
      <div className={cardClass(task, cn("rounded-lg border p-3", linked && "ml-6 border-dashed"))}>
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex flex-wrap items-center gap-2">
            {linked && <span className="text-muted-foreground">↳</span>}
            <span className="rounded bg-muted px-1.5 py-0.5 text-xs font-bold">{task.building}</span>
            <span className="font-medium">{TASK_TYPE_LABELS[task.type]}</span>
            {task.erp_document_number && (
              <span className="text-sm text-muted-foreground">#{task.erp_document_number}</span>
            )}
            {task.k2_reference && (
              <span className="rounded bg-purple-100 px-1.5 py-0.5 text-xs font-medium text-purple-700">
                K2:{task.k2_reference}
              </span>
            )}
            {hasDryIce && (
              <span className="flex items-center gap-1 rounded bg-cyan-100 px-1.5 py-0.5 text-xs font-medium text-cyan-700">
                <Snowflake className="h-3 w-3" /> Dry-Ice
              </span>
            )}
          </div>

          <div className="flex items-center gap-2">
            <Select value={task.status} onValueChange={(v) => setStatus(task.id, v as TaskStatus)}>
              <SelectTrigger className="h-7 w-auto border-none bg-transparent p-0">
                <StatusBadge status={task.status} />
              </SelectTrigger>
              <SelectContent>
                {STATUSES.map((s) => (
                  <SelectItem key={s} value={s}>
                    {STATUS_LABELS[s]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <span className="text-xs text-muted-foreground">{PRIORITY_LABELS[task.priority]}</span>
            <span className="text-sm text-muted-foreground">
              {task.due_date}
              {task.due_time ? ` ${task.due_time.slice(0, 5)}` : ""}
            </span>
            <Button variant="ghost" size="sm" onClick={() => openEdit(task)}>
              Edit
            </Button>
            {isAdmin && (
              <Button variant="ghost" size="sm" onClick={() => deleteTask(task.id)}>
                Delete
              </Button>
            )}
          </div>
        </div>

        <div className="mt-1.5 flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
          <span className="font-medium text-foreground">{destinationLabel(task, building) ?? "—"}</span>
          {task.carrier && (
            <span className="flex items-center gap-1">
              <Truck className="h-3.5 w-3.5" /> {carrierLabel(task)}
            </span>
          )}
          {task.transport_mode && <span>{TRANSPORT_MODE_LABELS[task.transport_mode]}</span>}
        </div>

        <div className="mt-1.5 flex flex-wrap items-center gap-2">
          {quantityBadges(task).map((label) => (
            <span key={label} className="rounded bg-muted px-1.5 py-0.5 text-xs">
              {label}
            </span>
          ))}
          {wu > 0 && (
            <span className="rounded bg-orange-100 px-1.5 py-0.5 text-xs font-medium text-orange-700">
              {wu.toFixed(2)} WU
            </span>
          )}
          {task.cmr_status && (
            <span
              className={cn(
                "rounded px-1.5 py-0.5 text-xs font-medium",
                task.cmr_status === "CHECKED_APPROVED" ? "bg-status-done/15 text-status-done" : "bg-muted"
              )}
            >
              {CMR_STATUS_LABELS[task.cmr_status]}
            </span>
          )}
          <button
            type="button"
            onClick={() => updateTask(task.id, { k2_closed: !task.k2_closed })}
            className={cn(
              "rounded border px-1.5 py-0.5 text-xs font-medium",
              task.k2_closed ? "border-status-done/40 bg-status-done/15 text-status-done" : "text-muted-foreground"
            )}
          >
            {task.k2_closed ? "✓" : "○"} K2 closed
          </button>
          <button
            type="button"
            onClick={() => updateTask(task.id, { pgi_done: !task.pgi_done })}
            className={cn(
              "rounded border px-1.5 py-0.5 text-xs font-medium",
              task.pgi_done ? "border-status-done/40 bg-status-done/15 text-status-done" : "text-muted-foreground"
            )}
          >
            {task.pgi_done ? "✓" : "○"} PGI done
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="p-6">
      <header className="mb-6 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">Backoffice</h1>
        {dryIceNeeded.cartons > 0 && (
          <span className="flex items-center gap-1.5 rounded-full bg-cyan-100 px-3 py-1 text-sm font-medium text-cyan-700">
            <Snowflake className="h-4 w-4" />
            {dryIceNeeded.cartons} cartons ({dryIceNeeded.kg} kg) needed
          </span>
        )}
      </header>

      <div className="mb-4 flex flex-wrap items-center gap-3">
        <Select value={building} onValueChange={(v) => setBuilding(v as Building)}>
          <SelectTrigger className="w-32">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="K">Building K</SelectItem>
            <SelectItem value="S">Building S</SelectItem>
          </SelectContent>
        </Select>

        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as TaskStatus | "ALL")}>
          <SelectTrigger className="w-40">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="ALL">All statuses</SelectItem>
            {STATUSES.map((s) => (
              <SelectItem key={s} value={s}>
                {STATUS_LABELS[s]}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search ERP #, K2 ref, destination, carrier, notes…"
          className="w-72"
        />

        <Button
          variant={orphanDryIceOnly ? "default" : "outline"}
          size="sm"
          onClick={() => setOrphanDryIceOnly((v) => !v)}
        >
          <Snowflake className="mr-2 h-4 w-4" />
          Orphan Dry Ice {orphanDryIce.length > 0 && `(${orphanDryIce.length})`}
        </Button>

        <Button
          variant="outline"
          size="sm"
          onClick={() => setSortDir((d) => (d === "asc" ? "desc" : "asc"))}
        >
          {sortDir === "asc" ? <ArrowUp className="mr-2 h-4 w-4" /> : <ArrowDown className="mr-2 h-4 w-4" />}
          Date {sortDir === "asc" ? "(soonest first)" : "(latest first)"}
        </Button>

        <div className="ml-auto flex gap-2">
          <Button variant="outline" onClick={() => filtered.length && exportTasksToCsv(filtered)}>
            Export CSV
          </Button>
          <Button onClick={openCreate}>+ New task</Button>
        </div>
      </div>

      {isLoading && <p className="text-muted-foreground">Loading…</p>}

      <div className="space-y-2">
        {rows.map((row) => {
          if (row.kind === "single") {
            return (
              <Fragment key={row.task.id}>
                <TaskCard task={row.task} />
                {(childrenByParent.get(row.task.id) ?? []).map((child) => (
                  <TaskCard key={child.id} task={child} linked />
                ))}
              </Fragment>
            )
          }
          if (row.kind === "month") {
            const isOpen = expandedGroups.has(row.key)
            const dryIce = dryIceTotals(row.tasks, childrenByParent)
            const wuTotal = workUnitsTotal(row.tasks, matrix)
            return (
              <Fragment key={row.key}>
                <button
                  type="button"
                  onClick={() => toggleGroup(row.key)}
                  className="flex w-full items-center justify-between gap-2 rounded-lg border border-dashed px-3 py-2 text-left text-xs font-medium text-muted-foreground bg-muted/50"
                >
                  <span className="flex items-center gap-2">
                    <Archive className="h-3.5 w-3.5 shrink-0" />
                    {monthLabel(row.key.slice(6))} · {row.tasks.length} envois
                    {wuTotal > 0 && ` · ${wuTotal.toFixed(2)} WU`}
                    {dryIce && (
                      <>
                        {" "}
                        · ❄️ {dryIce.cartons} cartons ({dryIce.kg} kg)
                      </>
                    )}
                  </span>
                  {isOpen ? (
                    <ChevronDown className="h-3.5 w-3.5 shrink-0" />
                  ) : (
                    <ChevronRight className="h-3.5 w-3.5 shrink-0" />
                  )}
                </button>
                {isOpen && (
                  <div className="space-y-2 pl-3">
                    {row.tasks.map((task) => (
                      <Fragment key={task.id}>
                        <TaskCard task={task} />
                        {(childrenByParent.get(task.id) ?? []).map((child) => (
                          <TaskCard key={child.id} task={child} linked />
                        ))}
                      </Fragment>
                    ))}
                  </div>
                )}
              </Fragment>
            )
          }
          const [first] = row.tasks
          const isOpen = expandedGroups.has(row.key)
          const dryIce = dryIceTotals(row.tasks, childrenByParent)
          const wuTotal = workUnitsTotal(row.tasks, matrix)
          return (
            <Fragment key={row.key}>
              <div
                className={cardClass(
                  first,
                  "flex w-full items-center justify-between gap-2 rounded-lg border px-3 py-2 text-xs font-medium text-muted-foreground bg-accent/40"
                )}
              >
                <button
                  type="button"
                  onClick={() => toggleGroup(row.key)}
                  className="flex flex-1 items-center gap-2 text-left"
                >
                  <span>
                    Commun · {first.due_date} · {destinationLabel(first, building)} · {carrierLabel(first)} ·{" "}
                    {row.tasks.length} envois
                    {wuTotal > 0 && ` · ${wuTotal.toFixed(2)} WU`}
                    {dryIce && (
                      <>
                        {" "}
                        · ❄️ {dryIce.cartons} cartons ({dryIce.kg} kg)
                      </>
                    )}
                  </span>
                  {isOpen ? (
                    <ChevronDown className="h-3.5 w-3.5 shrink-0" />
                  ) : (
                    <ChevronRight className="h-3.5 w-3.5 shrink-0" />
                  )}
                </button>
                <div className="flex shrink-0 items-center gap-1.5" onClick={(e) => e.stopPropagation()}>
                  <Select value="" onValueChange={(v) => bulkSetStatus(row.tasks, v as TaskStatus)}>
                    <SelectTrigger className="h-7 w-auto gap-1 border-dashed bg-background px-2 text-xs">
                      <SelectValue placeholder="Statut →" />
                    </SelectTrigger>
                    <SelectContent>
                      {STATUSES.map((s) => (
                        <SelectItem key={s} value={s}>
                          {STATUS_LABELS[s]}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Select value="" onValueChange={(v) => bulkSetCmrStatus(row.tasks, v as CmrStatus)}>
                    <SelectTrigger className="h-7 w-auto gap-1 border-dashed bg-background px-2 text-xs">
                      <SelectValue placeholder="CMR →" />
                    </SelectTrigger>
                    <SelectContent>
                      {CMR_STATUSES.map((s) => (
                        <SelectItem key={s} value={s}>
                          {CMR_STATUS_LABELS[s]}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              {isOpen && (
                <div className="space-y-2 pl-3">
                  {row.tasks.map((task) => (
                    <Fragment key={task.id}>
                      <TaskCard task={task} />
                      {(childrenByParent.get(task.id) ?? []).map((child) => (
                        <TaskCard key={child.id} task={child} linked />
                      ))}
                    </Fragment>
                  ))}
                </div>
              )}
            </Fragment>
          )
        })}
        {!isLoading && rows.length === 0 && (
          <p className="p-6 text-center text-muted-foreground">No tasks match the current filters.</p>
        )}
      </div>

      <TaskFormDialog open={formOpen} onOpenChange={setFormOpen} task={editingTask} defaultBuilding={building} />
    </div>
  )
}
