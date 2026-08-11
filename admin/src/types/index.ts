export type DietType = 'veg' | 'non_veg' | 'vegan' | 'unknown'
export type VerificationStatus =
  | 'unverified'
  | 'imported'
  | 'under_review'
  | 'verified'
  | 'outdated'
export type RequestStatus = 'pending' | 'in_review' | 'fulfilled' | 'rejected'

export interface Category {
  id: string
  name: string
  slug: string
  description?: string
  image_url?: string
  icon?: string
  parent_category_id?: string
  is_active: boolean
  created_at: string
  updated_at: string
  product_count?: number
}

export interface Brand {
  id: string
  name: string
  slug: string
  logo_url?: string
  description?: string
  website?: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Nutrient {
  id: string
  name: string
  slug: string
  unit: string
  description?: string
  display_order: number
}

export interface ProductNutrient {
  id: string
  product_id: string
  nutrient_id: string
  nutrient?: Nutrient
  value_per_100g?: number
  value_per_serving?: number
}

export interface Product {
  id: string
  name: string
  slug: string
  brand_id?: string
  brand?: Brand
  category_id?: string
  category?: Category
  subcategory_id?: string
  barcode?: string
  description?: string
  image_url?: string
  serving_size?: number
  serving_unit?: string
  ingredients?: string
  allergens?: string[]
  may_contain_allergens?: string[]
  diet_type: DietType
  manufacturer?: string
  country?: string
  source?: string
  verification_status: VerificationStatus
  is_published: boolean
  product_nutrients?: ProductNutrient[]
  created_at: string
  updated_at: string
}

export interface ProductChangeHistory {
  id: string
  product_id: string
  changed_by?: string
  field_changed: string
  old_value?: string
  new_value?: string
  changed_at: string
}

export interface ProductRequest {
  id: string
  product_name: string
  brand?: string
  barcode?: string
  photo_url?: string
  label_photo_url?: string
  message?: string
  status: RequestStatus
  reviewed_by?: string
  created_at: string
  updated_at: string
}

export interface OFFProductData {
  barcode: string
  name?: string
  brandName?: string
  categories?: string
  ingredients?: string
  allergens?: string[]
  imageUrl?: string
  servingSize?: string
  nutrients: Record<string, number>
}

export interface DashboardStats {
  totalProducts: number
  totalCategories: number
  totalBrands: number
  addedThisMonth: number
  updatedThisMonth: number
  pendingReview: number
  pendingRequests: number
  verifiedProducts: number
}

// Form types
export type ProductFormData = Omit<
  Product,
  'id' | 'brand' | 'category' | 'product_nutrients' | 'created_at' | 'updated_at'
> & {
  nutrients: Array<{
    nutrient_id: string
    value_per_100g?: string
    value_per_serving?: string
  }>
}
