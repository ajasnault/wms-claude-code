import { useMemo, useState } from "react"
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"
import { useTasks } from "@/hooks/useTasks"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { STATUS_LABELS, TASK_TYPE_LABELS, type TaskStatus, type TaskType } from "@/types/database"

const PERIODS = [7, 14, 30, 60, 90]

const STATUS_COLORS: Record<TaskStatus, string> = {
  NEW: "#f59e0b",
  IN_PROGRESS: "#3b82f6",
  DONE: "#22c55e",
  LATE: "#ef4444",
  STANDBY: "#a855f7",
  OUT: "#6b7280",
}

export default function Analytics() {
  const [period, setPeriod] = useState(30)
  const { tasks, isLoading } = useTasks()

  const periodTasks = useMemo(() => {
    const cutoff = new Date()
    cutoff.setDate(cutoff.getDate() - period)
    const cutoffIso = cutoff.toISOString().slice(0, 10)
    return tasks.filter((t) => t.due_date >= cutoffIso)
  }, [tasks, period])

  const lateRate = useMemo(() => {
    if (periodTasks.length === 0) return 0
    const late = periodTasks.filter((t) => t.status === "LATE").length
    return Math.round((late / periodTasks.length) * 100)
  }, [periodTasks])

  const statusDistribution = useMemo(() => {
    const counts = new Map<TaskStatus, number>()
    for (const t of periodTasks) counts.set(t.status, (counts.get(t.status) ?? 0) + 1)
    return Array.from(counts.entries()).map(([status, count]) => ({
      status,
      label: STATUS_LABELS[status],
      count,
    }))
  }, [periodTasks])

  const typeDistribution = useMemo(() => {
    const counts = new Map<TaskType, number>()
    for (const t of periodTasks) counts.set(t.type, (counts.get(t.type) ?? 0) + 1)
    return Array.from(counts.entries())
      .map(([type, count]) => ({ label: TASK_TYPE_LABELS[type], count }))
      .sort((a, b) => b.count - a.count)
  }, [periodTasks])

  const workloadTrend = useMemo(() => {
    const counts = new Map<string, number>()
    for (const t of periodTasks) counts.set(t.due_date, (counts.get(t.due_date) ?? 0) + 1)
    return Array.from(counts.entries())
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date))
  }, [periodTasks])

  return (
    <div className="p-6">
      <header className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">Analytics</h1>
          <p className="text-sm text-muted-foreground">{periodTasks.length} tasks in the selected period</p>
        </div>
        <Select value={String(period)} onValueChange={(v) => setPeriod(Number(v))}>
          <SelectTrigger className="w-32">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {PERIODS.map((p) => (
              <SelectItem key={p} value={String(p)}>
                {p} days
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </header>

      {isLoading && <p className="text-muted-foreground">Loading…</p>}

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Late rate</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-4xl font-bold text-status-late">{lateRate}%</p>
            <p className="text-sm text-muted-foreground">of tasks in the selected period are/were late</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Status distribution</CardTitle>
          </CardHeader>
          <CardContent className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={statusDistribution} dataKey="count" nameKey="label" outerRadius={90} label>
                  {statusDistribution.map((entry) => (
                    <Cell key={entry.status} fill={STATUS_COLORS[entry.status]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Workload trend (tasks / day)</CardTitle>
          </CardHeader>
          <CardContent className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={workloadTrend}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                <YAxis allowDecimals={false} />
                <Tooltip />
                <Line type="monotone" dataKey="count" stroke="#3b82f6" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Distribution by task type</CardTitle>
          </CardHeader>
          <CardContent className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={typeDistribution} layout="vertical" margin={{ left: 24 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis type="number" allowDecimals={false} />
                <YAxis dataKey="label" type="category" width={120} tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar dataKey="count" fill="#3b82f6" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
