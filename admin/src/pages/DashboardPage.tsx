import { useQuery } from '@tanstack/react-query'
import {
  Package, Tag, Briefcase, Plus, RefreshCw,
  Clock, ClipboardList, CheckCircle, TrendingUp,
} from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts'
import { getDashboardStats } from '../services/api'
import type { DashboardStats } from '../types'

export function DashboardPage() {
  const { data: stats, isLoading } = useQuery<DashboardStats>({
    queryKey: ['dashboard-stats'],
    queryFn: getDashboardStats,
    refetchInterval: 60_000,
  })

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw size={24} className="animate-spin text-brand-500" />
      </div>
    )
  }

  const s = stats!

  const chartData = [
    { name: 'Total',     value: s.totalProducts,   color: '#2ECC71' },
    { name: 'Verified',  value: s.verifiedProducts, color: '#3498DB' },
    { name: 'Added (mo)',value: s.addedThisMonth,   color: '#F39C12' },
    { name: 'Updated (mo)',value: s.updatedThisMonth,color: '#9B59B6' },
  ]

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-sm text-gray-500 mt-1">FitNGo data overview</p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-4 gap-5">
        <StatCard icon={<Package size={22} />} label="Products" value={s.totalProducts} color="green" />
        <StatCard icon={<Tag size={22} />} label="Categories" value={s.totalCategories} color="blue" />
        <StatCard icon={<Briefcase size={22} />} label="Brands" value={s.totalBrands} color="purple" />
        <StatCard icon={<CheckCircle size={22} />} label="Verified" value={s.verifiedProducts} color="teal" />
      </div>

      {/* Action items */}
      <div className="grid grid-cols-3 gap-5">
        <AlertCard
          icon={<Clock size={18} />}
          label="Pending Review"
          value={s.pendingReview}
          action="Review now →"
          href="/products?status=under_review"
          color="yellow"
        />
        <AlertCard
          icon={<ClipboardList size={18} />}
          label="User Requests"
          value={s.pendingRequests}
          action="View requests →"
          href="/requests"
          color="orange"
        />
        <AlertCard
          icon={<TrendingUp size={18} />}
          label="Added This Month"
          value={s.addedThisMonth}
          color="green"
        />
      </div>

      {/* Chart */}
      <div className="card p-6">
        <h2 className="font-semibold text-gray-900 mb-4">Product Overview</h2>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={chartData} barSize={40}>
            <XAxis dataKey="name" tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
            <Tooltip
              formatter={(v) => [v, '']}
              contentStyle={{ borderRadius: 8, border: '1px solid #E9ECEF', fontSize: 13 }}
            />
            <Bar dataKey="value" radius={[6, 6, 0, 0]}>
              {chartData.map((entry, i) => (
                <Cell key={i} fill={entry.color} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Quick actions */}
      <div className="card p-6">
        <h2 className="font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div className="flex flex-wrap gap-3">
          <a href="/products/new" className="btn-primary">
            <Plus size={16} /> Add Product
          </a>
          <a href="/categories/new" className="btn-secondary">
            <Plus size={16} /> Add Category
          </a>
          <a href="/brands/new" className="btn-secondary">
            <Plus size={16} /> Add Brand
          </a>
          <a href="/products/import" className="btn-secondary">
            <RefreshCw size={16} /> CSV Import
          </a>
        </div>
      </div>
    </div>
  )
}

function StatCard({
  icon, label, value, color,
}: {
  icon: React.ReactNode; label: string; value: number
  color: 'green' | 'blue' | 'purple' | 'teal'
}) {
  const styles = {
    green:  { bg: 'bg-green-50',  icon: 'bg-green-100 text-green-600' },
    blue:   { bg: 'bg-blue-50',   icon: 'bg-blue-100 text-blue-600' },
    purple: { bg: 'bg-purple-50', icon: 'bg-purple-100 text-purple-600' },
    teal:   { bg: 'bg-teal-50',   icon: 'bg-teal-100 text-teal-600' },
  }
  const s = styles[color]
  return (
    <div className={`card p-5 flex items-center gap-4 ${s.bg} border-0`}>
      <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${s.icon}`}>
        {icon}
      </div>
      <div>
        <div className="text-2xl font-bold text-gray-900">{value.toLocaleString()}</div>
        <div className="text-sm text-gray-500">{label}</div>
      </div>
    </div>
  )
}

function AlertCard({
  icon, label, value, action, href, color,
}: {
  icon: React.ReactNode; label: string; value: number
  action?: string; href?: string
  color: 'yellow' | 'orange' | 'green'
}) {
  const styles = {
    yellow: 'bg-yellow-50 border-yellow-200',
    orange: 'bg-orange-50 border-orange-200',
    green:  'bg-green-50 border-green-200',
  }
  return (
    <div className={`rounded-xl border p-5 ${styles[color]}`}>
      <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
        {icon}
        {label}
      </div>
      <div className="text-3xl font-bold text-gray-900">{value}</div>
      {action && href && (
        <a href={href} className="text-sm text-brand-600 hover:underline mt-2 block">
          {action}
        </a>
      )}
    </div>
  )
}
