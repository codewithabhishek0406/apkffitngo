import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { CheckCircle, XCircle, Eye, Clock } from 'lucide-react'
import toast from 'react-hot-toast'
import { getProductRequests, updateRequestStatus } from '../services/api'
import type { ProductRequest, RequestStatus } from '../types'

const STATUS_TABS: { value: string; label: string }[] = [
  { value: '', label: 'All' },
  { value: 'pending', label: 'Pending' },
  { value: 'in_review', label: 'In Review' },
  { value: 'fulfilled', label: 'Fulfilled' },
  { value: 'rejected', label: 'Rejected' },
]

const STATUS_BADGE: Record<RequestStatus, string> = {
  pending:    'bg-yellow-100 text-yellow-700',
  in_review:  'bg-blue-100 text-blue-700',
  fulfilled:  'bg-green-100 text-green-700',
  rejected:   'bg-red-100 text-red-700',
}

export function RequestsPage() {
  const [statusFilter, setStatusFilter] = useState('')
  const [selected, setSelected] = useState<ProductRequest | null>(null)
  const qc = useQueryClient()

  const { data: requests = [], isLoading } = useQuery({
    queryKey: ['product-requests', statusFilter],
    queryFn: () => getProductRequests(statusFilter || undefined),
  })

  const updateMut = useMutation({
    mutationFn: ({
      id,
      status,
    }: {
      id: string
      status: string
    }) => updateRequestStatus(id, status, 'admin'),
    onSuccess: () => {
      toast.success('Status updated')
      qc.invalidateQueries({ queryKey: ['product-requests'] })
      setSelected(null)
    },
    onError: () => toast.error('Update failed'),
  })

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Product Requests</h1>
        <p className="text-sm text-gray-500 mt-0.5">
          User-submitted product requests
        </p>
      </div>

      {/* Status tabs */}
      <div className="flex gap-1 bg-gray-100 rounded-xl p-1 w-fit">
        {STATUS_TABS.map((tab) => (
          <button
            key={tab.value}
            onClick={() => setStatusFilter(tab.value)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              statusFilter === tab.value
                ? 'bg-white shadow-sm text-gray-900'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Product Name</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Brand</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Barcode</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Status</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Submitted</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {isLoading
              ? Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="border-b border-gray-100 animate-pulse">
                    {Array.from({ length: 6 }).map((_, j) => (
                      <td key={j} className="px-4 py-3">
                        <div className="h-4 bg-gray-100 rounded w-24" />
                      </td>
                    ))}
                  </tr>
                ))
              : requests.map((req) => (
                  <tr key={req.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="px-4 py-3 font-medium text-gray-900">
                      {req.product_name}
                    </td>
                    <td className="px-4 py-3 text-gray-600">{req.brand ?? '—'}</td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">
                      {req.barcode ?? '—'}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
                          STATUS_BADGE[req.status]
                        }`}
                      >
                        <Clock size={10} />
                        {req.status.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-400 text-xs">
                      {new Date(req.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2 justify-end">
                        <button
                          className="p-1.5 hover:bg-gray-100 rounded-lg"
                          onClick={() => setSelected(req)}
                          title="Review"
                        >
                          <Eye size={15} className="text-gray-500" />
                        </button>
                        {req.status === 'pending' && (
                          <>
                            <button
                              className="p-1.5 hover:bg-green-50 rounded-lg"
                              title="Mark fulfilled"
                              onClick={() =>
                                updateMut.mutate({ id: req.id, status: 'fulfilled' })
                              }
                            >
                              <CheckCircle size={15} className="text-green-500" />
                            </button>
                            <button
                              className="p-1.5 hover:bg-red-50 rounded-lg"
                              title="Reject"
                              onClick={() =>
                                updateMut.mutate({ id: req.id, status: 'rejected' })
                              }
                            >
                              <XCircle size={15} className="text-red-400" />
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
          </tbody>
        </table>
        {!isLoading && requests.length === 0 && (
          <div className="text-center py-12 text-gray-400">
            <CheckCircle size={32} className="mx-auto mb-3 opacity-40" />
            <p>No requests in this category</p>
          </div>
        )}
      </div>

      {/* Detail modal */}
      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-black/40"
            onClick={() => setSelected(null)}
          />
          <div className="relative card p-6 w-full max-w-lg shadow-xl">
            <h3 className="font-semibold text-gray-900 text-lg mb-4">
              Request: {selected.product_name}
            </h3>
            <dl className="space-y-2 text-sm">
              {[
                ['Brand', selected.brand],
                ['Barcode', selected.barcode],
                ['Message', selected.message],
                ['Submitted', new Date(selected.created_at).toLocaleString()],
                ['Status', selected.status],
              ]
                .filter(([, v]) => v)
                .map(([label, value]) => (
                  <div key={label as string} className="flex gap-4">
                    <dt className="w-24 font-medium text-gray-500 shrink-0">{label}</dt>
                    <dd className="text-gray-700">{value}</dd>
                  </div>
                ))}
            </dl>
            <div className="flex justify-end gap-3 mt-6">
              <button
                className="btn-secondary"
                onClick={() => setSelected(null)}
              >
                Close
              </button>
              <button
                className="btn-primary"
                onClick={() =>
                  updateMut.mutate({ id: selected.id, status: 'in_review' })
                }
                disabled={selected.status !== 'pending'}
              >
                Mark In Review
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
