import { Navigate } from "react-router-dom"
import type { ReactNode } from "react"
import { useAuth } from "@/hooks/useAuth"

export function ProtectedRoute({
  children,
  adminOnly = false,
}: {
  children: ReactNode
  adminOnly?: boolean
}) {
  const { user, isAdmin, loading } = useAuth()

  if (loading) {
    return <div className="flex h-screen items-center justify-center text-muted-foreground">Loading...</div>
  }

  if (!user) {
    return <Navigate to="/auth" replace />
  }

  if (adminOnly && !isAdmin) {
    return <Navigate to="/" replace />
  }

  return <>{children}</>
}
