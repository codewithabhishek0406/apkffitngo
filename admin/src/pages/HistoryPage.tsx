import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { ArrowRight } from 'lucide-react'
import { supabase } from '../services/supabase'
import type { ProductChangeHistory } from '../types'

export function HistoryPage() {
  const [productId, setProductId] = useState('')

  const { data: history = [], isLoading } = useQuery({
    queryKey: ['global-history', productId],
    queryFn: async () => {
      let query = supabase
        .from('product_change_history')
        .select('*')
        .order('changed_at', { ascending: false })
        .limit(100)

      if (productId.trim()) {
        query = query.eq('product_id', productId.trim())
      }

      const { data, error } = await query
      if (error) throw error
      return data as ProductChangeHistory[]
    },
  })

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Change History</h1>
        <p className="text-sm text-gray-500 mt-0.5">
          Audit log of all product edits
        </p>
      </div>

      <input
        className="input max-w-sm"
        placeholder="Filter by Product ID (optional)..."
        value={productId}
        onChange={(e) => setProductId(e.target.value)}
      />

      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Product ID</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Field</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Old Value</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 w-6"></th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">New Value</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Changed By</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">When</th>
            </tr>
          </thead>
          <tbody>
            {isLoading
              ? Array.from({ length: 8 }).map((_, i) => (
                  <tr key={i} className="border-b border-gray-100 animate-pulse">
                    {Array.from({ length: 7 }).map((_, j) => (
                      <td key={j} className="px-4 py-3">
                        <div className="h-4 bg-gray-100 rounded w-20" />
                      </td>
                    ))}
                  </tr>
                ))
              : history.map((h) => (
                  <tr key={h.id} className="border-b border-gray-100 hover:bg-gray-50 text-xs">
                    <td className="px-4 py-3 font-mono text-gray-400 truncate max-w-[120px]">
                      {h.product_id}
                    </td>
                    <td className="px-4 py-3 font-medium text-gray-700">
                      {h.field_changed}
                    </td>
                    <td className="px-4 py-3 text-red-500 line-through max-w-[160px] truncate">
                      {h.old_value ?? '—'}
                    </td>
                    <td className="px-4 py-2 text-gray-400">
                      <ArrowRight size={12} />
                    </td>
                    <td className="px-4 py-3 text-green-600 max-w-[160px] truncate">
                      {h.new_value ?? '—'}
                    </td>
                    <td className="px-4 py-3 text-gray-500">
                      {h.changed_by ?? 'Admin'}
                    </td>
                    <td className="px-4 py-3 text-gray-400 whitespace-nowrap">
                      {new Date(h.changed_at).toLocaleString()}
                    </td>
                  </tr>
                ))}
          </tbody>
        </table>
        {!isLoading && history.length === 0 && (
          <div className="text-center py-12 text-gray-400">
            <p>No history found</p>
          </div>
        )}
      </div>
    </div>
  )
}
