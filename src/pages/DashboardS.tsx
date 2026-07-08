import { useTasks } from "@/hooks/useTasks"
import { filterVisibleForDashboard, groupTasksByDate, groupTasksByDestination, linkPrepDryIce } from "@/lib/taskGrouping"
import { DashboardLayout } from "@/components/dashboard/DashboardLayout"
import { DestinationSection } from "@/components/dashboard/DestinationSection"

export default function DashboardS() {
  const { tasks: allTasks, isLoading } = useTasks("S")
  const tasks = filterVisibleForDashboard(allTasks)
  const { main, childrenByParent } = linkPrepDryIce(tasks)
  const dateGroups = groupTasksByDate(main)

  const palletCount = tasks.reduce((sum, t) => sum + (t.pallet_count ?? 0), 0)

  return (
    <DashboardLayout
      building="S"
      flowLabel="Commercial flows"
      stats={`${tasks.length} tasks · ${palletCount} pallets`}
      otherBuilding="K"
    >
      {isLoading && <p className="text-muted-foreground">Loading…</p>}

      <div className="space-y-8">
        {dateGroups.map((dateGroup) => (
          <div key={dateGroup.date} className="space-y-4">
            <h2 className="border-b border-border pb-1 text-lg font-bold">{dateGroup.date}</h2>
            <div className="space-y-6">
              {groupTasksByDestination(dateGroup.tasks, "S").map((group) => (
                <DestinationSection key={group.label} group={group} childrenByParent={childrenByParent} />
              ))}
            </div>
          </div>
        ))}
        {!isLoading && dateGroups.length === 0 && (
          <p className="text-muted-foreground">No tasks yet. Create one from the Backoffice.</p>
        )}
      </div>
    </DashboardLayout>
  )
}
