import { Fragment, useState } from "react"
import { ChevronDown, ChevronRight } from "lucide-react"
import { TaskRow } from "@/components/dashboard/TaskRow"
import { carrierLabel, groupByCarrier, sortTasksByDateThenStatus, type TaskGroup } from "@/lib/taskGrouping"
import type { Task } from "@/types/database"

interface DestinationSectionProps {
  group: TaskGroup
  childrenByParent: Map<string, Task[]>
}

export function DestinationSection({ group, childrenByParent }: DestinationSectionProps) {
  const rows = groupByCarrier(sortTasksByDateThenStatus(group.tasks))

  return (
    <section className="space-y-2">
      <h2 className="text-sm font-semibold uppercase text-muted-foreground">
        {group.label} · {group.tasks.length}
      </h2>
      <div className="space-y-2">
        {rows.map((row) =>
          row.kind === "single" ? (
            <TaskWithChildren key={row.task.id} task={row.task} childrenByParent={childrenByParent} />
          ) : (
            <CollapsibleGroup key={row.key} tasks={row.tasks} childrenByParent={childrenByParent} />
          )
        )}
      </div>
    </section>
  )
}

function TaskWithChildren({ task, childrenByParent }: { task: Task; childrenByParent: Map<string, Task[]> }) {
  const children = childrenByParent.get(task.id) ?? []
  return (
    <div className="space-y-2">
      <TaskRow task={task} />
      {children.map((child) => (
        <LinkedChildRow key={child.id} task={child} />
      ))}
    </div>
  )
}

function LinkedChildRow({ task }: { task: Task }) {
  return (
    <div className="relative ml-4 pl-4 before:absolute before:left-0 before:top-0 before:h-full before:border-l-2 before:border-cyan-500/50 before:content-['']">
      <span className="absolute -left-[5px] top-1/2 h-2.5 w-2.5 -translate-y-1/2 rounded-full bg-cyan-500" />
      <TaskRow task={task} linked />
    </div>
  )
}

function CollapsibleGroup({
  tasks,
  childrenByParent,
}: {
  tasks: Task[]
  childrenByParent: Map<string, Task[]>
}) {
  const [open, setOpen] = useState(false)
  const [first] = tasks

  return (
    <div className="rounded-lg border bg-accent/20">
      <button
        type="button"
        className="flex w-full items-center justify-between gap-2 p-3 text-left text-sm font-medium"
        onClick={() => setOpen((o) => !o)}
      >
        <span>
          {first.due_date} · {carrierLabel(first)} · {tasks.length} envois
        </span>
        {open ? <ChevronDown className="h-4 w-4 shrink-0" /> : <ChevronRight className="h-4 w-4 shrink-0" />}
      </button>
      {open && (
        <div className="space-y-2 p-3 pt-0">
          {tasks.map((t) => (
            <Fragment key={t.id}>
              <TaskRow task={t} />
              {(childrenByParent.get(t.id) ?? []).map((child) => (
                <LinkedChildRow key={child.id} task={child} />
              ))}
            </Fragment>
          ))}
        </div>
      )}
    </div>
  )
}
