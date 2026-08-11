import { useState, useCallback } from 'react'
import { useDropzone } from 'react-dropzone'
import { Search, Loader2, Upload, X, AlertTriangle } from 'lucide-react'
import toast from 'react-hot-toast'
import type { Brand, Category, DietType, Nutrient, Product, VerificationStatus } from '../../types'
import { fetchFromOFF } from '../../services/openFoodFacts'
import { uploadProductImage } from '../../services/api'

interface NutrientEntry {
  nutrient_id: string
  value_per_100g: string
  value_per_serving: string
}

interface Props {
  product?: Product
  categories: Category[]
  brands: Brand[]
  nutrients: Nutrient[]
  onSave: (data: any, nutrients: NutrientEntry[]) => Promise<void>
  onCancel: () => void
  saving?: boolean
}

const DIET_OPTIONS: { value: DietType; label: string }[] = [
  { value: 'veg',     label: '🟢 Vegetarian' },
  { value: 'vegan',   label: '🌱 Vegan' },
  { value: 'non_veg', label: '🔴 Non-Vegetarian' },
  { value: 'unknown', label: '❓ Unknown' },
]

const STATUS_OPTIONS: { value: VerificationStatus; label: string }[] = [
  { value: 'unverified',  label: 'Unverified' },
  { value: 'imported',    label: 'Imported' },
  { value: 'under_review',label: 'Under Review' },
  { value: 'verified',    label: 'Verified' },
  { value: 'outdated',    label: 'Outdated' },
]

function slugify(s: string) {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
}

export function ProductForm({
  product, categories, brands, nutrients, onSave, onCancel, saving,
}: Props) {
  const [barcode, setBarcode] = useState(product?.barcode ?? '')
  const [fetchingOFF, setFetchingOFF] = useState(false)
  const [offWarning, setOffWarning] = useState<string | null>(null)

  const [name, setName] = useState(product?.name ?? '')
  const [slug, setSlug] = useState(product?.slug ?? '')
  const [brandId, setBrandId] = useState(product?.brand_id ?? '')
  const [categoryId, setCategoryId] = useState(product?.category_id ?? '')
  const [description, setDescription] = useState(product?.description ?? '')
  const [ingredients, setIngredients] = useState(product?.ingredients ?? '')
  const [allergens, setAllergens] = useState(product?.allergens?.join(', ') ?? '')
  const [servingSize, setServingSize] = useState(product?.serving_size?.toString() ?? '')
  const [servingUnit, setServingUnit] = useState(product?.serving_unit ?? 'g')
  const [dietType, setDietType] = useState<DietType>(product?.diet_type ?? 'unknown')
  const [manufacturer, setManufacturer] = useState(product?.manufacturer ?? '')
  const [country, setCountry] = useState(product?.country ?? 'India')
  const [status, setStatus] = useState<VerificationStatus>(
    product?.verification_status ?? 'unverified',
  )
  const [isPublished, setIsPublished] = useState(product?.is_published ?? false)
  const [imageUrl, setImageUrl] = useState(product?.image_url ?? '')
  const [uploadingImage, setUploadingImage] = useState(false)

  // Nutrient entries — initialise from existing product nutrients
  const [nutrientEntries, setNutrientEntries] = useState<NutrientEntry[]>(() => {
    if (product?.product_nutrients?.length) {
      return product.product_nutrients.map((pn) => ({
        nutrient_id: pn.nutrient_id,
        value_per_100g: pn.value_per_100g?.toString() ?? '',
        value_per_serving: pn.value_per_serving?.toString() ?? '',
      }))
    }
    // Pre-populate all nutrients with empty strings
    return nutrients.map((n) => ({
      nutrient_id: n.id,
      value_per_100g: '',
      value_per_serving: '',
    }))
  })

  // ── OpenFoodFacts auto-fill ─────────────────────────────────────────────

  const handleFetchOFF = async () => {
    if (!barcode.trim()) { toast.error('Enter a barcode first'); return }
    setFetchingOFF(true)
    setOffWarning(null)

    try {
      const data = await fetchFromOFF(barcode.trim())
      if (!data) {
        toast.error('Product not found in OpenFoodFacts')
        setFetchingOFF(false)
        return
      }

      // Auto-fill form fields (user can still edit before saving)
      if (data.name && !name) { setName(data.name); setSlug(slugify(data.name)) }
      if (data.ingredients && !ingredients) setIngredients(data.ingredients)
      if (data.allergens && !allergens) setAllergens(data.allergens.join(', '))
      if (data.imageUrl && !imageUrl) setImageUrl(data.imageUrl)

      // Auto-match brand
      if (data.brandName && !brandId) {
        const matched = brands.find(
          (b) => b.name.toLowerCase() === data.brandName!.toLowerCase(),
        )
        if (matched) setBrandId(matched.id)
      }

      // Fill nutrient entries
      setNutrientEntries((prev) =>
        prev.map((entry) => {
          const nutrient = nutrients.find((n) => n.id === entry.nutrient_id)
          if (!nutrient) return entry
          const val = data.nutrients[nutrient.slug]
          if (val !== undefined && !entry.value_per_100g) {
            return { ...entry, value_per_100g: String(val) }
          }
          return entry
        }),
      )

      // Warn about validation concerns
      const warnings: string[] = []
      if (data.nutrients['protein'] !== undefined && data.nutrients['protein'] > 100) {
        warnings.push(`Protein ${data.nutrients['protein']}g/100g seems too high`)
      }
      if (warnings.length) setOffWarning(warnings.join('; '))

      setStatus('imported')
      toast.success('Auto-filled from OpenFoodFacts — please review before saving')
    } catch {
      toast.error('OpenFoodFacts lookup failed')
    } finally {
      setFetchingOFF(false)
    }
  }

  // ── Image upload ────────────────────────────────────────────────────────

  const onDrop = useCallback(async (accepted: File[]) => {
    const file = accepted[0]
    if (!file) return
    if (!product?.id) { toast.error('Save the product first before uploading an image'); return }
    setUploadingImage(true)
    try {
      const url = await uploadProductImage(file, product.id)
      setImageUrl(url)
      toast.success('Image uploaded')
    } catch {
      toast.error('Image upload failed')
    } finally {
      setUploadingImage(false)
    }
  }, [product?.id])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop, accept: { 'image/*': [] }, maxFiles: 1,
  })

  // ── Submit ──────────────────────────────────────────────────────────────

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim()) { toast.error('Product name is required'); return }

    const productData = {
      ...(product?.id ? { id: product.id } : {}),
      name: name.trim(),
      slug: slug.trim() || slugify(name),
      brand_id: brandId || null,
      category_id: categoryId || null,
      barcode: barcode.trim() || null,
      description: description.trim() || null,
      ingredients: ingredients.trim() || null,
      allergens: allergens.trim()
        ? allergens.split(',').map((a) => a.trim()).filter(Boolean)
        : null,
      serving_size: servingSize ? Number(servingSize) : null,
      serving_unit: servingUnit || 'g',
      diet_type: dietType,
      manufacturer: manufacturer.trim() || null,
      country: country.trim() || null,
      image_url: imageUrl || null,
      verification_status: status,
      is_published: isPublished,
      source: status === 'imported' ? 'OpenFoodFacts' : (product?.source ?? 'Manual'),
    }

    // Filter out empty nutrient entries
    const validNutrients = nutrientEntries.filter(
      (n) => n.value_per_100g !== '' || n.value_per_serving !== '',
    )

    await onSave(productData, validNutrients)
  }

  const updateNutrient = (
    id: string,
    field: 'value_per_100g' | 'value_per_serving',
    value: string,
  ) => {
    setNutrientEntries((prev) =>
      prev.map((e) => (e.nutrient_id === id ? { ...e, [field]: value } : e)),
    )
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-8">

      {/* ── Barcode + OFF auto-fill ── */}
      <section className="card p-6">
        <h2 className="font-semibold text-gray-900 mb-4">Barcode Lookup</h2>
        <div className="flex gap-3">
          <div className="flex-1">
            <input
              className="input"
              placeholder="Enter barcode (EAN-8, EAN-13, UPC-A...)"
              value={barcode}
              onChange={(e) => setBarcode(e.target.value)}
            />
          </div>
          <button
            type="button"
            className="btn-primary"
            onClick={handleFetchOFF}
            disabled={fetchingOFF}
          >
            {fetchingOFF ? (
              <Loader2 size={16} className="animate-spin" />
            ) : (
              <Search size={16} />
            )}
            Auto-fill from OpenFoodFacts
          </button>
        </div>

        {offWarning && (
          <div className="mt-3 flex items-start gap-2 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
            <AlertTriangle size={14} className="text-yellow-600 mt-0.5 shrink-0" />
            <p className="text-sm text-yellow-800">
              <strong>Review required:</strong> {offWarning}
            </p>
          </div>
        )}
      </section>

      {/* ── Basic info ── */}
      <section className="card p-6">
        <h2 className="font-semibold text-gray-900 mb-4">Product Information</h2>
        <div className="grid grid-cols-2 gap-4">
          <div className="col-span-2">
            <label className="label">Product Name *</label>
            <input
              className="input"
              value={name}
              onChange={(e) => {
                setName(e.target.value)
                if (!product?.id) setSlug(slugify(e.target.value))
              }}
              required
            />
          </div>
          <div>
            <label className="label">Slug</label>
            <input
              className="input font-mono text-xs"
              value={slug}
              onChange={(e) => setSlug(e.target.value)}
            />
          </div>
          <div>
            <label className="label">Barcode</label>
            <input
              className="input"
              value={barcode}
              onChange={(e) => setBarcode(e.target.value)}
            />
          </div>
          <div>
            <label className="label">Brand</label>
            <select className="input" value={brandId} onChange={(e) => setBrandId(e.target.value)}>
              <option value="">— Select brand —</option>
              {brands.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
            </select>
          </div>
          <div>
            <label className="label">Category</label>
            <select className="input" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
              <option value="">— Select category —</option>
              {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
          <div>
            <label className="label">Diet Type</label>
            <select className="input" value={dietType} onChange={(e) => setDietType(e.target.value as DietType)}>
              {DIET_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
          <div>
            <label className="label">Manufacturer</label>
            <input className="input" value={manufacturer} onChange={(e) => setManufacturer(e.target.value)} />
          </div>
          <div>
            <label className="label">Country</label>
            <input className="input" value={country} onChange={(e) => setCountry(e.target.value)} />
          </div>
          <div>
            <label className="label">Serving Size</label>
            <div className="flex gap-2">
              <input
                className="input"
                type="number"
                placeholder="e.g. 30"
                value={servingSize}
                onChange={(e) => setServingSize(e.target.value)}
              />
              <input
                className="input w-20"
                placeholder="g"
                value={servingUnit}
                onChange={(e) => setServingUnit(e.target.value)}
              />
            </div>
          </div>
          <div>
            <label className="label">Verification Status</label>
            <select className="input" value={status} onChange={(e) => setStatus(e.target.value as VerificationStatus)}>
              {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
          <div className="col-span-2">
            <label className="label">Description</label>
            <textarea
              className="input"
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>
          <div className="col-span-2">
            <label className="label">Ingredients</label>
            <textarea
              className="input"
              rows={3}
              value={ingredients}
              onChange={(e) => setIngredients(e.target.value)}
              placeholder="Flour, Sugar, Palm Oil, Salt..."
            />
          </div>
          <div className="col-span-2">
            <label className="label">Allergens (comma-separated)</label>
            <input
              className="input"
              value={allergens}
              onChange={(e) => setAllergens(e.target.value)}
              placeholder="gluten, milk, nuts"
            />
          </div>
          <div className="col-span-2 flex items-center gap-3">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                className="w-4 h-4 accent-brand-500"
                checked={isPublished}
                onChange={(e) => setIsPublished(e.target.checked)}
              />
              <span className="text-sm font-medium text-gray-700">Published (visible in app)</span>
            </label>
          </div>
        </div>
      </section>

      {/* ── Image upload ── */}
      <section className="card p-6">
        <h2 className="font-semibold text-gray-900 mb-4">Product Image</h2>
        {imageUrl && (
          <div className="relative inline-block mb-4">
            <img
              src={imageUrl}
              alt="Product"
              className="w-32 h-32 object-contain border border-gray-200 rounded-lg"
            />
            <button
              type="button"
              onClick={() => setImageUrl('')}
              className="absolute -top-2 -right-2 w-6 h-6 bg-red-500 text-white
                         rounded-full flex items-center justify-center"
            >
              <X size={12} />
            </button>
          </div>
        )}
        <div
          {...getRootProps()}
          className={`border-2 border-dashed rounded-xl p-8 text-center cursor-pointer
                      transition-colors ${isDragActive ? 'border-brand-500 bg-brand-50' : 'border-gray-200 hover:border-brand-400'}`}
        >
          <input {...getInputProps()} />
          {uploadingImage ? (
            <Loader2 size={24} className="animate-spin text-brand-500 mx-auto" />
          ) : (
            <>
              <Upload size={24} className="text-gray-400 mx-auto mb-2" />
              <p className="text-sm text-gray-500">
                Drag an image here or click to upload
              </p>
              <p className="text-xs text-gray-400 mt-1">PNG, JPG, WebP accepted</p>
            </>
          )}
        </div>
        <div className="mt-3">
          <label className="label">Or paste image URL</label>
          <input
            className="input"
            value={imageUrl}
            onChange={(e) => setImageUrl(e.target.value)}
            placeholder="https://..."
          />
        </div>
      </section>

      {/* ── Nutrients ── */}
      <section className="card p-6">
        <h2 className="font-semibold text-gray-900 mb-1">Nutrition Facts</h2>
        <p className="text-xs text-gray-500 mb-4">
          Leave blank for any nutrients that are unavailable — never enter 0 to fill missing data.
        </p>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="text-left py-2 pr-4 font-medium text-gray-500 w-48">Nutrient</th>
                <th className="text-left py-2 pr-4 font-medium text-gray-500">Per 100g</th>
                <th className="text-left py-2 font-medium text-gray-500">Per Serving</th>
              </tr>
            </thead>
            <tbody>
              {nutrients.map((nutrient) => {
                const entry = nutrientEntries.find((e) => e.nutrient_id === nutrient.id)
                if (!entry) return null
                return (
                  <tr key={nutrient.id} className="border-b border-gray-50">
                    <td className="py-2 pr-4 font-medium text-gray-700">
                      {nutrient.name}
                      <span className="ml-1 text-gray-400">({nutrient.unit})</span>
                    </td>
                    <td className="py-1.5 pr-4">
                      <input
                        className="input w-28 text-center"
                        type="number"
                        step="0.01"
                        min="0"
                        value={entry.value_per_100g}
                        onChange={(e) =>
                          updateNutrient(nutrient.id, 'value_per_100g', e.target.value)
                        }
                        placeholder="—"
                      />
                    </td>
                    <td className="py-1.5">
                      <input
                        className="input w-28 text-center"
                        type="number"
                        step="0.01"
                        min="0"
                        value={entry.value_per_serving}
                        onChange={(e) =>
                          updateNutrient(nutrient.id, 'value_per_serving', e.target.value)
                        }
                        placeholder="—"
                      />
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </section>

      {/* ── Actions ── */}
      <div className="flex justify-end gap-3 pb-8">
        <button type="button" className="btn-secondary" onClick={onCancel}>
          Cancel
        </button>
        <button type="submit" className="btn-primary" disabled={saving}>
          {saving && <Loader2 size={16} className="animate-spin" />}
          {product?.id ? 'Save changes' : 'Create product'}
        </button>
      </div>
    </form>
  )
}
