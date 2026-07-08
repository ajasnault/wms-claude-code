import { NavLink } from "react-router-dom"
import { Button } from "@/components/ui/button"
import { useAuth } from "@/hooks/useAuth"
import { cn } from "@/lib/utils"

const links = [
  { to: "/backoffice", label: "Backoffice" },
  { to: "/dashboard/k", label: "Dashboard K" },
  { to: "/dashboard/s", label: "Dashboard S" },
  { to: "/analytics", label: "Analytics" },
  { to: "/capacity", label: "Capacity" },
  { to: "/customer-service", label: "Customer Service" },
]

const adminLinks = [{ to: "/admin/work-units", label: "Work Unit Admin" }]

export function NavBar() {
  const { user, isAdmin, signOut } = useAuth()
  const visibleLinks = isAdmin ? [...links, ...adminLinks] : links

  return (
    <nav className="flex h-14 items-center justify-between border-b bg-background px-6">
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
          <span className="text-sm text-muted-foreground">{user.email}</span>
          <Button variant="outline" size="sm" onClick={signOut}>
            Sign out
          </Button>
        </div>
      )}
    </nav>
  )
}
