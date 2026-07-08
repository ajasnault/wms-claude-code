import { cn } from "@/lib/utils"
import { STATUS_LABELS, type TaskStatus } from "@/types/database"

const STATUS_CLASSES: Record<TaskStatus, string> = {
  NEW: "bg-status-new/15 text-status-new border-status-new/30",
  IN_PROGRESS: "bg-status-progress/15 text-status-progress border-status-progress/30",
  DONE: "bg-status-done/15 text-status-done border-status-done/30",
  LATE: "bg-status-late/15 text-status-late border-status-late/30",
  STANDBY: "bg-status-standby/15 text-status-standby border-status-standby/30",
  OUT: "bg-status-out/15 text-status-out border-status-out/30",
}

export function StatusBadge({ status, className }: { status: TaskStatus; className?: string }) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-md border px-2 py-0.5 text-xs font-semibold",
        STATUS_CLASSES[status],
        className
      )}
    >
      {STATUS_LABELS[status]}
    </span>
  )
}
