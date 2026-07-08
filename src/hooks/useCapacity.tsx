import { useQuery, useQueryClient } from "@tanstack/react-query"
import { supabase } from "@/integrations/supabase/client"
import type { Building, CapacityForecast, Collaborator, CollaboratorAvailability } from "@/types/database"

const COLLABORATORS_KEY = ["collaborators"] as const
const AVAILABILITY_KEY = ["collaborator-availability"] as const
const FORECASTS_KEY = ["capacity-forecasts"] as const

export function useCollaborators(building: Building) {
  const queryClient = useQueryClient()

  const query = useQuery({
    queryKey: COLLABORATORS_KEY,
    queryFn: async (): Promise<Collaborator[]> => {
      const { data, error } = await supabase.from("collaborators").select("*").order("name")
      if (error) throw error
      return data as Collaborator[]
    },
  })

  async function createCollaborator(input: Partial<Collaborator>) {
    const { error } = await supabase.from("collaborators").insert(input)
    if (error) throw error
    queryClient.invalidateQueries({ queryKey: COLLABORATORS_KEY })
  }

  async function deleteCollaborator(id: string) {
    const { error } = await supabase.from("collaborators").delete().eq("id", id)
    if (error) throw error
    queryClient.invalidateQueries({ queryKey: COLLABORATORS_KEY })
  }

  const collaborators = (query.data ?? []).filter((c) => c.building === building)

  return { ...query, collaborators, createCollaborator, deleteCollaborator }
}

export function useCollaboratorAvailability() {
  const queryClient = useQueryClient()

  const query = useQuery({
    queryKey: AVAILABILITY_KEY,
    queryFn: async (): Promise<CollaboratorAvailability[]> => {
      const { data, error } = await supabase.from("collaborator_availability").select("*")
      if (error) throw error
      return data as CollaboratorAvailability[]
    },
  })

  async function setAvailability(collaboratorId: string, date: string, percentage: number) {
    const { error } = await supabase
      .from("collaborator_availability")
      .upsert({ collaborator_id: collaboratorId, date, percentage }, { onConflict: "collaborator_id,date" })
    if (error) throw error
    queryClient.invalidateQueries({ queryKey: AVAILABILITY_KEY })
  }

  return { ...query, availability: query.data ?? [], setAvailability }
}

export function useCapacityForecasts() {
  const queryClient = useQueryClient()

  const query = useQuery({
    queryKey: FORECASTS_KEY,
    queryFn: async (): Promise<CapacityForecast[]> => {
      const { data, error } = await supabase.from("capacity_forecasts").select("*")
      if (error) throw error
      return data as CapacityForecast[]
    },
  })

  async function setForecast(building: Building, date: string, value: number) {
    const { error } = await supabase
      .from("capacity_forecasts")
      .upsert({ building, date, value }, { onConflict: "building,date" })
    if (error) throw error
    queryClient.invalidateQueries({ queryKey: FORECASTS_KEY })
  }

  return { ...query, forecasts: query.data ?? [], setForecast }
}
