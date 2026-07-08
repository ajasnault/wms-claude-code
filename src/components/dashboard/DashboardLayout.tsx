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
    <div className="dark flex h-[calc(100vh-3.5rem)] flex-col overflow-hidden bg-background font-mono text-foreground">
      <header className="flex h-[10%] shrink-0 items-center justify-between gap-4 border-b border-border px-6">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold tracking-wide">BUILDING {building}</h1>
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
            <div className="text-3xl font-bold tabular-nums">{time}</div>
            <div className="text-xs tracking-wide text-muted-foreground">{date}</div>
          </div>
          <Button variant="outline" size="sm" onClick={toggle}>
            {isFullscreen ? <Minimize className="mr-2 h-4 w-4" /> : <Maximize className="mr-2 h-4 w-4" />}
            {isFullscreen ? "Exit fullscreen" : "Fullscreen"}
          </Button>
        </div>
      </header>

      <div className="flex h-[90%]">
        <main className="w-[80%] overflow-y-auto p-6">{children}</main>
        <aside className="w-[20%] overflow-hidden border-l-2 border-cyan-500/40 p-4 shadow-[inset_8px_0_16px_-12px_rgba(34,211,238,0.4)]">
          <CrossBuildingSummary building={otherBuilding} />
        </aside>
      </div>
    </div>
  )
}
