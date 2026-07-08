import { useEffect, useId } from "react"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { supabase } from "@/integrations/supabase/client"
import type { Building, Task, TaskStatus } from "@/types/database"
import { useAuth } from "@/hooks/useAuth"

const TASKS_KEY = ["tasks"] as const

const PAGE_SIZE = 1000 // Supabase project enforces this as a hard server-side max-rows cap

async function fetchTasks(): Promise<Task[]> {
  const pages: Task[] = []
  let from = 0

  while (true) {
    const { data, error } = await supabase
      .from("tasks")
      .select("*")
      .order("due_date", { ascending: true })
      .order("due_time", { ascending: true })
      .range(from, from + PAGE_SIZE - 1)

    if (error) throw error
    pages.push(...(data as Task[]))
    if (!data || data.length < PAGE_SIZE) break
    from += PAGE_SIZE
  }

  return pages
}

export function useTasks(building?: Building) {
  const queryClient = useQueryClient()
  const instanceId = useId()

  const query = useQuery({
    queryKey: TASKS_KEY,
    queryFn: fetchTasks,
    staleTime: 30_000,
  })

  useEffect(() => {
    const channel = supabase
      .channel(`tasks-realtime-${instanceId}`)
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "tasks" },
        (payload) => {
          queryClient.setQueryData<Task[]>(TASKS_KEY, (current) => {
            if (!current) return current
            if (payload.eventType === "INSERT") {
              const newTask = payload.new as Task
              if (current.some((t) => t.id === newTask.id)) return current
              return [...current, newTask]
            }
            if (payload.eventType === "UPDATE") {
              const updated = payload.new as Task
              return current.map((t) => (t.id === updated.id ? updated : t))
            }
            if (payload.eventType === "DELETE") {
              const deletedId = (payload.old as Task).id
              return current.filter((t) => t.id !== deletedId)
            }
            return current
          })
        }
      )
      .subscribe()

    function onVisible() {
      if (document.visibilityState === "visible") {
        queryClient.invalidateQueries({ queryKey: TASKS_KEY })
      }
    }
    document.addEventListener("visibilitychange", onVisible)

    return () => {
      supabase.removeChannel(channel)
      document.removeEventListener("visibilitychange", onVisible)
    }
  }, [queryClient, instanceId])

  const tasks = building ? (query.data ?? []).filter((t) => t.building === building) : query.data ?? []

  return { ...query, tasks }
}

export function useTaskMutations() {
  const queryClient = useQueryClient()
  const { user } = useAuth()

  async function createTask(input: Partial<Task>) {
    const { data, error } = await supabase
      .from("tasks")
      .insert({ ...input, created_by: user?.id })
      .select()
      .single()
    if (error) throw error

    queryClient.setQueryData<Task[]>(TASKS_KEY, (current) => (current ? [...current, data as Task] : current))
    return data as Task
  }

  async function updateTask(id: string, patch: Partial<Task>) {
    queryClient.setQueryData<Task[]>(TASKS_KEY, (current) =>
      current?.map((t) => (t.id === id ? { ...t, ...patch } : t))
    )

    const { data, error } = await supabase.from("tasks").update(patch).eq("id", id).select().single()
    if (error) {
      queryClient.invalidateQueries({ queryKey: TASKS_KEY })
      throw error
    }
    return data as Task
  }

  async function setStatus(id: string, status: TaskStatus) {
    const patch: Partial<Task> = { status }
    if (status === "DONE") patch.completed_at = new Date().toISOString()
    return updateTask(id, patch)
  }

  async function deleteTask(id: string) {
    queryClient.setQueryData<Task[]>(TASKS_KEY, (current) => current?.filter((t) => t.id !== id))
    const { error } = await supabase.from("tasks").delete().eq("id", id)
    if (error) {
      queryClient.invalidateQueries({ queryKey: TASKS_KEY })
      throw error
    }
  }

  return { createTask, updateTask, setStatus, deleteTask }
}
