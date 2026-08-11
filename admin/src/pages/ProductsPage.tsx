import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { Plus, Search, Upload, Trash2, Pencil, Eye } from 'lucide-react'
import toast from 'react-hot-toast'
import {
  getProducts, getCategories, getBrands, deleteProduct,
} from '../services/api'
import { StatusBadge } from '../components/common/StatusBadge'
import { ConfirmDialog } from '../components/common/ConfirmDialog'
import { Pagination } from '../components/common/Pagination'
import type { Product } from '../types'

const PAGE_SIZE = 20

export function ProductsPage() {
  const navigate = useNavigate()
  const [searchParams, setSearchParams] = useSearchParams()
  const [search, setSearch] = useState(searchParams.get('q') ?? '')
  const [deleteId, setDeleteId] = useState<string | null>(null)

  const page = Number(searchParams.get('page') ?? '0')
  const categoryId = searchParams.get('category') ?? undefined
  const status = searchParams.get('status') ?? undefined

  const qc = useQueryClient()

  const { data, isLoading } = useQuery({
    queryKey: ['products', page, search, categoryId, status],
    queryFn: () => getProducts({ page, pageSize: PAGE_SIZE, search, categoryId, status }),
  })

  const { data: categories = [] } = useQuery({
    queryKey: ['categories'],
    queryFn: getCategories,
  })

  const deleteMut = useMutation({
    mutationFn: deleteProduct,
    onSuccess: () => {
      toast.success('Product deleted')
      qc.invalidateQueries({ queryKey: ['products'] })
      setDeleteId(null)
    },
    onError: () => toast.error('Delete failed'),
  })

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Products</h1>
          <p className="text-sm text-gray-500 mt-0.5">
            {data?.total ?? 0} total products
          </p>
        </div>
        <div className="flex gap-3">
          <button
            className="btn-secondary"
            onClick={() => navigate('/products/import')}
          >
            <Upload size={16} /> CSV Import
          </button>
          <button
            className="btn-primary"
            onClick={() => navigate('/products/new')}
          >
            <Plus size={16} /> Add Product
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-3 flex-wrap">
        <div className="relative flex-1 min-w-64">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            className="input pl-9"
            placeholder="Search by name or barcode..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                setSearchParams({ q: search, page: '0' })
              }
            }}
          />
        </div>
        <select
          className="input w-48"
          value={categoryId ?? ''}
          onChange={(e) =>
            setSearchParams({ category: e.target.value, page: '0' })
          }
        >
          <option value="">All categories</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
        <select
          className="input w-44"
          value={status ?? ''}
          onChange={(e) =>
            setSearchParams({ status: e.target.value, page: '0' })
          }
        >
          <option value="">All statuses</option>
          <option value="unverified">Unverified</option>
          <option value="imported">Imported</option>
          <option value="under_review">Under Review</option>
          <option value="verified">Verified</option>
          <option value="outdated">Outdated</option>
        </select>
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Product</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Category</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Barcode</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Status</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Published</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {isLoading
              ? Array.from({ length: 8 }).map((_, i) => (
                  <tr key={i} className="border-b border-gray-100 animate-pulse">
                    {Array.from({ length: 6 }).map((_, j) => (
                      <td key={j} className="px-4 py-3">
                        <div className="h-4 bg-gray-100 rounded w-24" />
                      </td>
                    ))}
                  </tr>
                ))
              : (data?.products ?? []).map((p: Product) => (
                  <tr
                    key={p.id}
                    className="border-b border-gray-100 hover:bg-gray-50 transition-colors"
                  >
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        {p.image_url ? (
                          <img
                            src={p.image_url}
                            alt={p.name}
                            className="w-9 h-9 object-contain rounded-lg border border-gray-100"
                          />
                        ) : (
                          <div className="w-9 h-9 rounded-lg bg-gray-100 flex items-center justify-center text-gray-400 text-xs">
                            ?
                          </div>
                        )}
                        <div>
                          <div className="font-medium text-gray-900 max-w-xs truncate">
                            {p.name}
                          </div>
                          <div className="text-xs text-gray-400">
                            {(p as any).brand?.name ?? '—'}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-gray-600">
                      {(p as any).category?.name ?? '—'}
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">
                      {p.barcode ?? '—'}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={p.verification_status} />
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                          p.is_published
                            ? 'bg-green-100 text-green-700'
                            : 'bg-gray-100 text-gray-600'
                        }`}
                      >
                        {p.is_published ? 'Live' : 'Draft'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2 justify-end">
                        <button
                          className="p-1.5 hover:bg-gray-100 rounded-lg transition-colors"
                          onClick={() => navigate(`/products/${p.id}`)}
                          title="View / Edit"
                        >
                          <Pencil size={15} className="text-gray-500" />
                        </button>
                        <button
                          className="p-1.5 hover:bg-red-50 rounded-lg transition-colors"
                          onClick={() => setDeleteId(p.id)}
                          title="Delete"
                        >
                          <Trash2 size={15} className="text-red-400" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
          </tbody>
        </table>
        {!isLoading && (data?.products ?? []).length === 0 && (
          <div className="text-center py-16 text-gray-400">
            <Package size={36} className="mx-auto mb-3 opacity-40" />
            <p>No products found</p>
          </div>
        )}
      </div>

      <Pagination
        page={page}
        pageSize={PAGE_SIZE}
        total={data?.total ?? 0}
        onPageChange={(p) => setSearchParams({ page: String(p) })}
      />

      <ConfirmDialog
        open={deleteId !== null}
        title="Delete product?"
        description="This will permanently delete the product and all its nutrition data. This cannot be undone."
        confirmLabel="Delete"
        danger
        onConfirm={() => deleteId && deleteMut.mutate(deleteId)}
        onCancel={() => setDeleteId(null)}
      />
    </div>
  )
}
