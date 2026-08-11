import { Outlet } from 'react-router-dom'
import { Sidebar } from './Sidebar'

export function AdminLayout() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Sidebar />
      <div className="ml-60">
        <main className="p-8">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
