import { useAuth } from "@/hooks/useAuth"
import { useTaskMutations } from "@/hooks/useTasks"
import { useWorkUnitMatrix } from "@/hooks/useWorkUnitMatrix"
import { calculateWorkUnits } from "@/lib/workUnitCalculator"
import { Card } from "@/components/ui/card"
import { Select, SelectContent, SelectItem, SelectTrigger } from "@/components/ui/select"
import { StatusBadge } from "@/components/dashboard/StatusBadge"
import { PRIORITY_CLASSES, PRIORITY_LABELS, TASK_TYPE_LABELS, type Task, type TaskStatus } from "@/types/database"

export function TaskRow({ task, linked = false }: { task: Task; linked?: boolean }) {
  const { isAdmin } = useAuth()
  const { setStatus, deleteTask } = useTaskMutations()
  const { entries } = useWorkUnitMatrix()
  const wu = calculateWorkUnits(task, entries)

  function handleChange(value: string) {
    if (value === "DELETE") {
      deleteTask(task.id)
    } else {
      setStatus(task.id, value as TaskStatus)
    }
  }

  return (
    <Card
      className={`flex items-center justify-between gap-4 p-3 ${linked ? "border-dashed" : ""} ${
        task.destination_k === "ANGERS_FR" ? "bg-blue-500/15" : ""
      }`}
    >
      <div className="flex min-w-0 flex-col">
        <span className="truncate font-medium">
          {linked && <span className="mr-1 text-muted-foreground">↳</span>}
          {TASK_TYPE_LABELS[task.type]}
        </span>
        <span className="truncate text-sm text-muted-foreground">
          {task.erp_document_number ? `ERP ${task.erp_document_number} · ` : ""}
          Due {task.due_date}
          {task.due_time ? ` ${task.due_time.slice(0, 5)}` : ""}
        </span>
      </div>
      <div className="flex shrink-0 items-center gap-2">
        {wu > 0 && (
          <span className="rounded-full bg-primary/10 px-2 py-0.5 text-xs font-medium text-primary">
            {wu % 1 === 0 ? wu : wu.toFixed(2)} WU
          </span>
        )}
        <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${PRIORITY_CLASSES[task.priority]}`}>
          {PRIORITY_LABELS[task.priority]}
        </span>
        <Select value={task.status} onValueChange={handleChange}>
          <SelectTrigger className="h-auto w-auto border-none bg-transparent p-0 [&>svg]:hidden">
            <StatusBadge status={task.status} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="DONE">Done</SelectItem>
            <SelectItem value="OUT">Out</SelectItem>
            <SelectItem value="STANDBY">Standby</SelectItem>
            {isAdmin && (
              <SelectItem value="DELETE" className="text-destructive">
                Delete
              </SelectItem>
            )}
          </SelectContent>
        </Select>
      </div>
    </Card>
  )
}
