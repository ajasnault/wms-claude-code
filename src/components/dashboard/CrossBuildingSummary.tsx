import { useTasks } from "@/hooks/useTasks"
import { filterVisibleForDashboard } from "@/lib/taskGrouping"
import { STATUS_LABELS, type Building, type TaskStatus } from "@/types/database"

const ZONE3_OUT_MAX_AGE_DAYS = 1 // documented retention for cross-building recap: 24h

const STATUS_ORDER: TaskStatus[] = ["IN_PROGRESS", "LATE", "NEW", "STANDBY", "DONE", "OUT"]

const STATUS_DOT: Record<TaskStatus, string> = {
  NEW: "bg-status-new",
  IN_PROGRESS: "bg-status-progress",
  DONE: "bg-status-done",
  LATE: "bg-status-late",
  STANDBY: "bg-status-standby",
  OUT: "bg-status-out",
}

export function CrossBuildingSummary({ building }: { building: Building }) {
  const { tasks: allTasks, isLoading } = useTasks(building)
  const tasks = filterVisibleForDashboard(allTasks, ZONE3_OUT_MAX_AGE_DAYS)

  const counts = new Map<TaskStatus, number>()
  for (const t of tasks) counts.set(t.status, (counts.get(t.status) ?? 0) + 1)

  return (
    <div className="space-y-4">
      <h2 className="text-sm font-semibold uppercase text-muted-foreground">Building {building}</h2>

      {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}

      {!isLoading && (
        <>
          <p className="text-3xl font-bold">{tasks.length}</p>
          <p className="text-xs text-muted-foreground">active tasks</p>

          <div className="space-y-2 pt-2">
            {STATUS_ORDER.filter((s) => (counts.get(s) ?? 0) > 0).map((status) => (
              <div key={status} className="flex items-center justify-between gap-2 text-sm">
                <span className="flex items-center gap-2">
                  <span className={`h-2 w-2 rounded-full ${STATUS_DOT[status]}`} />
                  {STATUS_LABELS[status]}
                </span>
                <span className="font-medium">{counts.get(status)}</span>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  )
}
