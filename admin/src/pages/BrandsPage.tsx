import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Plus, Pencil, Trash2, Check, X } from 'lucide-react'
import toast from 'react-hot-toast'
import { getBrands, upsertBrand, deleteBrand } from '../services/api'
import { ConfirmDialog } from '../components/common/ConfirmDialog'
import type { Brand } from '../types'

function slugify(s: string) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
}

interface BrandFormState {
  id?: string
  name: string
  slug: string
  website: string
  description: string
  is_active: boolean
}

const EMPTY: BrandFormState = {
  name: '', slug: '', website: '', description: '', is_active: true,
}

export function BrandsPage() {
  const qc = useQueryClient()
  const [editing, setEditing] = useState<BrandFormState | null>(null)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [search, setSearch] = useState('')

  const { data: brands = [], isLoading } = useQuery({
    queryKey: ['brands'],
    queryFn: getBrands,
  })

  const saveMut = useMutation({
    mutationFn: (data: Partial<Brand> & { name: string; slug: string }) =>
      upsertBrand(data),
    onSuccess: () => {
      toast.success('Brand saved')
      qc.invalidateQueries({ queryKey: ['brands'] })
      setEditing(null)
    },
    onError: (e: any) => toast.error(`Save failed: ${e.message}`),
  })

  const deleteMut = useMutation({
    mutationFn: deleteBrand,
    onSuccess: () => {
      toast.success('Brand deleted')
      qc.invalidateQueries({ queryKey: ['brands'] })
      setDeleteId(null)
    },
    onError: () => toast.error('Delete failed'),
  })

  const filtered = brands.filter((b) =>
    b.name.toLowerCase().includes(search.toLowerCase()),
  )

  const handleSave = () => {
    if (!editing?.name.trim()) { toast.error('Name is required'); return }
    saveMut.mutate({
      ...(editing.id ? { id: editing.id } : {}),
      name: editing.name.trim(),
      slug: editing.slug.trim() || slugify(editing.name),
      website: editing.website.trim() || undefined,
      description: editing.description.trim() || undefined,
      is_active: editing.is_active,
    })
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Brands</h1>
          <p className="text-sm text-gray-500 mt-0.5">{brands.length} brands</p>
        </div>
        <button className="btn-primary" onClick={() => setEditing({ ...EMPTY })}>
          <Plus size={16} /> Add Brand
        </button>
      </div>

      {/* Search */}
      <input
        className="input max-w-sm"
        placeholder="Search brands..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />

      {/* Inline edit form */}
      {editing && (
        <div className="card p-5 border-brand-300 border-2">
          <h3 className="font-semibold text-gray-900 mb-4">
            {editing.id ? 'Edit Brand' : 'New Brand'}
          </h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="label">Name *</label>
              <input
                className="input"
                value={editing.name}
                onChange={(e) =>
                  setEditing((prev) => ({
                    ...prev!,
                    name: e.target.value,
                    slug: slugify(e.target.value),
                  }))
                }
              />
            </div>
            <div>
              <label className="label">Slug</label>
              <input
                className="input font-mono text-xs"
                value={editing.slug}
                onChange={(e) =>
                  setEditing((prev) => ({ ...prev!, slug: e.target.value }))
                }
              />
            </div>
            <div>
              <label className="label">Website</label>
              <input
                className="input"
                value={editing.website}
                onChange={(e) =>
                  setEditing((prev) => ({ ...prev!, website: e.target.value }))
                }
                placeholder="https://brand.com"
              />
            </div>
            <div>
              <label className="label">Description</label>
              <input
                className="input"
                value={editing.description}
                onChange={(e) =>
                  setEditing((prev) => ({
                    ...prev!,
                    description: e.target.value,
                  }))
                }
              />
            </div>
          </div>
          <div className="flex justify-end gap-3 mt-4">
            <button className="btn-secondary" onClick={() => setEditing(null)}>
              <X size={15} /> Cancel
            </button>
            <button className="btn-primary" onClick={handleSave} disabled={saveMut.isPending}>
              <Check size={15} /> Save
            </button>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Name</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Slug</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Website</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">Status</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {isLoading
              ? Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="border-b border-gray-100 animate-pulse">
                    {Array.from({ length: 5 }).map((_, j) => (
                      <td key={j} className="px-4 py-3">
                        <div className="h-4 bg-gray-100 rounded w-28" />
                      </td>
                    ))}
                  </tr>
                ))
              : filtered.map((brand) => (
                  <tr key={brand.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="px-4 py-3 font-medium text-gray-900">{brand.name}</td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">
                      {brand.slug}
                    </td>
                    <td className="px-4 py-3">
                      {brand.website ? (
                        <a
                          href={brand.website}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-brand-600 hover:underline text-xs"
                        >
                          {brand.website}
                        </a>
                      ) : (
                        <span className="text-gray-400">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                          brand.is_active
                            ? 'bg-green-100 text-green-700'
                            : 'bg-gray-100 text-gray-500'
                        }`}
                      >
                        {brand.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2 justify-end">
                        <button
                          className="p-1.5 hover:bg-gray-100 rounded-lg"
                          onClick={() =>
                            setEditing({
                              id: brand.id,
                              name: brand.name,
                              slug: brand.slug,
                              website: brand.website ?? '',
                              description: brand.description ?? '',
                              is_active: brand.is_active,
                            })
                          }
                        >
                          <Pencil size={15} className="text-gray-500" />
                        </button>
                        <button
                          className="p-1.5 hover:bg-red-50 rounded-lg"
                          onClick={() => setDeleteId(brand.id)}
                        >
                          <Trash2 size={15} className="text-red-400" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
          </tbody>
        </table>
      </div>

      <ConfirmDialog
        open={deleteId !== null}
        title="Delete brand?"
        description="Products linked to this brand will have their brand cleared."
        confirmLabel="Delete"
        danger
        onConfirm={() => deleteId && deleteMut.mutate(deleteId)}
        onCancel={() => setDeleteId(null)}
      />
    </div>
  )
}
