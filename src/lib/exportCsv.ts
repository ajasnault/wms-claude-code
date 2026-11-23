import type { Task } from "@/types/database"

export function exportTasksToCsv(tasks: Task[], filename = "tasks.csv") {
  const headers = Object.keys(tasks[0] ?? {})
  const rows = tasks.map((task) =>
    headers
      .map((h) => {
        const value = (task as unknown as Record<string, unknown>)[h]
        return value === null || value === undefined ? "" : `"${String(value).replace(/"/g, '""')}"`
      })
      .join(",")
  )
  const csv = [headers.join(","), ...rows].join("\n")

  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" })
  const url = URL.createObjectURL(blob)
  const link = document.createElement("a")
  link.href = url
  link.download = filename
  link.click()
  URL.revokeObjectURL(url)
}
