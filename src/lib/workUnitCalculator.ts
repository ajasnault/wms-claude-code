import type { Task, WorkUnitMatrixEntry } from "@/types/database"

function quantityForUnitType(task: Task, unitType: string): number {
  switch (unitType) {
    case "BOTTLE":  return task.bottle_count ?? 0
    case "PALLET":  return task.pallet_count ?? 0
    case "PACKAGE": return task.package_count ?? 0
    case "CARTON":  return task.dry_ice_carton_count ?? 0
    case "FIXED":   return 1
    default:        return 0
  }
}

function specificity(e: WorkUnitMatrixEntry): number {
  let score = 0
  if (e.carrier !== null) score++
  if (e.destination_k !== null || e.destination_s !== null) score++
  if (e.temperature_group !== null) score++
  if (e.other_shipment_category !== null) score++
  return score
}

function matchesTask(e: WorkUnitMatrixEntry, task: Task): boolean {
  if (e.task_type !== task.type) return false
  if (e.carrier !== null && e.carrier !== task.carrier) return false
  const destination = task.building === "K" ? task.destination_k : task.destination_s
  if (task.building === "K" && e.destination_k !== null && e.destination_k !== destination) return false
  if (task.building === "S" && e.destination_s !== null && e.destination_s !== destination) return false
  if (e.temperature_group !== null && e.temperature_group !== task.temperature_group) return false
  if (e.other_shipment_category !== null && e.other_shipment_category !== task.other_shipment_category) return false
  return true
}

export function calculateWorkUnits(task: Task, matrix: WorkUnitMatrixEntry[]): number {
  const candidates = matrix.filter((e) => matchesTask(e, task))
  if (candidates.length === 0) return 0

  // Among the most specific matches, several entries can tie on specificity
  // while differing in unit_type (e.g. one expects pallet_count, another
  // package_count). Prefer whichever one the task actually has data for,
  // instead of an arbitrary array-order pick that can land on an entry
  // whose quantity field is empty even though the task's real data would
  // match a tied entry.
  const topSpecificity = Math.max(...candidates.map(specificity))
  const topCandidates = candidates.filter((e) => specificity(e) === topSpecificity)
  const entry = topCandidates.find((e) => quantityForUnitType(task, e.unit_type) > 0) ?? topCandidates[0]

  return entry.work_unit_value * quantityForUnitType(task, entry.unit_type)
}
