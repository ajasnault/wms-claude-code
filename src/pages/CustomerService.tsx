import { useMemo, useState } from "react"
import { useTasks } from "@/hooks/useTasks"
import { StatusBadge } from "@/components/dashboard/StatusBadge"
import { Input } from "@/components/ui/input"
import { Card } from "@/components/ui/card"
import { PRIORITY_LABELS } from "@/types/database"

export default function CustomerService() {
  const { tasks, isLoading } = useTasks("K")
  const [search, setSearch] = useState("")

  const shipments = useMemo(() => {
    const erpOnly = tasks.filter((t) => t.type === "ERP_DOCUMENT")
    const filtered = search.trim()
      ? erpOnly.filter((t) => t.erp_document_number?.toLowerCase().includes(search.trim().toLowerCase()))
      : erpOnly

    const byDay = new Map<string, typeof filtered>()
    for (const task of filtered) {
      const list = byDay.get(task.due_date) ?? []
      list.push(task)
      byDay.set(task.due_date, list)
    }
    return Array.from(byDay.entries()).sort((a, b) => b[0].localeCompare(a[0]))
  }, [tasks, search])

  return (
    <div className="mx-auto max-w-md p-4 sm:max-w-2xl sm:p-6">
      <header className="mb-4">
        <h1 className="text-xl font-bold">Customer Service — Shipment Timeline</h1>
        <p className="text-sm text-muted-foreground">Read-only view of ERP shipments (Building K)</p>
      </header>

      <Input
        placeholder="Search by ERP document number…"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        className="mb-4"
      />

      {isLoading && <p className="text-muted-foreground">Loading…</p>}

      <div className="space-y-6">
        {shipments.map(([date, dayTasks]) => (
          <div key={date}>
            <h2 className="mb-2 text-sm font-semibold text-muted-foreground">{date}</h2>
            <div className="space-y-2">
              {dayTasks.map((task) => (
                <Card key={task.id} className="p-3">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="font-medium">ERP {task.erp_document_number ?? "—"}</p>
                      <p className="text-xs text-muted-foreground">{PRIORITY_LABELS[task.priority]}</p>
                    </div>
                    <StatusBadge status={task.status} />
                  </div>
                </Card>
              ))}
            </div>
          </div>
        ))}
        {!isLoading && shipments.length === 0 && (
          <p className="text-muted-foreground">No matching shipments.</p>
        )}
      </div>
    </div>
  )
}
