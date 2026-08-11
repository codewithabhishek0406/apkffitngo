import { supabase } from './supabase'
import type {
  Brand,
  Category,
  DashboardStats,
  Nutrient,
  Product,
  ProductChangeHistory,
  ProductRequest,
} from '../types'

// ── Categories ────────────────────────────────────────────────────────────────

export async function getCategories(): Promise<Category[]> {
  const { data, error } = await supabase
    .from('categories')
    .select('*')
    .order('name')
  if (error) throw error
  return data
}

export async function upsertCategory(
  cat: Partial<Category> & { name: string; slug: string },
): Promise<Category> {
  const { data, error } = await supabase
    .from('categories')
    .upsert(cat, { onConflict: 'id' })
    .select()
    .single()
  if (error) throw error
  return data
}

export async function deleteCategory(id: string): Promise<void> {
  const { error } = await supabase.from('categories').delete().eq('id', id)
  if (error) throw error
}

// ── Brands ────────────────────────────────────────────────────────────────────

export async function getBrands(): Promise<Brand[]> {
  const { data, error } = await supabase
    .from('brands')
    .select('*')
    .order('name')
  if (error) throw error
  return data
}

export async function upsertBrand(
  brand: Partial<Brand> & { name: string; slug: string },
): Promise<Brand> {
  const { data, error } = await supabase
    .from('brands')
    .upsert(brand, { onConflict: 'id' })
    .select()
    .single()
  if (error) throw error
  return data
}

export async function deleteBrand(id: string): Promise<void> {
  const { error } = await supabase.from('brands').delete().eq('id', id)
  if (error) throw error
}

// ── Nutrients ─────────────────────────────────────────────────────────────────

export async function getNutrients(): Promise<Nutrient[]> {
  const { data, error } = await supabase
    .from('nutrients')
    .select('*')
    .order('display_order')
  if (error) throw error
  return data
}

// ── Products ──────────────────────────────────────────────────────────────────

export interface ProductListParams {
  page?: number
  pageSize?: number
  search?: string
  categoryId?: string
  brandId?: string
  status?: string
}

export interface ProductListResult {
  products: Product[]
  total: number
}

export async function getProducts(
  params: ProductListParams = {},
): Promise<ProductListResult> {
  const { page = 0, pageSize = 20, search, categoryId, brandId, status } =
    params
  const from = page * pageSize
  const to = from + pageSize - 1

  let query = supabase
    .from('products')
    .select(
      '*, brand:brands(id,name,logo_url), category:categories!products_category_id_fkey(id,name,slug)',
      { count: 'exact' },
    )
    .order('created_at', { ascending: false })
    .range(from, to)

  if (search) {
    query = query.or(
      `name.ilike.%${search}%,barcode.eq.${search}`,
    )
  }
  if (categoryId) query = query.eq('category_id', categoryId)
  if (brandId) query = query.eq('brand_id', brandId)
  if (status) query = query.eq('verification_status', status)

  const { data, error, count } = await query
  if (error) throw error
  return { products: data ?? [], total: count ?? 0 }
}

export async function getProductById(id: string): Promise<Product> {
  const { data, error } = await supabase
    .from('products')
    .select(
      `*, brand:brands(*), category:categories!products_category_id_fkey(*),
       product_nutrients(*, nutrient:nutrients(*))`,
    )
    .eq('id', id)
    .single()
  if (error) throw error
  return data
}

export async function upsertProduct(product: Partial<Product>): Promise<Product> {
  const { product_nutrients, brand, category, ...productData } = product as any
  const { data, error } = await supabase
    .from('products')
    .upsert(productData, { onConflict: 'id' })
    .select()
    .single()
  if (error) throw error
  return data
}

export async function deleteProduct(id: string): Promise<void> {
  const { error } = await supabase.from('products').delete().eq('id', id)
  if (error) throw error
}

export async function saveProductNutrients(
  productId: string,
  nutrients: Array<{
    nutrient_id: string
    value_per_100g?: number
    value_per_serving?: number
  }>,
): Promise<void> {
  // Delete existing then insert fresh (simpler than diffing)
  await supabase.from('product_nutrients').delete().eq('product_id', productId)

  const rows = nutrients
    .filter((n) => n.value_per_100g !== undefined || n.value_per_serving !== undefined)
    .map((n) => ({ product_id: productId, ...n }))

  if (rows.length === 0) return

  const { error } = await supabase.from('product_nutrients').insert(rows)
  if (error) throw error
}

export async function logChange(
  productId: string,
  field: string,
  oldValue: string | null,
  newValue: string | null,
  changedBy: string,
): Promise<void> {
  await supabase.from('product_change_history').insert({
    product_id: productId,
    field_changed: field,
    old_value: oldValue,
    new_value: newValue,
    changed_by: changedBy,
  })
}

// ── Change history ────────────────────────────────────────────────────────────

export async function getChangeHistory(
  productId: string,
): Promise<ProductChangeHistory[]> {
  const { data, error } = await supabase
    .from('product_change_history')
    .select('*')
    .eq('product_id', productId)
    .order('changed_at', { ascending: false })
    .limit(50)
  if (error) throw error
  return data
}

// ── Product requests ──────────────────────────────────────────────────────────

export async function getProductRequests(
  status?: string,
): Promise<ProductRequest[]> {
  let query = supabase
    .from('product_requests')
    .select('*')
    .order('created_at', { ascending: false })
  if (status) query = query.eq('status', status)
  const { data, error } = await query
  if (error) throw error
  return data
}

export async function updateRequestStatus(
  id: string,
  status: string,
  reviewedBy?: string,
): Promise<void> {
  const { error } = await supabase
    .from('product_requests')
    .update({ status, reviewed_by: reviewedBy })
    .eq('id', id)
  if (error) throw error
}

// ── Dashboard stats ───────────────────────────────────────────────────────────

export async function getDashboardStats(): Promise<DashboardStats> {
  const now = new Date()
  const firstOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString()

  const [
    { count: totalProducts },
    { count: totalCategories },
    { count: totalBrands },
    { count: addedThisMonth },
    { count: updatedThisMonth },
    { count: pendingReview },
    { count: pendingRequests },
    { count: verifiedProducts },
  ] = await Promise.all([
    supabase.from('products').select('*', { count: 'exact', head: true }),
    supabase.from('categories').select('*', { count: 'exact', head: true }).eq('is_active', true),
    supabase.from('brands').select('*', { count: 'exact', head: true }).eq('is_active', true),
    supabase.from('products').select('*', { count: 'exact', head: true }).gte('created_at', firstOfMonth),
    supabase.from('products').select('*', { count: 'exact', head: true }).gte('updated_at', firstOfMonth),
    supabase.from('products').select('*', { count: 'exact', head: true }).eq('verification_status', 'under_review'),
    supabase.from('product_requests').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
    supabase.from('products').select('*', { count: 'exact', head: true }).eq('verification_status', 'verified'),
  ])

  return {
    totalProducts: totalProducts ?? 0,
    totalCategories: totalCategories ?? 0,
    totalBrands: totalBrands ?? 0,
    addedThisMonth: addedThisMonth ?? 0,
    updatedThisMonth: updatedThisMonth ?? 0,
    pendingReview: pendingReview ?? 0,
    pendingRequests: pendingRequests ?? 0,
    verifiedProducts: verifiedProducts ?? 0,
  }
}

// ── Image upload ──────────────────────────────────────────────────────────────

export async function uploadProductImage(
  file: File,
  productId: string,
): Promise<string> {
  const ext = file.name.split('.').pop()
  const path = `products/${productId}.${ext}`
  const { error } = await supabase.storage
    .from('product-images')
    .upload(path, file, { upsert: true, contentType: file.type })
  if (error) throw error
  const { data } = supabase.storage.from('product-images').getPublicUrl(path)
  return data.publicUrl
}
