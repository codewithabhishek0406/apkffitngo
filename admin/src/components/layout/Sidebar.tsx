import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard, Package, Tag, Briefcase, ClipboardList,
  History, LogOut, Flame,
} from 'lucide-react'
import { supabase } from '../../services/supabase'

const NAV = [
  { to: '/',          icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/products',  icon: Package,         label: 'Products' },
  { to: '/categories',icon: Tag,             label: 'Categories' },
  { to: '/brands',    icon: Briefcase,       label: 'Brands' },
  { to: '/requests',  icon: ClipboardList,   label: 'Requests' },
  { to: '/history',   icon: History,         label: 'Change History' },
]

export function Sidebar() {
  const handleLogout = async () => {
    await supabase.auth.signOut()
    window.location.href = '/login'
  }

  return (
    <aside className="fixed inset-y-0 left-0 w-60 bg-gray-900 text-white flex flex-col z-40">
      {/* Logo */}
      <div className="flex items-center gap-3 px-5 py-5 border-b border-gray-800">
        <div className="w-8 h-8 bg-brand-500 rounded-lg flex items-center justify-center">
          <Flame size={18} className="text-white" />
        </div>
        <div>
          <div className="font-bold text-base leading-tight">FitNGo</div>
          <div className="text-xs text-gray-400 leading-tight">Admin Panel</div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
        {NAV.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-brand-600 text-white'
                  : 'text-gray-400 hover:bg-gray-800 hover:text-white'
              }`
            }
          >
            <Icon size={18} />
            {label}
          </NavLink>
        ))}
      </nav>

      {/* Logout */}
      <div className="px-3 py-4 border-t border-gray-800">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm
                     font-medium text-gray-400 hover:bg-gray-800 hover:text-white
                     transition-colors w-full"
        >
          <LogOut size={18} />
          Sign out
        </button>
      </div>
    </aside>
  )
}
