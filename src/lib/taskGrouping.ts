import {
  CARRIER_LABELS,
  DESTINATION_K_LABELS,
  DESTINATION_S_LABELS,
  type Building,
  type Task,
} from "@/types/database"

export interface TaskGroup {
  label: string
  tasks: Task[]
}

export function destinationLabel(task: Task, building: Building): string | null {
  if (building === "K") {
    if (!task.destination_k) return null
    return task.destination_k === "OTHER" && task.destination_k_other
      ? task.destination_k_other
      : DESTINATION_K_LABELS[task.destination_k]
  }
  if (!task.destination_s) return null
  return task.destination_s === "OTHER" && task.destination_s_other
    ? task.destination_s_other
    : DESTINATION_S_LABELS[task.destination_s]
}

export function carrierLabel(task: Task): string | null {
  if (!task.carrier) return null
  return task.carrier === "OTHER" && task.carrier_other ? task.carrier_other : CARRIER_LABELS[task.carrier]
}

export function groupTasksByDestination(tasks: Task[], building: Building): TaskGroup[] {
  const groups = new Map<string, Task[]>()

  for (const task of tasks) {
    const label = destinationLabel(task, building) ?? "Unspecified"
    if (!groups.has(label)) groups.set(label, [])
    groups.get(label)!.push(task)
  }

  return Array.from(groups.entries())
    .map(([label, tasks]) => ({ label, tasks }))
    .sort((a, b) => a.label.localeCompare(b.label))
}

export interface DateGroup {
  date: string
  tasks: Task[]
}

export function groupTasksByDate(tasks: Task[]): DateGroup[] {
  const groups = new Map<string, Task[]>()
  for (const task of tasks) {
    if (!groups.has(task.due_date)) groups.set(task.due_date, [])
    groups.get(task.due_date)!.push(task)
  }

  return Array.from(groups.entries())
    .map(([date, tasks]) => ({ date, tasks }))
    .sort((a, b) => b.date.localeCompare(a.date))
}

export function linkPrepDryIce(tasks: Task[]): { main: Task[]; childrenByParent: Map<string, Task[]> } {
  const byErp = new Map<string, Task[]>()
  for (const t of tasks) {
    if (!t.erp_document_number) continue
    const group = byErp.get(t.erp_document_number)
    if (group) group.push(t)
    else byErp.set(t.erp_document_number, [t])
  }

  const childrenByParent = new Map<string, Task[]>()
  const absorbed = new Set<string>()
  for (const group of byErp.values()) {
    const parents = group.filter((t) => t.type === "ERP_DOCUMENT")
    const children = group.filter((t) => t.type === "PREP_DRY_ICE")
    if (parents.length === 0 || children.length === 0) continue

    // the same erp_document_number can be reused across unrelated shipments over time,
    // so each prep task is matched to the parent with the closest due_date, not just any parent
    for (const child of children) {
      const childDate = Date.parse(child.due_date)
      const parent = parents.reduce((closest, p) =>
        Math.abs(Date.parse(p.due_date) - childDate) < Math.abs(Date.parse(closest.due_date) - childDate)
          ? p
          : closest
      )
      const siblings = childrenByParent.get(parent.id) ?? []
      siblings.push(child)
      childrenByParent.set(parent.id, siblings)
      absorbed.add(child.id)
    }
  }

  return { main: tasks.filter((t) => !absorbed.has(t.id)), childrenByParent }
}

export type DashboardRow = { kind: "single"; task: Task } | { kind: "group"; key: string; tasks: Task[] }

export function groupByCarrier(tasks: Task[]): DashboardRow[] {
  const keyOf = (t: Task) => carrierLabel(t)

  const counts = new Map<string, number>()
  for (const t of tasks) {
    const key = keyOf(t)
    if (key) counts.set(key, (counts.get(key) ?? 0) + 1)
  }

  const rows: DashboardRow[] = []
  const emitted = new Set<string>()
  for (const t of tasks) {
    const key = keyOf(t)
    if (key && (counts.get(key) ?? 0) > 1) {
      if (emitted.has(key)) continue
      emitted.add(key)
      rows.push({ kind: "group", key, tasks: tasks.filter((other) => keyOf(other) === key) })
    } else {
      rows.push({ kind: "single", task: t })
    }
  }
  return rows
}

const STATUS_SORT_ORDER: Record<Task["status"], number> = {
  IN_PROGRESS: 0,
  LATE: 1,
  NEW: 2,
  DONE: 3,
  STANDBY: 4,
  OUT: 5,
}

export function sortTasksByDateThenStatus(tasks: Task[]): Task[] {
  return [...tasks].sort(
    (a, b) =>
      b.due_date.localeCompare(a.due_date) ||
      (b.due_time ?? "").localeCompare(a.due_time ?? "") ||
      STATUS_SORT_ORDER[a.status] - STATUS_SORT_ORDER[b.status]
  )
}

const OUT_MAX_AGE_DAYS = 10

export function filterVisibleForDashboard(tasks: Task[], maxOutAgeDays = OUT_MAX_AGE_DAYS): Task[] {
  const cutoff = new Date()
  cutoff.setDate(cutoff.getDate() - maxOutAgeDays)
  const cutoffDate = cutoff.toISOString().slice(0, 10)

  return tasks.filter((t) => t.status !== "OUT" || t.due_date >= cutoffDate)
}
