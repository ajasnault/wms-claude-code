import { Maximize, Minimize } from "lucide-react"
import type { ReactNode } from "react"
import { useFullscreen } from "@/hooks/useFullscreen"
import { useClock } from "@/hooks/useClock"
import { useCapacityUtilization } from "@/hooks/useCapacityUtilization"
import { CrossBuildingSummary } from "@/components/dashboard/CrossBuildingSummary"
import { Button } from "@/components/ui/button"
import type { Building } from "@/types/database"

function utilizationPillClass(pct: number): string {
  if (pct > 100) return "bg-status-late/20 text-status-late border-status-late/40"
  if (pct >= 80) return "bg-status-new/20 text-status-new border-status-new/40"
  return "bg-status-done/20 text-status-done border-status-done/40"
}

export function DashboardLayout({
  building,
  flowLabel,
  stats,
  otherBuilding,
  children,
}: {
  building: Building
  flowLabel: string
  stats: ReactNode
  otherBuilding: Building
  children: ReactNode
}) {
  const { isFullscreen, toggle } = useFullscreen()
  const { time, date } = useClock()
  const { today, tomorrow } = useCapacityUtilization(building)

  return (
    <div className="dark flex h-[calc(100dvh-3rem-4rem-env(safe-area-inset-bottom))] flex-col overflow-hidden bg-background font-mono text-foreground md:h-[calc(100vh-3.5rem)]">
      <header className="flex shrink-0 items-center justify-between gap-4 border-b border-border px-4 py-2 md:h-[10%] md:px-6 md:py-0">
        <div>
          <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
            <h1 className="text-lg font-bold tracking-wide md:text-2xl">BUILDING {building}</h1>
            <span className={`rounded border px-2 py-0.5 text-xs font-semibold ${utilizationPillClass(today)}`}>
              J+0: {today}%
            </span>
            <span className={`rounded border px-2 py-0.5 text-xs font-semibold ${utilizationPillClass(tomorrow)}`}>
              J+1: {tomorrow}%
            </span>
          </div>
          <p className="text-xs uppercase tracking-wide text-muted-foreground">
            {flowLabel} · {stats}
          </p>
        </div>
        <div className="flex items-center gap-4">
          <div className="text-right">
            <div className="text-xl font-bold tabular-nums md:text-3xl">{time}</div>
            <div className="hidden text-xs tracking-wide text-muted-foreground md:block">{date}</div>
          </div>
          <Button variant="outline" size="sm" onClick={toggle} className="hidden md:inline-flex">
            {isFullscreen ? <Minimize className="mr-2 h-4 w-4" /> : <Maximize className="mr-2 h-4 w-4" />}
            {isFullscreen ? "Exit fullscreen" : "Fullscreen"}
          </Button>
        </div>
      </header>

      <div className="flex min-h-0 flex-1 md:h-[90%] md:flex-none">
        <main className="w-full overflow-y-auto p-3 md:w-[80%] md:p-6">{children}</main>
        <aside className="hidden w-[20%] overflow-hidden md:block border-l-2 border-cyan-500/40 p-4 shadow-[inset_8px_0_16px_-12px_rgba(34,211,238,0.4)]">
          <CrossBuildingSummary building={otherBuilding} />
        </aside>
      </div>
    </div>
  )
}
