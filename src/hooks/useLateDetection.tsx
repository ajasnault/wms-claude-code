import { useEffect } from "react"
import { supabase } from "@/integrations/supabase/client"

/**
 * Client-side equivalent of the Lovable `check-late-tasks` cron edge function.
 * Runs once on mount, then every minute, while the app is open.
 * A production deployment should move this to a scheduled Supabase Edge
 * Function so detection doesn't depend on a browser tab being open.
 */
export function useLateDetection() {
  useEffect(() => {
    async function checkLateTasks() {
      const now = new Date()
      const today = now.toISOString().slice(0, 10)
      const time = now.toISOString().slice(11, 19)

      await supabase
        .from("tasks")
        .update({ status: "LATE" })
        .in("status", ["NEW", "IN_PROGRESS"])
        .neq("type", "PREP_DRY_ICE")
        .or(`due_date.lt.${today},and(due_date.eq.${today},due_time.lt.${time})`)
    }

    checkLateTasks()
    const interval = setInterval(checkLateTasks, 60_000)
    return () => clearInterval(interval)
  }, [])
}
