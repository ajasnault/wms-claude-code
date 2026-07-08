import { useEffect } from "react"
import { useForm, Controller } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

import {
  CARRIER_LABELS,
  DESTINATION_K_LABELS,
  DESTINATION_S_LABELS,
  OTHER_SHIPMENT_CATEGORY_LABELS,
  PRIORITY_LABELS,
  TASK_TYPE_LABELS,
  TASK_TYPES_BY_BUILDING,
  TEMPERATURE_GROUP_LABELS,
  type Building,
  type OtherShipmentCategory,
  type Task,
  type TemperatureGroup,
} from "@/types/database"
import { useTaskMutations } from "@/hooks/useTasks"

const schema = z.object({
  building: z.enum(["K", "S"]),
  type: z.string().min(1),
  priority: z.coerce.number().min(1).max(5),
  erp_document_number: z.string().optional(),
  carrier: z.string().optional(),
  destination_k: z.string().optional(),
  destination_s: z.string().optional(),
  due_date: z.string().min(1, "Required"),
  due_time: z.string().optional(),
  bottle_count: z.coerce.number().optional(),
  pallet_count: z.coerce.number().optional(),
  package_count: z.coerce.number().optional(),
  dry_ice_carton_count: z.coerce.number().optional(),
  temperature_group: z.string().optional(),
  other_shipment_category: z.string().optional(),
  notes: z.string().optional(),
})

type FormInput = z.input<typeof schema>
type FormValues = z.output<typeof schema>

export function TaskFormDialog({
  open,
  onOpenChange,
  task,
  defaultBuilding,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  task?: Task
  defaultBuilding: Building
}) {
  const { createTask, updateTask } = useTaskMutations()

  const { register, handleSubmit, watch, control, reset, formState } = useForm<FormInput, unknown, FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      building: defaultBuilding,
      type: TASK_TYPES_BY_BUILDING[defaultBuilding][0],
      priority: 3,
      due_date: new Date().toISOString().slice(0, 10),
    },
  })

  useEffect(() => {
    if (task) {
      reset({
        building: task.building,
        type: task.type,
        priority: task.priority,
        erp_document_number: task.erp_document_number ?? "",
        carrier: task.carrier ?? "",
        destination_k: task.destination_k ?? "",
        destination_s: task.destination_s ?? "",
        due_date: task.due_date,
        due_time: task.due_time ?? "",
        bottle_count: task.bottle_count ?? undefined,
        pallet_count: task.pallet_count ?? undefined,
        package_count: task.package_count ?? undefined,
        dry_ice_carton_count: task.dry_ice_carton_count ?? undefined,
        temperature_group: task.temperature_group ?? "",
        other_shipment_category: task.other_shipment_category ?? "",
        notes: task.notes ?? "",
      })
    } else if (open) {
      reset({
        building: defaultBuilding,
        type: TASK_TYPES_BY_BUILDING[defaultBuilding][0],
        priority: 3,
        due_date: new Date().toISOString().slice(0, 10),
      })
    }
  }, [task, open, defaultBuilding, reset])

  const building = watch("building")

  async function onSubmit(values: FormValues) {
    const payload = {
      ...values,
      carrier: values.carrier || null,
      destination_k: values.destination_k || null,
      destination_s: values.destination_s || null,
      due_time: values.due_time || null,
      erp_document_number: values.erp_document_number || null,
      temperature_group: (values.temperature_group || null) as TemperatureGroup | null,
      other_shipment_category: (values.other_shipment_category || null) as OtherShipmentCategory | null,
      notes: values.notes || null,
    }

    if (task) {
      await updateTask(task.id, payload as never)
    } else {
      await createTask(payload as never)
    }
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{task ? "Edit task" : "New task"}</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Building</Label>
              <Controller
                control={control}
                name="building"
                render={({ field }) => (
                  <Select value={field.value} onValueChange={field.onChange}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="K">K</SelectItem>
                      <SelectItem value="S">S</SelectItem>
                    </SelectContent>
                  </Select>
                )}
              />
            </div>

            <div className="space-y-2">
              <Label>Type</Label>
              <Controller
                control={control}
                name="type"
                render={({ field }) => (
                  <Select value={field.value} onValueChange={field.onChange}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {TASK_TYPES_BY_BUILDING[building].map((t) => (
                        <SelectItem key={t} value={t}>
                          {TASK_TYPE_LABELS[t]}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Priority</Label>
              <Controller
                control={control}
                name="priority"
                render={({ field }) => (
                  <Select value={String(field.value)} onValueChange={(v) => field.onChange(Number(v))}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {Object.entries(PRIORITY_LABELS).map(([value, label]) => (
                        <SelectItem key={value} value={value}>
                          {value} — {label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
              />
            </div>

            <div className="space-y-2">
              <Label>Carrier</Label>
              <Controller
                control={control}
                name="carrier"
                render={({ field }) => (
                  <Select value={field.value || undefined} onValueChange={field.onChange}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select carrier" />
                    </SelectTrigger>
                    <SelectContent>
                      {Object.entries(CARRIER_LABELS).map(([value, label]) => (
                        <SelectItem key={value} value={value}>
                          {label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label>Destination</Label>
            <Controller
              control={control}
              name={building === "K" ? "destination_k" : "destination_s"}
              render={({ field }) => (
                <Select value={field.value || undefined} onValueChange={field.onChange}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select destination" />
                  </SelectTrigger>
                  <SelectContent>
                    {Object.entries(building === "K" ? DESTINATION_K_LABELS : DESTINATION_S_LABELS).map(
                      ([value, label]) => (
                        <SelectItem key={value} value={value}>
                          {label}
                        </SelectItem>
                      )
                    )}
                  </SelectContent>
                </Select>
              )}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Due date</Label>
              <Input type="date" {...register("due_date")} />
            </div>
            <div className="space-y-2">
              <Label>Due time</Label>
              <Input type="time" {...register("due_time")} />
            </div>
          </div>

          <div className="space-y-2">
            <Label>ERP document number</Label>
            <Input {...register("erp_document_number")} />
          </div>

          <div className="grid grid-cols-2 gap-4">
            {building === "K" ? (
              <>
                <div className="space-y-2">
                  <Label>Bottle count</Label>
                  <Input type="number" {...register("bottle_count")} />
                </div>
                <div className="space-y-2">
                  <Label>Dry-ice cartons</Label>
                  <Input type="number" {...register("dry_ice_carton_count")} />
                </div>
              </>
            ) : (
              <div className="space-y-2">
                <Label>Pallet count</Label>
                <Input type="number" {...register("pallet_count")} />
              </div>
            )}
          </div>

          {watch("type") === "ERP_DOCUMENT" && (
            <div className="space-y-2">
              <Label>Temperature group</Label>
              <Controller
                control={control}
                name="temperature_group"
                render={({ field }) => (
                  <Select value={field.value || undefined} onValueChange={field.onChange}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select temperature group" />
                    </SelectTrigger>
                    <SelectContent>
                      {Object.entries(TEMPERATURE_GROUP_LABELS).map(([value, label]) => (
                        <SelectItem key={value} value={value}>{label}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
              />
            </div>
          )}

          {watch("type") === "OTHER_SHIPMENTS" && (
            <div className="space-y-2">
              <Label>Shipment category</Label>
              <Controller
                control={control}
                name="other_shipment_category"
                render={({ field }) => (
                  <Select value={field.value || undefined} onValueChange={field.onChange}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select category" />
                    </SelectTrigger>
                    <SelectContent>
                      {Object.entries(OTHER_SHIPMENT_CATEGORY_LABELS).map(([value, label]) => (
                        <SelectItem key={value} value={value}>{label}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
              />
            </div>
          )}

          <div className="space-y-2">
            <Label>Notes</Label>
            <Input {...register("notes")} />
          </div>

          <DialogFooter>
            <Button type="submit" disabled={formState.isSubmitting}>
              {task ? "Save changes" : "Create task"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
