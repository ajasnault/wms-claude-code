import { useMemo, useState, type FormEvent } from "react"
import {
  Bar,
  CartesianGrid,
  ComposedChart,
  Legend,
  Line,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"
import { useAuth } from "@/hooks/useAuth"
import { useTasks } from "@/hooks/useTasks"
import { useCollaborators, useCollaboratorAvailability, useCapacityForecasts } from "@/hooks/useCapacity"
import { useWorkUnitMatrix } from "@/hooks/useWorkUnitMatrix"
import { calculateWorkUnits } from "@/lib/workUnitCalculator"
import { nextWorkingDays } from "@/lib/workingDays"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { cn } from "@/lib/utils"
import type { Building } from "@/types/database"

const DAYS = nextWorkingDays(10)
const AVAIL_OPTIONS = [0, 25, 50, 75, 100] as const
const FTE_BY_BUILDING: Record<string, number> = { K: 12.5, S: 33 }

function utilizationColor(pct: number) {
  if (pct > 100) return "text-red-500"
  if (pct >= 80) return "text-amber-500"
  return "text-green-500"
}

function formatDate(iso: string) {
  return iso.slice(8) + "/" + iso.slice(5, 7)
}

function availColor(pct: number) {
  if (pct === 0) return "text-muted-foreground bg-muted"
  if (pct === 100) return "text-green-700 bg-green-50 font-medium"
  return "text-amber-700 bg-amber-50"
}

function BuildingCapacitySection({ building }: { building: Building }) {
  const { tasks } = useTasks(building)
  const { collaborators, createCollaborator, deleteCollaborator } = useCollaborators(building)
  const { availability, setAvailability } = useCollaboratorAvailability()
  const { forecasts } = useCapacityForecasts()
  const { entries: matrix } = useWorkUnitMatrix()

  const fteWu = FTE_BY_BUILDING[building]
  const { isAdmin } = useAuth()
  const [name, setName] = useState("")
  const [addError, setAddError] = useState<string | null>(null)
  const [adding, setAdding] = useState(false)

  async function handleAdd(e: FormEvent) {
    e.preventDefault()
    if (!name.trim()) return
    setAddError(null)
    setAdding(true)
    try {
      await createCollaborator({ name: name.trim(), building, base_capacity: fteWu, default_percentage: 100 })
      setName("")
    } catch (err) {
      setAddError((err as { message?: string })?.message ?? "Erreur inconnue")
    } finally {
      setAdding(false)
    }
  }

  const activeCollaborators = collaborators.filter((c) => c.is_active)

  const dailyData = useMemo(() => {
    return DAYS.map((date) => {
      const capacity = activeCollaborators.reduce((sum, c) => {
        const override = availability.find((a) => a.collaborator_id === c.id && a.date === date)
        const pct = override ? override.percentage : c.default_percentage
        return sum + c.base_capacity * (pct / 100)
      }, 0)
      const taskLoad = tasks
        .filter((t) => t.due_date === date)
        .reduce((sum, t) => sum + calculateWorkUnits(t, matrix), 0)
      const forecast = forecasts.find((f) => f.building === building && f.date === date)?.value ?? 0
      const workload = parseFloat((taskLoad + forecast).toFixed(1))
      const utilPct = capacity > 0 ? Math.round((workload / capacity) * 100) : 0
      return {
        label: formatDate(date),
        fullDate: date,
        capacity: parseFloat(capacity.toFixed(1)),
        workload,
        pct: utilPct,
      }
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [collaborators, availability, tasks, matrix, forecasts, building])

  const todayData = dailyData[0]

  function getAvailPct(collaboratorId: string, date: string): number {
    const collab = collaborators.find((c) => c.id === collaboratorId)
    const override = availability.find((a) => a.collaborator_id === collaboratorId && a.date === date)
    return override ? override.percentage : (collab?.default_percentage ?? 100)
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-lg">Bâtiment {building}</CardTitle>
        {todayData && (
          <div className="text-right">
            <p className={cn("text-3xl font-bold", utilizationColor(todayData.pct))}>{todayData.pct}%</p>
            <p className="text-xs text-muted-foreground">utilisation aujourd'hui</p>
          </div>
        )}
      </CardHeader>

      <CardContent className="space-y-6">
        {/* Chart */}
        <div>
          <p className="mb-2 text-xs font-semibold uppercase text-muted-foreground">
            Capacité vs Charge — 10 jours ouvrés
          </p>
          <div className="h-48">
            <ResponsiveContainer width="100%" height="100%">
              <ComposedChart data={dailyData} margin={{ top: 4, right: 4, bottom: 0, left: -10 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="label" tick={{ fontSize: 10 }} />
                <YAxis tick={{ fontSize: 10 }} unit=" WU" />
                <Tooltip formatter={(v) => `${v} WU`} />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                <Bar dataKey="capacity" name="Capacité" fill="#22c55e" opacity={0.75} radius={[2, 2, 0, 0]} />
                <Line
                  dataKey="workload"
                  name="Charge"
                  stroke="#ef4444"
                  strokeWidth={2}
                  strokeDasharray="5 5"
                  dot={{ r: 3, fill: "#ef4444" }}
                />
              </ComposedChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Grille collaborateurs × jours */}
        <div>
          <p className="mb-2 text-xs font-semibold uppercase text-muted-foreground">
            Présence par collaborateur — {activeCollaborators.length} pers. · FTE = {fteWu} WU/j
          </p>
          <div className="overflow-x-auto rounded border">
            <table className="w-full text-sm">
              <thead className="bg-muted/50 text-left text-xs uppercase text-muted-foreground">
                <tr>
                  <th className="p-2 whitespace-nowrap">Nom</th>
                  {DAYS.map((d) => (
                    <th key={d} className="p-2 text-center whitespace-nowrap font-normal">
                      {formatDate(d)}
                    </th>
                  ))}
                  <th className="p-2" />
                </tr>
              </thead>
              <tbody>
                {activeCollaborators.map((c) => (
                  <tr key={c.id} className="border-t">
                    <td className="p-2 font-medium whitespace-nowrap">{c.name}</td>
                    {DAYS.map((date) => {
                      const pct = getAvailPct(c.id, date)
                      return (
                        <td key={date} className="p-1 text-center">
                          <select
                            value={pct}
                            onChange={(e) => setAvailability(c.id, date, Number(e.target.value))}
                            className={cn(
                              "rounded border px-1 py-0.5 text-xs cursor-pointer appearance-none text-center w-14",
                              availColor(pct)
                            )}
                          >
                            {AVAIL_OPTIONS.map((o) => (
                              <option key={o} value={o}>{o}%</option>
                            ))}
                          </select>
                        </td>
                      )
                    })}
                    <td className="p-1 text-right">
                      {isAdmin && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-6 w-6 p-0 text-muted-foreground hover:text-destructive"
                          onClick={() => deleteCollaborator(c.id)}
                        >
                          ×
                        </Button>
                      )}
                    </td>
                  </tr>
                ))}

                {/* Ligne capacité totale */}
                {activeCollaborators.length > 0 && (
                  <tr className="border-t bg-muted/40 text-xs font-semibold">
                    <td className="p-2">Capacité totale</td>
                    {dailyData.map((d) => (
                      <td key={d.fullDate} className="p-2 text-center">
                        {d.capacity > 0 ? `${d.capacity} WU` : "—"}
                      </td>
                    ))}
                    <td />
                  </tr>
                )}

                {activeCollaborators.length === 0 && (
                  <tr>
                    <td colSpan={DAYS.length + 2} className="p-6 text-center text-muted-foreground">
                      Aucun collaborateur pour ce bâtiment.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Formulaire ajout — admin seulement */}
        {isAdmin && (
          <form onSubmit={handleAdd} className="flex flex-wrap items-end gap-3 border-t pt-4">
            <div className="space-y-1">
              <Label className="text-xs">Nouveau collaborateur</Label>
              <Input
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-48"
                placeholder="Prénom Nom"
                disabled={adding}
              />
            </div>
            <Button type="submit" size="sm" disabled={adding}>
              {adding ? "…" : "+ Ajouter"}
            </Button>
            <span className="text-xs text-muted-foreground">FTE · {fteWu} WU/jour · 100% par défaut</span>
            {addError && (
              <p className="w-full text-xs text-red-500">{addError}</p>
            )}
          </form>
        )}

        {/* Résumé 10 jours */}
        <div>
          <p className="mb-2 text-xs font-semibold uppercase text-muted-foreground">Résumé 10 jours</p>
          <div className="overflow-x-auto rounded border">
            <table className="w-full text-sm">
              <thead className="bg-muted/50 text-left text-xs uppercase text-muted-foreground">
                <tr>
                  <th className="p-2">Date</th>
                  <th className="p-2">Capacité</th>
                  <th className="p-2">Charge</th>
                  <th className="p-2">Utilisation</th>
                </tr>
              </thead>
              <tbody>
                {dailyData.map((d) => (
                  <tr key={d.fullDate} className="border-t">
                    <td className="p-2">{d.fullDate}</td>
                    <td className="p-2">{d.capacity} WU</td>
                    <td className="p-2">{d.workload} WU</td>
                    <td className={cn("p-2 font-semibold", utilizationColor(d.pct))}>{d.pct}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

export default function Capacity() {
  return (
    <div className="p-6">
      <header className="mb-6">
        <h1 className="text-2xl font-bold">Capacity Planning</h1>
        <p className="text-sm text-muted-foreground">
          Présence par jour : 0 / 25 / 50 / 75 / 100% · prévision 10 jours ouvrés
        </p>
      </header>
      <div className="grid gap-6 lg:grid-cols-2">
        <BuildingCapacitySection building="K" />
        <BuildingCapacitySection building="S" />
      </div>
    </div>
  )
}
