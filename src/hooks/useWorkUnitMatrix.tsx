import { useQuery, useQueryClient } from "@tanstack/react-query"
import { supabase } from "@/integrations/supabase/client"
import type { WorkUnitMatrixEntry } from "@/types/database"

const KEY = ["work-unit-matrix"] as const

async function fetchMatrix(): Promise<WorkUnitMatrixEntry[]> {
  const { data, error } = await supabase
    .from("work_unit_matrix")
    .select("*")
    .order("task_type", { ascending: true })
  if (error) throw error
  return data as WorkUnitMatrixEntry[]
}

export function useWorkUnitMatrix() {
  const queryClient = useQueryClient()
  const query = useQuery({ queryKey: KEY, queryFn: fetchMatrix })

  async function createEntry(input: Partial<WorkUnitMatrixEntry>) {
    const { error } = await supabase.from("work_unit_matrix").insert(input)
    if (error) throw error
    queryClient.invalidateQueries({ queryKey: KEY })
  }

  async function updateEntry(id: string, workUnitValue: number) {
    const { error } = await supabase
      .from("work_unit_matrix")
      .update({ work_unit_value: workUnitValue })
      .eq("id", id)
    if (error) throw error
    queryClient.invalidateQueries({ queryKey: KEY })
  }

  async function deleteEntry(id: string) {
    const { error } = await supabase.from("work_unit_matrix").delete().eq("id", id)
    if (error) throw error
    queryClient.invalidateQueries({ queryKey: KEY })
  }

  return { ...query, entries: query.data ?? [], createEntry, updateEntry, deleteEntry }
}
