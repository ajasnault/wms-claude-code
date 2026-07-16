import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom"
import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { AuthProvider } from "@/hooks/useAuth"
import { ProtectedRoute } from "@/components/ProtectedRoute"
import { Layout } from "@/components/Layout"
import { useLateDetection } from "@/hooks/useLateDetection"

import Auth from "@/pages/Auth"
import DashboardK from "@/pages/DashboardK"
import DashboardS from "@/pages/DashboardS"
import Backoffice from "@/pages/Backoffice"
import Analytics from "@/pages/Analytics"
import Capacity from "@/pages/Capacity"
import CustomerService from "@/pages/CustomerService"
import WorkUnitAdmin from "@/pages/WorkUnitAdmin"

const queryClient = new QueryClient()

function LateDetectionRunner() {
  useLateDetection()
  return null
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter basename={import.meta.env.BASE_URL}>
          <LateDetectionRunner />
          <Routes>
            <Route path="/" element={<Navigate to="/backoffice" replace />} />
            <Route path="/auth" element={<Auth />} />

            <Route element={<Layout />}>
              <Route path="/dashboard/k" element={<DashboardK />} />
              <Route path="/dashboard/s" element={<DashboardS />} />
              <Route
                path="/backoffice"
                element={
                  <ProtectedRoute>
                    <Backoffice />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/analytics"
                element={
                  <ProtectedRoute>
                    <Analytics />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/capacity"
                element={
                  <ProtectedRoute>
                    <Capacity />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/customer-service"
                element={
                  <ProtectedRoute>
                    <CustomerService />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/admin/work-units"
                element={
                  <ProtectedRoute adminOnly>
                    <WorkUnitAdmin />
                  </ProtectedRoute>
                }
              />
            </Route>
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  )
}
