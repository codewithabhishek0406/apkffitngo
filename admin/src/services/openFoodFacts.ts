import axios from 'axios'
import type { OFFProductData } from '../types'

// OFF nutriment key → our slug
const OFF_NUTRIMENT_MAP: Record<string, string> = {
  'energy-kcal_100g': 'energy_kcal',
  'proteins_100g':    'protein',
  'carbohydrates_100g': 'carbohydrates',
  'fat_100g':         'fat_total',
  'fiber_100g':       'fiber',
  'sugars_100g':      'sugar',
  'sodium_100g':      'sodium',
  'saturated-fat_100g': 'saturated_fat',
  'trans-fat_100g':   'trans_fat',
  'cholesterol_100g': 'cholesterol',
}

export async function fetchFromOFF(barcode: string): Promise<OFFProductData | null> {
  try {
    const res = await axios.get(
      `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`,
      {
        params: {
          fields:
            'product_name,brands,categories,ingredients_text,' +
            'allergens_tags,image_front_url,serving_size,nutriments',
        },
        headers: {
          'User-Agent': 'FitNGo-Admin/1.0 (contact@fitngo.app)',
        },
        timeout: 12000,
      },
    )

    if (res.data.status === 0 || !res.data.product) return null

    const p = res.data.product
    const nutriments = p.nutriments ?? {}

    // Map OFF nutriments to our slugs
    const nutrients: Record<string, number> = {}
    for (const [offKey, ourSlug] of Object.entries(OFF_NUTRIMENT_MAP)) {
      const val = nutriments[offKey] ?? nutriments[offKey.replace('_100g', '')]
      if (val !== undefined && val !== null) {
        nutrients[ourSlug] = Number(val)
      }
    }

    // Parse allergens
    const allergenTags: string[] = p.allergens_tags ?? []
    const allergens = allergenTags
      .map((t: string) => (t.includes(':') ? t.split(':')[1] : t))
      .map((t: string) => t.replace(/-/g, ' ').trim())
      .filter(Boolean)

    return {
      barcode,
      name: p.product_name || undefined,
      brandName: p.brands || undefined,
      categories: p.categories || undefined,
      ingredients: p.ingredients_text || undefined,
      allergens: allergens.length ? allergens : undefined,
      imageUrl: p.image_front_url || undefined,
      servingSize: p.serving_size || undefined,
      nutrients,
    }
  } catch {
    return null
  }
}
