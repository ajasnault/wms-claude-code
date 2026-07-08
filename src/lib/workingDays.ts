function toIsoDate(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, "0")
  const day = String(d.getDate()).padStart(2, "0")
  return `${y}-${m}-${day}`
}

export function nextWorkingDays(count: number, from: Date = new Date()): string[] {
  const days: string[] = []
  const cursor = new Date(from)
  cursor.setHours(0, 0, 0, 0)

  while (days.length < count) {
    const dow = cursor.getDay()
    if (dow !== 0 && dow !== 6) {
      days.push(toIsoDate(cursor))
    }
    cursor.setDate(cursor.getDate() + 1)
  }

  return days
}
