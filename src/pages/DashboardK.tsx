import { useTasks } from "@/hooks/useTasks"
import { filterVisibleForDashboard, groupTasksByDate, groupTasksByDestination, linkPrepDryIce } from "@/lib/taskGrouping"
import { DashboardLayout } from "@/components/dashboard/DashboardLayout"
import { DestinationSection } from "@/components/dashboard/DestinationSection"

export default function DashboardK() {
  const { tasks: allTasks, isLoading } = useTasks("K")
  const tasks = filterVisibleForDashboard(allTasks)
  const { main, childrenByParent } = linkPrepDryIce(tasks)
  const dateGroups = groupTasksByDate(main)

  const bottleCount = tasks.reduce((sum, t) => sum + (t.bottle_count ?? 0), 0)
  const dryIceCartons = tasks.reduce((sum, t) => sum + (t.dry_ice_carton_count ?? 0), 0)

  return (
    <DashboardLayout
      building="K"
      flowLabel="Non-commercial flows"
      stats={`${tasks.length} tasks · ${bottleCount} bottles · ${dryIceCartons} dry-ice cartons`}
      otherBuilding="S"
    >
      {isLoading && <p className="text-muted-foreground">Loading…</p>}

      <div className="space-y-8">
        {dateGroups.map((dateGroup) => (
          <div key={dateGroup.date} className="space-y-4">
            <h2 className="border-b border-border pb-1 text-lg font-bold">{dateGroup.date}</h2>
            <div className="space-y-6">
              {groupTasksByDestination(dateGroup.tasks, "K").map((group) => (
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
