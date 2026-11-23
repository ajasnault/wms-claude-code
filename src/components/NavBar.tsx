import { useState } from "react"
import { NavLink, useLocation } from "react-router-dom"
import { BarChart3, ClipboardList, Menu, Warehouse } from "lucide-react"
import { Button } from "@/components/ui/button"
import { useAuth } from "@/hooks/useAuth"
import { cn } from "@/lib/utils"

const links = [
  { to: "/backoffice", label: "Backoffice" },
  { to: "/dashboard/pj01", label: "Dashboard PJ01" },
  { to: "/dashboard/fg01", label: "Dashboard FG01" },
  { to: "/analytics", label: "Analytics" },
  { to: "/capacity", label: "Capacity" },
  { to: "/customer-service", label: "Customer Service" },
]

const adminLinks = [{ to: "/admin/work-units", label: "Work Unit Admin" }]

// Phone layout: the most used pages as bottom tabs, the rest behind "More"
const tabs = [
  { to: "/backoffice", label: "Backoffice", icon: ClipboardList },
  { to: "/dashboard/pj01", label: "PJ01", icon: Warehouse },
  { to: "/dashboard/fg01", label: "FG01", icon: Warehouse },
  { to: "/analytics", label: "Analytics", icon: BarChart3 },
]

export function NavBar() {
  const { user, isAdmin, signOut } = useAuth()
  const visibleLinks = isAdmin ? [...links, ...adminLinks] : links
  const moreLinks = visibleLinks.filter((link) => !tabs.some((tab) => tab.to === link.to))
  const [moreOpen, setMoreOpen] = useState(false)
  const { pathname } = useLocation()
  const currentLabel = visibleLinks.find((link) => pathname.startsWith(link.to))?.label
  // Show the role, never the account's e-mail address
  const accountLabel = isAdmin ? "Admin" : "Operator"

  return (
    <>
      <nav className="hidden h-14 items-center justify-between border-b bg-background px-6 md:flex">
        <div className="flex flex-wrap items-center gap-1">
          <span className="mr-4 font-bold">WMS</span>
          {visibleLinks.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              className={({ isActive }) =>
                cn(
                  "rounded-md px-3 py-1.5 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground",
                  isActive && "bg-accent text-accent-foreground"
                )
              }
            >
              {link.label}
            </NavLink>
          ))}
        </div>

        {user && (
          <div className="flex items-center gap-3">
            <span className="text-sm text-muted-foreground">{accountLabel}</span>
            <Button variant="outline" size="sm" onClick={signOut}>
              Sign out
            </Button>
          </div>
        )}
      </nav>

      <header className="flex h-12 items-center gap-2 border-b bg-background px-4 md:hidden">
        <span className="font-bold">WMS</span>
        {currentLabel && <span className="truncate text-sm text-muted-foreground">· {currentLabel}</span>}
      </header>

      {moreOpen && (
        <div className="fixed inset-0 z-40 bg-black/40 md:hidden" onClick={() => setMoreOpen(false)}>
          <div
            className="absolute inset-x-0 bottom-[calc(4rem+env(safe-area-inset-bottom))] rounded-t-xl border-t bg-background p-2"
            onClick={(e) => e.stopPropagation()}
          >
            {moreLinks.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                onClick={() => setMoreOpen(false)}
                className={({ isActive }) =>
                  cn("block rounded-md px-4 py-3 font-medium", isActive && "bg-accent text-accent-foreground")
                }
              >
                {link.label}
              </NavLink>
            ))}
            {user && (
              <div className="mt-2 flex items-center justify-between gap-3 border-t px-4 pt-3 pb-1">
                <span className="truncate text-sm text-muted-foreground">{accountLabel}</span>
                <Button variant="outline" size="sm" onClick={signOut}>
                  Sign out
                </Button>
              </div>
            )}
          </div>
        </div>
      )}

      <nav className="fixed inset-x-0 bottom-0 z-50 flex border-t bg-background pb-[env(safe-area-inset-bottom)] md:hidden">
        {tabs.map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            to={to}
            onClick={() => setMoreOpen(false)}
            className={({ isActive }) =>
              cn(
                "flex h-16 flex-1 flex-col items-center justify-center gap-1 text-xs font-medium text-muted-foreground",
                isActive && "text-primary"
              )
            }
          >
            <Icon className="h-5 w-5" />
            {label}
          </NavLink>
        ))}
        <button
          type="button"
          onClick={() => setMoreOpen((open) => !open)}
          className={cn(
            "flex h-16 flex-1 flex-col items-center justify-center gap-1 text-xs font-medium text-muted-foreground",
            (moreOpen || moreLinks.some((link) => pathname.startsWith(link.to))) && "text-primary"
          )}
        >
          <Menu className="h-5 w-5" />
          More
        </button>
      </nav>
    </>
  )
}
