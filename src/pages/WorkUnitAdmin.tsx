import { useState, type FormEvent, type KeyboardEvent } from "react"
import { useWorkUnitMatrix } from "@/hooks/useWorkUnitMatrix"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  CARRIER_LABELS,
  DESTINATION_K_LABELS,
  DESTINATION_S_LABELS,
  TASK_TYPE_LABELS,
  UNIT_TYPE_LABELS,
  type CarrierType,
  type DestinationK,
  type DestinationS,
  type TaskType,
  type UnitType,
  type WorkUnitMatrixEntry,
} from "@/types/database"

const TASK_TYPES = Object.keys(TASK_TYPE_LABELS) as TaskType[]
const CARRIERS = Object.keys(CARRIER_LABELS) as CarrierType[]
const UNIT_TYPES = Object.keys(UNIT_TYPE_LABELS) as UnitType[]

export default function WorkUnitAdmin() {
  const { entries, isLoading, createEntry, updateEntry, deleteEntry } = useWorkUnitMatrix()

  const [taskType, setTaskType] = useState<TaskType>(TASK_TYPES[0])
  const [carrier, setCarrier] = useState<CarrierType | "ANY">("ANY")
  const [unitType, setUnitType] = useState<UnitType>("PALLET")
  const [value, setValue] = useState("1")

  const [editingId, setEditingId] = useState<string | null>(null)
  const [editValue, setEditValue] = useState("")

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    await createEntry({
      task_type: taskType,
      carrier: carrier === "ANY" ? null : carrier,
      unit_type: unitType,
      work_unit_value: Number(value),
    })
    setValue("1")
  }

  function startEdit(entry: WorkUnitMatrixEntry) {
    setEditingId(entry.id)
    setEditValue(String(entry.work_unit_value))
  }

  async function commitEdit(id: string) {
    const num = Number(editValue)
    if (!isNaN(num) && num > 0) await updateEntry(id, num)
    setEditingId(null)
  }

  function handleEditKeyDown(e: KeyboardEvent<HTMLInputElement>, id: string) {
    if (e.key === "Enter") commitEdit(id)
    if (e.key === "Escape") setEditingId(null)
  }

  function destinationLabel(entry: WorkUnitMatrixEntry): string {
    if (entry.destination_k) return DESTINATION_K_LABELS[entry.destination_k as DestinationK] ?? entry.destination_k
    if (entry.destination_s) return DESTINATION_S_LABELS[entry.destination_s as DestinationS] ?? entry.destination_s
    return "Any"
  }

  return (
    <div className="p-6">
      <header className="mb-6">
        <h1 className="text-2xl font-bold">Work Unit Matrix</h1>
        <p className="text-sm text-muted-foreground">
          Coefficients used to convert task quantities into work units (WU) for capacity planning. Click a WU value to edit it.
        </p>
      </header>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="text-base">New coefficient</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <div className="space-y-2">
              <Label>Task type</Label>
              <Select value={taskType} onValueChange={(v) => setTaskType(v as TaskType)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {TASK_TYPES.map((t) => (
                    <SelectItem key={t} value={t}>
                      {TASK_TYPE_LABELS[t]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Carrier</Label>
              <Select value={carrier} onValueChange={(v) => setCarrier(v as CarrierType | "ANY")}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ANY">Any</SelectItem>
                  {CARRIERS.map((c) => (
                    <SelectItem key={c} value={c}>
                      {CARRIER_LABELS[c]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Unit type</Label>
              <Select value={unitType} onValueChange={(v) => setUnitType(v as UnitType)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {UNIT_TYPES.map((u) => (
                    <SelectItem key={u} value={u}>
                      {UNIT_TYPE_LABELS[u]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>WU per unit</Label>
              <Input type="number" step="0.1" value={value} onChange={(e) => setValue(e.target.value)} />
            </div>

            <Button type="submit" className="col-span-2 sm:col-span-1">
              Add coefficient
            </Button>
          </form>
        </CardContent>
      </Card>

      {isLoading && <p className="text-muted-foreground">Loading…</p>}

      <div className="overflow-x-auto rounded-lg border">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 text-left text-xs uppercase text-muted-foreground">
            <tr>
              <th className="p-3">Task type</th>
              <th className="p-3">Carrier</th>
              <th className="p-3">Destination</th>
              <th className="p-3">Unit type</th>
              <th className="p-3">WU / unit</th>
              <th className="p-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {entries.map((entry) => (
              <tr key={entry.id} className="border-t">
                <td className="p-3">{TASK_TYPE_LABELS[entry.task_type]}</td>
                <td className="p-3">{entry.carrier ? CARRIER_LABELS[entry.carrier] : "Any"}</td>
                <td className="p-3">{destinationLabel(entry)}</td>
                <td className="p-3">{UNIT_TYPE_LABELS[entry.unit_type]}</td>
                <td className="p-3">
                  {editingId === entry.id ? (
                    <Input
                      type="number"
                      step="0.1"
                      value={editValue}
                      onChange={(e) => setEditValue(e.target.value)}
                      onBlur={() => commitEdit(entry.id)}
                      onKeyDown={(e) => handleEditKeyDown(e, entry.id)}
                      className="w-24"
                      autoFocus
                    />
                  ) : (
                    <button
                      className="rounded px-2 py-0.5 font-medium hover:bg-muted"
                      onClick={() => startEdit(entry)}
                      title="Click to edit"
                    >
                      {entry.work_unit_value}
                    </button>
                  )}
                </td>
                <td className="p-3 text-right">
                  <Button variant="ghost" size="sm" onClick={() => deleteEntry(entry.id)}>
                    Delete
                  </Button>
                </td>
              </tr>
            ))}
            {!isLoading && entries.length === 0 && (
              <tr>
                <td colSpan={6} className="p-6 text-center text-muted-foreground">
                  No coefficients defined yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
