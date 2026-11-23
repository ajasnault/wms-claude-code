import { useEffect, useState } from "react"

const timeFormatter = new Intl.DateTimeFormat("fr-CH", {
  timeZone: "Europe/Zurich",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
})

const dateFormatter = new Intl.DateTimeFormat("en-GB", {
  timeZone: "Europe/Zurich",
  weekday: "long",
  day: "2-digit",
  month: "short",
  year: "numeric",
})

export function useClock(): { time: string; date: string } {
  const [now, setNow] = useState(() => new Date())

  useEffect(() => {
    const interval = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(interval)
  }, [])

  return { time: timeFormatter.format(now), date: dateFormatter.format(now).toUpperCase() }
}
