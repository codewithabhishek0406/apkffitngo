import { useState, useCallback } from 'react'
import { useDropzone } from 'react-dropzone'
import Papa from 'papaparse'
import { Upload, CheckCircle, XCircle, AlertTriangle, Loader2 } from 'lucide-react'
import toast from 'react-hot-toast'
import { supabase } from '../../services/supabase'

interface CsvRow {
  name: string
  barcode?: string
  brand?: string
  category?: string
  serving_size?: string
  serving_unit?: string
  ingredients?: string
  allergens?: string
  diet_type?: string
  manufacturer?: string
  country?: string
  energy_kcal?: string
  protein?: string
  carbohydrates?: string
  fat_total?: string
  fiber?: string
  sugar?: string
  sodium?: string
}

interface ImportResult {
  imported: number
  updated: number
  duplicates: number
  failed: number
  errors: string[]
}

export function CsvImport({ onDone }: { onDone: () => void }) {
  const [rows, setRows] = useState<CsvRow[]>([])
  const [preview, setPreview] = useState(false)
  const [importing, setImporting] = useState(false)
  const [result, setResult] = useState<ImportResult | null>(null)

  const onDrop = useCallback((files: File[]) => {
    const file = files[0]
    if (!file) return
    Papa.parse<CsvRow>(file, {
      header: true,
      skipEmptyLines: true,
      complete: (res) => {
        setRows(res.data)
        setPreview(true)
      },
      error: () => toast.error('Failed to parse CSV'),
    })
  }, [])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'text/csv': ['.csv'],
      'application/vnd.ms-excel': ['.csv'],
    },
    maxFiles: 1,
  })

  const handleImport = async () => {
    setImporting(true)
    const result: ImportResult = {
      imported: 0, updated: 0, duplicates: 0, failed: 0, errors: [],
    }

    // Fetch existing barcodes to detect duplicates
    const { data: existing } = await supabase
      .from('products')
      .select('id, barcode, name')

    const existingBarcodes = new Map(
      (existing ?? [])
        .filter((p) => p.barcode)
        .map((p) => [p.barcode as string, p.id as string]),
    )

    // Fetch nutrient ID map
    const { data: nutrients } = await supabase
      .from('nutrients')
      .select('id, slug')
    const nutrientMap = new Map(
      (nutrients ?? []).map((n) => [n.slug as string, n.id as string]),
    )

    for (const [i, row] of rows.entries()) {
      if (!row.name?.trim()) {
        result.errors.push(`Row ${i + 2}: Missing product name`)
        result.failed++
        continue
      }

      try {
        const slug = row.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
        const isExisting = row.barcode && existingBarcodes.has(row.barcode)

        if (isExisting) {
          result.duplicates++
          continue // skip duplicates (don't silently overwrite)
        }

        // Insert product
        const { data: inserted, error } = await supabase
          .from('products')
          .insert({
            name: row.name.trim(),
            slug,
            barcode: row.barcode?.trim() || null,
            serving_size: row.serving_size ? Number(row.serving_size) : null,
            serving_unit: row.serving_unit || 'g',
            ingredients: row.ingredients?.trim() || null,
            allergens: row.allergens
              ? row.allergens.split(',').map((a) => a.trim()).filter(Boolean)
              : null,
            diet_type: row.diet_type || 'unknown',
            manufacturer: row.manufacturer?.trim() || null,
            country: row.country?.trim() || 'India',
            source: 'CSV',
            verification_status: 'imported',
            is_published: false,
          })
          .select('id')
          .single()

        if (error || !inserted) {
          result.errors.push(`Row ${i + 2}: ${error?.message ?? 'Insert failed'}`)
          result.failed++
          continue
        }

        // Insert nutrients
        const nutrientRows = [
          ['energy_kcal', row.energy_kcal],
          ['protein',     row.protein],
          ['carbohydrates', row.carbohydrates],
          ['fat_total',   row.fat_total],
          ['fiber',       row.fiber],
          ['sugar',       row.sugar],
          ['sodium',      row.sodium],
        ]
          .filter(([, v]) => v !== undefined && v !== '' && v !== null)
          .map(([slug, val]) => ({
            product_id: inserted.id,
            nutrient_id: nutrientMap.get(slug as string),
            value_per_100g: Number(val),
          }))
          .filter((r) => r.nutrient_id)

        if (nutrientRows.length > 0) {
          await supabase.from('product_nutrients').insert(nutrientRows)
        }

        result.imported++
      } catch (err: any) {
        result.errors.push(`Row ${i + 2}: ${err.message}`)
        result.failed++
      }
    }

    setResult(result)
    setImporting(false)
    toast.success(`Import done — ${result.imported} imported, ${result.failed} failed`)
  }

  if (result) {
    return (
      <div className="space-y-4">
        <h3 className="font-semibold text-gray-900">Import Summary</h3>
        <div className="grid grid-cols-4 gap-4">
          <Stat icon={<CheckCircle size={18} className="text-green-600" />} label="Imported" value={result.imported} color="green" />
          <Stat icon={<CheckCircle size={18} className="text-blue-600" />} label="Updated" value={result.updated} color="blue" />
          <Stat icon={<AlertTriangle size={18} className="text-yellow-600" />} label="Duplicates skipped" value={result.duplicates} color="yellow" />
          <Stat icon={<XCircle size={18} className="text-red-600" />} label="Failed" value={result.failed} color="red" />
        </div>
        {result.errors.length > 0 && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-sm font-medium text-red-800 mb-2">Errors:</p>
            <ul className="text-xs text-red-700 space-y-1 list-disc pl-4">
              {result.errors.map((e, i) => <li key={i}>{e}</li>)}
            </ul>
          </div>
        )}
        <button className="btn-primary" onClick={onDone}>Done</button>
      </div>
    )
  }

  if (preview && rows.length > 0) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="font-semibold text-gray-900">{rows.length} rows ready to import</h3>
          <div className="flex gap-3">
            <button className="btn-secondary" onClick={() => { setRows([]); setPreview(false) }}>
              Cancel
            </button>
            <button className="btn-primary" onClick={handleImport} disabled={importing}>
              {importing && <Loader2 size={16} className="animate-spin" />}
              Import {rows.length} products
            </button>
          </div>
        </div>
        <div className="overflow-x-auto border border-gray-200 rounded-lg">
          <table className="text-xs w-full">
            <thead className="bg-gray-50">
              <tr>
                {Object.keys(rows[0]).map((k) => (
                  <th key={k} className="text-left px-3 py-2 font-medium text-gray-500 whitespace-nowrap">
                    {k}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.slice(0, 10).map((row, i) => (
                <tr key={i} className="border-t border-gray-100">
                  {Object.values(row).map((v, j) => (
                    <td key={j} className="px-3 py-2 text-gray-700 whitespace-nowrap max-w-xs truncate">
                      {v as string}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
          {rows.length > 10 && (
            <p className="text-xs text-gray-400 p-3 border-t border-gray-100">
              ... and {rows.length - 10} more rows
            </p>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div>
        <h3 className="font-semibold text-gray-900 mb-1">CSV Bulk Import</h3>
        <p className="text-sm text-gray-500">
          Required columns: <code className="bg-gray-100 px-1 rounded">name</code>.
          Optional: barcode, brand, category, serving_size, serving_unit, ingredients,
          allergens, diet_type, manufacturer, country, energy_kcal, protein,
          carbohydrates, fat_total, fiber, sugar, sodium.
        </p>
      </div>
      <div
        {...getRootProps()}
        className={`border-2 border-dashed rounded-xl p-12 text-center cursor-pointer transition-colors
                    ${isDragActive ? 'border-brand-500 bg-brand-50' : 'border-gray-200 hover:border-brand-400'}`}
      >
        <input {...getInputProps()} />
        <Upload size={32} className="text-gray-400 mx-auto mb-3" />
        <p className="font-medium text-gray-700">Drop your CSV file here</p>
        <p className="text-sm text-gray-400 mt-1">or click to browse</p>
      </div>
      <a
        href="/sample-import.csv"
        className="text-sm text-brand-600 hover:underline"
        download
      >
        Download sample CSV template
      </a>
    </div>
  )
}

function Stat({ icon, label, value, color }: {
  icon: React.ReactNode; label: string; value: number
  color: 'green' | 'blue' | 'yellow' | 'red'
}) {
  const bg = { green: 'bg-green-50', blue: 'bg-blue-50', yellow: 'bg-yellow-50', red: 'bg-red-50' }
  return (
    <div className={`${bg[color]} rounded-xl p-4 flex items-center gap-3`}>
      {icon}
      <div>
        <div className="text-2xl font-bold text-gray-900">{value}</div>
        <div className="text-xs text-gray-500">{label}</div>
      </div>
    </div>
  )
}
