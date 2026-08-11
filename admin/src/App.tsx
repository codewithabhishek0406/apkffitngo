import { useEffect, useState } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import type { Session } from '@supabase/supabase-js'
import { supabase } from './services/supabase'
import { AdminLayout } from './components/layout/AdminLayout'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'
import { ProductsPage } from './pages/ProductsPage'
import { ProductEditPage } from './pages/ProductEditPage'
import { CategoriesPage } from './pages/CategoriesPage'
import { BrandsPage } from './pages/BrandsPage'
import { RequestsPage } from './pages/RequestsPage'
import { HistoryPage } from './pages/HistoryPage'

function AuthGuard({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null | undefined>(undefined)

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setSession(data.session))
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_, s) =>
      setSession(s),
    )
    return () => subscription.unsubscribe()
  }, [])

  if (session === undefined) {
    // Loading state — wait for Supabase to restore session
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-brand-500 border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  if (!session) return <Navigate to="/login" replace />
  return <>{children}</>
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          element={
            <AuthGuard>
              <AdminLayout />
            </AuthGuard>
          }
        >
          <Route index element={<DashboardPage />} />
          <Route path="products" element={<ProductsPage />} />
          <Route path="products/:id" element={<ProductEditPage />} />
          <Route path="categories" element={<CategoriesPage />} />
          <Route path="brands" element={<BrandsPage />} />
          <Route path="requests" element={<RequestsPage />} />
          <Route path="history" element={<HistoryPage />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
