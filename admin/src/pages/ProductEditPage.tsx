import { useParams, useNavigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import toast from 'react-hot-toast'
import { ArrowLeft, History } from 'lucide-react'
import {
  getProductById, getCategories, getBrands, getNutrients,
  upsertProduct, saveProductNutrients, getChangeHistory,
} from '../services/api'
import { ProductForm } from '../components/products/ProductForm'
import { CsvImport } from '../components/products/CsvImport'
import { StatusBadge } from '../components/common/StatusBadge'
import type { Product } from '../types'

export function ProductEditPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const qc = useQueryClient()
  const isNew = id === 'new'
  const isImport = id === 'import'

  const { data: product } = useQuery({
    queryKey: ['product', id],
    queryFn: () => getProductById(id!),
    enabled: !isNew && !isImport,
  })

  const { data: categories = [] } = useQuery({
    queryKey: ['categories'],
    queryFn: getCategories,
  })
  const { data: brands = [] } = useQuery({
    queryKey: ['brands'],
    queryFn: getBrands,
  })
  const { data: nutrients = [] } = useQuery({
    queryKey: ['nutrients'],
    queryFn: getNutrients,
  })
  const { data: history = [] } = useQuery({
    queryKey: ['change-history', id],
    queryFn: () => getChangeHistory(id!),
    enabled: !isNew && !isImport,
  })

  const saveMutation = useMutation({
    mutationFn: async ({
      productData,
      nutrientEntries,
    }: {
      productData: Partial<Product>
      nutrientEntries: any[]
    }) => {
      const saved = await upsertProduct(productData)
      await saveProductNutrients(
        saved.id,
        nutrientEntries.map((e) => ({
          nutrient_id: e.nutrient_id,
          value_per_100g: e.value_per_100g !== '' ? Number(e.value_per_100g) : undefined,
          value_per_serving: e.value_per_serving !== '' ? Number(e.value_per_serving) : undefined,
        })),
      )
      return saved
    },
    onSuccess: (saved) => {
      toast.success(isNew ? 'Product created' : 'Product saved')
      qc.invalidateQueries({ queryKey: ['products'] })
      qc.invalidateQueries({ queryKey: ['product', saved.id] })
      if (isNew) navigate(`/products/${saved.id}`)
    },
    onError: (e: any) => toast.error(`Save failed: ${e.message}`),
  })

  if (isImport) {
    return (
      <div className="max-w-4xl">
        <div className="flex items-center gap-3 mb-6">
          <button className="btn-secondary px-2" onClick={() => navigate('/products')}>
            <ArrowLeft size={16} />
          </button>
          <h1 className="text-2xl font-bold text-gray-900">CSV Bulk Import</h1>
        </div>
        <div className="card p-6">
          <CsvImport onDone={() => navigate('/products')} />
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-4xl">
      {/* Page header */}
      <div className="flex items-center gap-3 mb-6">
        <button className="btn-secondary px-2" onClick={() => navigate('/products')}>
          <ArrowLeft size={16} />
        </button>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-gray-900">
            {isNew ? 'New Product' : (product?.name ?? '…')}
          </h1>
          {product && (
            <div className="flex items-center gap-2 mt-1">
              <StatusBadge status={product.verification_status} />
              <span className="text-xs text-gray-400">ID: {product.id}</span>
            </div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Form — takes 2/3 */}
        <div className="col-span-2">
          <ProductForm
            product={isNew ? undefined : product}
            categories={categories}
            brands={brands}
            nutrients={nutrients}
            saving={saveMutation.isPending}
            onCancel={() => navigate('/products')}
            onSave={async (productData, nutrientEntries) => {
              await saveMutation.mutateAsync({ productData, nutrientEntries })
            }}
          />
        </div>

        {/* Sidebar — change history */}
        {!isNew && history.length > 0 && (
          <div className="col-span-1">
            <div className="card p-4 sticky top-6">
              <div className="flex items-center gap-2 mb-3">
                <History size={16} className="text-gray-500" />
                <h3 className="font-semibold text-sm text-gray-900">Change History</h3>
              </div>
              <div className="space-y-3 max-h-96 overflow-y-auto">
                {history.map((h) => (
                  <div key={h.id} className="text-xs border-b border-gray-100 pb-2 last:border-0">
                    <div className="font-medium text-gray-700">{h.field_changed}</div>
                    {h.old_value && (
                      <div className="text-red-500 line-through truncate">
                        {h.old_value}
                      </div>
                    )}
                    {h.new_value && (
                      <div className="text-green-600 truncate">{h.new_value}</div>
                    )}
                    <div className="text-gray-400 mt-0.5">
                      {h.changed_by ?? 'Admin'} ·{' '}
                      {new Date(h.changed_at).toLocaleString()}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
