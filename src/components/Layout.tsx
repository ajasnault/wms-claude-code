import { Outlet } from "react-router-dom"
import { NavBar } from "@/components/NavBar"

export function Layout() {
  return (
    <div className="min-h-screen bg-background pb-[calc(4rem+env(safe-area-inset-bottom))] md:pb-0">
      <NavBar />
      <Outlet />
    </div>
  )
}
