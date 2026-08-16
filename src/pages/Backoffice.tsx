import { ChevronDown, ChevronRight, Snowflake, Truck } from "lucide-react"
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
  type Task,
  type TaskStatus,
  type WorkUnitMatrixEntry,
} from "@/types/database"

const STATUSES: TaskStatus[] = ["NEW", "IN_PROGRESS", "DONE", "LATE", "STANDBY", "OUT"]

const DRY_ICE_KG_PER_CARTON = 20 // documented: 3 cartons ≈ 60 kg

function cardClass(task: Task, fallback: string): string {
  if (task.destination_k === "WAVRE_BE") return cn(fallback, "bg-rose-100 border-rose-200")
  if (task.carrier === "DHL") return cn(fallback, "bg-yellow-100/60")
  if (task.destination_k === "ANGERS_FR") return cn(fallback, "bg-blue-100 border-blue-200")
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

type Row = { kind: "single"; task: Task } | { kind: "common"; key: string; tasks: Task[] }

type DayGroup = { key: string; label: string; rows: Row[]; defaultOpen: boolean }

function rowDate(row: Row): string {
  return row.kind === "single" ? row.task.due_date : row.tasks[0].due_date
}

function startOfToday(): Date {
  const d = new Date()
  d.setHours(0, 0, 0, 0)
  return d
}

function diffInDays(dateStr: string, today: Date): number {
  const d = new Date(`${dateStr}T00:00:00`)
  return Math.round((d.getTime() - today.getTime()) / 86_400_000)
}

function formatDayLabel(dateStr: string): string {
  const d = new Date(`${dateStr}T00:00:00`)
  return d.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short" })
}

function buildDayGroups(rows: Row[]): DayGroup[] {
  const today = startOfToday()
  const monIndex = (today.getDay() + 6) % 7 // Mon=0 .. Sun=6
  const daysUntilWeekEnd = 6 - monIndex // days left until (and including) this Sunday

  const groups = new Map<string, DayGroup>()
  for (const row of rows) {
    const dateStr = rowDate(row)
    const diff = diffInDays(dateStr, today)
    let key: string
    let label: string
    let defaultOpen: boolean
    if (diff < 0) {
      key = "overdue"
      label = "Overdue"
      defaultOpen = true
    } else if (diff === 0) {
      key = "today"
      label = "Today"
      defaultOpen = true
    } else if (diff === 1) {
      key = "tomorrow"
      label = "Tomorrow"
      defaultOpen = true
    } else {
      key = dateStr
      label = formatDayLabel(dateStr)
      defaultOpen = diff <= daysUntilWeekEnd
    }
    let group = groups.get(key)
    if (!group) {
      group = { key, label, rows: [], defaultOpen }
      groups.set(key, group)
    }
    group.rows.push(row)
  }
  return [...groups.values()]
}

function groupCommonShipments(tasks: Task[], building: Building): Row[] {
  const counts = new Map<string, number>()
  for (const t of tasks) {
    const key = groupKey(t, building)
    if (key) counts.set(key, (counts.get(key) ?? 0) + 1)
  }

  const rows: Row[] = []
  const emitted = new Set<string>()
  for (const t of tasks) {
    const key = groupKey(t, building)
    if (key && (counts.get(key) ?? 0) > 1) {
      if (emitted.has(key)) continue
      emitted.add(key)
      rows.push({ kind: "common", key, tasks: tasks.filter((other) => groupKey(other, building) === key) })
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
    return [...bySearch].sort(
      (a, b) => a.due_date.localeCompare(b.due_date) || (a.due_time ?? "").localeCompare(b.due_time ?? "")
    )
  }, [tasks, statusFilter, search, building])

  const { main, childrenByParent } = useMemo(() => linkPrepDryIce(filtered), [filtered])

  const orphanDryIce = useMemo(() => main.filter((t) => t.type === "PREP_DRY_ICE"), [main])

  const rows = useMemo(
    () => (orphanDryIceOnly ? orphanDryIce.map((task) => ({ kind: "single", task }) as Row) : groupCommonShipments(main, building)),
    [orphanDryIceOnly, orphanDryIce, main, building]
  )

  const dayGroups = useMemo(() => buildDayGroups(rows), [rows])

  const [collapsedOverrides, setCollapsedOverrides] = useState<Set<string>>(new Set())

  function toggleDay(key: string) {
    setCollapsedOverrides((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      return next
    })
  }

  function isDayOpen(group: DayGroup) {
    return collapsedOverrides.has(group.key) ? !group.defaultOpen : group.defaultOpen
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

  function renderRow(row: Row) {
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
    const [first] = row.tasks
    const isOpen = expandedGroups.has(row.key)
    const dryIce = dryIceTotals(row.tasks, childrenByParent)
    const wuTotal = workUnitsTotal(row.tasks, matrix)
    return (
      <Fragment key={row.key}>
        <button
          type="button"
          onClick={() => toggleGroup(row.key)}
          className={cardClass(
            first,
            "flex w-full items-center justify-between gap-2 rounded-lg border px-3 py-2 text-left text-xs font-medium text-muted-foreground bg-accent/40"
          )}
        >
          <span>
            Commun · {first.due_date} · {destinationLabel(first, building)} · {carrierLabel(first)} · {row.tasks.length}{" "}
            envois
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

        <div className="ml-auto flex gap-2">
          <Button variant="outline" onClick={() => filtered.length && exportTasksToCsv(filtered)}>
            Export CSV
          </Button>
          <Button onClick={openCreate}>+ New task</Button>
        </div>
      </div>

      {isLoading && <p className="text-muted-foreground">Loading…</p>}

      <div className="space-y-4">
        {dayGroups.map((group) => {
          const isOpen = isDayOpen(group)
          return (
            <div key={group.key}>
              <button
                type="button"
                onClick={() => toggleDay(group.key)}
                className={cn(
                  "sticky top-0 z-10 flex w-full items-center justify-between gap-2 border-b bg-background/95 px-1 py-2 text-left text-sm font-semibold backdrop-blur",
                  group.key === "overdue" && "text-destructive"
                )}
              >
                <span>
                  {group.label}{" "}
                  <span className="ml-1 text-xs font-normal text-muted-foreground">({group.rows.length})</span>
                </span>
                {isOpen ? (
                  <ChevronDown className="h-4 w-4 shrink-0" />
                ) : (
                  <ChevronRight className="h-4 w-4 shrink-0" />
                )}
              </button>
              {isOpen && <div className="mt-2 space-y-2">{group.rows.map((row) => renderRow(row))}</div>}
            </div>
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
