import { useTasks } from "@/hooks/useTasks"
import { useCollaboratorAvailability, useCollaborators, useCapacityForecasts } from "@/hooks/useCapacity"
import { useWorkUnitMatrix } from "@/hooks/useWorkUnitMatrix"
import { calculateWorkUnits } from "@/lib/workUnitCalculator"
import { nextWorkingDays } from "@/lib/workingDays"
import type { Building } from "@/types/database"

export function useCapacityUtilization(building: Building): { today: number; tomorrow: number } {
  const { tasks } = useTasks(building)
  const { collaborators } = useCollaborators(building)
  const { availability } = useCollaboratorAvailability()
  const { forecasts } = useCapacityForecasts()
  const { entries: matrix } = useWorkUnitMatrix()

  const [today, tomorrow] = nextWorkingDays(2)

  function utilizationFor(date: string): number {
    const capacity = collaborators.reduce((sum, c) => {
      if (!c.is_active) return sum
      const override = availability.find((a) => a.collaborator_id === c.id && a.date === date)
      const pct = override ? override.percentage : c.default_percentage
      return sum + c.base_capacity * (pct / 100)
    }, 0)

    const taskLoad = tasks
      .filter((t) => t.due_date === date)
      .reduce((sum, t) => sum + calculateWorkUnits(t, matrix), 0)
    const forecast = forecasts.find((f) => f.building === building && f.date === date)?.value ?? 0
    const workload = taskLoad + forecast

    return capacity > 0 ? Math.round((workload / capacity) * 100) : 0
  }

  return { today: utilizationFor(today), tomorrow: utilizationFor(tomorrow) }
}
