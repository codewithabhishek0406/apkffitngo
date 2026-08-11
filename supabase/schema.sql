-- ============================================================
-- FitNGo — Supabase / PostgreSQL Schema
-- Run this in your Supabase SQL editor (Dashboard → SQL Editor)
-- ============================================================

-- Enable extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pg_trgm";   -- for fuzzy/full-text search

-- ============================================================
-- 1. CATEGORIES
-- ============================================================
create table public.categories (
  id              uuid primary key default uuid_generate_v4(),
  name            text not null,
  slug            text not null unique,
  description     text,
  image_url       text,
  icon            text,
  parent_category_id uuid references public.categories(id) on delete set null,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_categories_slug on public.categories(slug);
create index idx_categories_parent on public.categories(parent_category_id);

-- ============================================================
-- 2. BRANDS
-- ============================================================
create table public.brands (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  slug        text not null unique,
  logo_url    text,
  description text,
  website     text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_brands_slug on public.brands(slug);
create index idx_brands_name_trgm on public.brands using gin(name gin_trgm_ops);

-- ============================================================
-- 3. PRODUCTS
-- ============================================================
create table public.products (
  id                  uuid primary key default uuid_generate_v4(),
  name                text not null,
  slug                text not null unique,
  brand_id            uuid references public.brands(id) on delete set null,
  category_id         uuid references public.categories(id) on delete set null,
  subcategory_id      uuid references public.categories(id) on delete set null,
  barcode             text unique,
  description         text,
  image_url           text,
  serving_size        numeric(10, 2),
  serving_unit        text default 'g',
  ingredients         text,
  allergens           text[],
  may_contain_allergens text[],
  diet_type           text check (diet_type in ('veg','non_veg','vegan','unknown')) default 'unknown',
  manufacturer        text,
  country             text default 'India',
  source              text,   -- 'OpenFoodFacts', 'CSV', 'Manual', 'User'
  verification_status text not null default 'unverified'
                      check (verification_status in
                             ('unverified','imported','under_review','verified','outdated')),
  is_published        boolean not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- Full-text + trigram indexes for fast search
create index idx_products_name_trgm     on public.products using gin(name gin_trgm_ops);
create index idx_products_barcode       on public.products(barcode);
create index idx_products_category      on public.products(category_id);
create index idx_products_brand         on public.products(brand_id);
create index idx_products_published     on public.products(is_published) where is_published = true;
create index idx_products_slug          on public.products(slug);

-- Compound FTS index (name + ingredients)
create index idx_products_fts on public.products
  using gin(to_tsvector('english', coalesce(name,'') || ' ' || coalesce(ingredients,'')));

-- ============================================================
-- 4. NUTRIENTS (master list — flexible, not hardcoded columns)
-- ============================================================
create table public.nutrients (
  id            uuid primary key default uuid_generate_v4(),
  name          text not null,
  slug          text not null unique,
  unit          text not null,  -- 'g', 'mg', 'kcal', 'µg', '%'
  description   text,
  display_order int  not null default 99,
  created_at    timestamptz not null default now()
);

-- ============================================================
-- 5. PRODUCT NUTRIENTS (flexible join table)
-- ============================================================
create table public.product_nutrients (
  id               uuid primary key default uuid_generate_v4(),
  product_id       uuid not null references public.products(id) on delete cascade,
  nutrient_id      uuid not null references public.nutrients(id) on delete cascade,
  value_per_100g   numeric(10, 4),
  value_per_serving numeric(10, 4),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint uq_product_nutrient unique (product_id, nutrient_id),
  -- Validation: values must be non-negative
  constraint chk_value_per_100g   check (value_per_100g   is null or value_per_100g   >= 0),
  constraint chk_value_per_serving check (value_per_serving is null or value_per_serving >= 0)
);

create index idx_product_nutrients_product on public.product_nutrients(product_id);
create index idx_product_nutrients_nutrient on public.product_nutrients(nutrient_id);

-- ============================================================
-- 6. PRODUCT CHANGE HISTORY
-- ============================================================
create table public.product_change_history (
  id            uuid primary key default uuid_generate_v4(),
  product_id    uuid not null references public.products(id) on delete cascade,
  changed_by    text,           -- admin user email/id
  field_changed text not null,
  old_value     text,
  new_value     text,
  changed_at    timestamptz not null default now()
);

create index idx_change_history_product on public.product_change_history(product_id);
create index idx_change_history_time    on public.product_change_history(changed_at desc);

-- ============================================================
-- 7. PRODUCT REQUESTS (user-submitted)
-- ============================================================
create table public.product_requests (
  id              uuid primary key default uuid_generate_v4(),
  product_name    text not null,
  brand           text,
  barcode         text,
  photo_url       text,
  label_photo_url text,
  message         text,
  status          text not null default 'pending'
                  check (status in ('pending','in_review','fulfilled','rejected')),
  reviewed_by     text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_product_requests_status on public.product_requests(status);

-- ============================================================
-- 8. UPDATED_AT TRIGGERS
-- ============================================================
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_categories_updated   before update on public.categories   for each row execute function public.set_updated_at();
create trigger trg_brands_updated       before update on public.brands       for each row execute function public.set_updated_at();
create trigger trg_products_updated     before update on public.products     for each row execute function public.set_updated_at();
create trigger trg_pn_updated           before update on public.product_nutrients for each row execute function public.set_updated_at();
create trigger trg_requests_updated     before update on public.product_requests  for each row execute function public.set_updated_at();

-- ============================================================
-- 9. ROW LEVEL SECURITY
-- ============================================================

-- Categories: public read, admin write
alter table public.categories enable row level security;
create policy "categories_public_read"  on public.categories for select using (is_active = true);
create policy "categories_admin_write"  on public.categories for all using (auth.role() = 'authenticated');

-- Brands: public read
alter table public.brands enable row level security;
create policy "brands_public_read"  on public.brands for select using (is_active = true);
create policy "brands_admin_write"  on public.brands for all using (auth.role() = 'authenticated');

-- Products: only published visible to public
alter table public.products enable row level security;
create policy "products_public_read"  on public.products for select using (is_published = true);
create policy "products_admin_all"    on public.products for all using (auth.role() = 'authenticated');

-- Nutrients: public read
alter table public.nutrients enable row level security;
create policy "nutrients_public_read" on public.nutrients for select using (true);
create policy "nutrients_admin_write" on public.nutrients for all using (auth.role() = 'authenticated');

-- Product nutrients: public read
alter table public.product_nutrients enable row level security;
create policy "pn_public_read"  on public.product_nutrients for select using (true);
create policy "pn_admin_write"  on public.product_nutrients for all using (auth.role() = 'authenticated');

-- Change history: admin only
alter table public.product_change_history enable row level security;
create policy "history_admin_only" on public.product_change_history for all using (auth.role() = 'authenticated');

-- Product requests: anyone can insert (anonymous user reporting)
alter table public.product_requests enable row level security;
create policy "requests_public_insert" on public.product_requests for insert with check (true);
create policy "requests_admin_all"     on public.product_requests for all using (auth.role() = 'authenticated');

-- ============================================================
-- 10. HELPER VIEWS
-- ============================================================

-- Product card view (for list pages — no nutrients, lighter query)
create or replace view public.product_cards as
select
  p.id, p.name, p.slug, p.barcode, p.image_url,
  p.diet_type, p.verification_status, p.is_published,
  p.serving_size, p.serving_unit,
  p.created_at, p.updated_at,
  b.id   as brand_id,   b.name  as brand_name,   b.logo_url as brand_logo,
  c.id   as category_id, c.name as category_name, c.slug     as category_slug,
  -- Inline calories & protein for card display
  (select value_per_100g from product_nutrients pn
     join nutrients n on n.id = pn.nutrient_id
     where pn.product_id = p.id and n.slug = 'energy_kcal' limit 1) as calories_per_100g,
  (select value_per_100g from product_nutrients pn
     join nutrients n on n.id = pn.nutrient_id
     where pn.product_id = p.id and n.slug = 'protein' limit 1) as protein_per_100g,
  (select value_per_100g from product_nutrients pn
     join nutrients n on n.id = pn.nutrient_id
     where pn.product_id = p.id and n.slug = 'sugar' limit 1) as sugar_per_100g
from public.products p
left join public.brands     b on b.id = p.brand_id
left join public.categories c on c.id = p.category_id
where p.is_published = true;

-- ============================================================
-- 11. SEARCH FUNCTION (server-side, with filters)
-- ============================================================
create or replace function public.search_products(
  p_query          text default '',
  p_category_id    uuid default null,
  p_brand_id       uuid default null,
  p_diet_type      text default null,
  p_min_calories   numeric default null,
  p_max_calories   numeric default null,
  p_min_protein    numeric default null,
  p_max_protein    numeric default null,
  p_min_sugar      numeric default null,
  p_max_sugar      numeric default null,
  p_limit          int  default 20,
  p_offset         int  default 0
)
returns table (
  id                uuid, name text, slug text, barcode text, image_url text,
  diet_type text, verification_status text, serving_size numeric, serving_unit text,
  brand_id uuid, brand_name text, brand_logo text,
  category_id uuid, category_name text, category_slug text,
  calories_per_100g numeric, protein_per_100g numeric, sugar_per_100g numeric,
  total_count bigint
)
language plpgsql stable as $$
declare
  cal_nutrient_id  uuid;
  prot_nutrient_id uuid;
  sugar_nutrient_id uuid;
begin
  select id into cal_nutrient_id  from nutrients where slug = 'energy_kcal';
  select id into prot_nutrient_id from nutrients where slug = 'protein';
  select id into sugar_nutrient_id from nutrients where slug = 'sugar';

  return query
  with base as (
    select p.*,
      b.id as b_id, b.name as b_name, b.logo_url as b_logo,
      c.id as c_id, c.name as c_name, c.slug as c_slug,
      (select pn.value_per_100g from product_nutrients pn where pn.product_id = p.id and pn.nutrient_id = cal_nutrient_id limit 1)  as cal,
      (select pn.value_per_100g from product_nutrients pn where pn.product_id = p.id and pn.nutrient_id = prot_nutrient_id limit 1) as prot,
      (select pn.value_per_100g from product_nutrients pn where pn.product_id = p.id and pn.nutrient_id = sugar_nutrient_id limit 1) as sug
    from products p
    left join brands     b on b.id = p.brand_id
    left join categories c on c.id = p.category_id
    where p.is_published = true
      and (p_category_id is null or p.category_id = p_category_id)
      and (p_brand_id    is null or p.brand_id    = p_brand_id)
      and (p_diet_type   is null or p.diet_type   = p_diet_type)
      and (
        p_query = '' or
        p.name        ilike '%' || p_query || '%' or
        b.name        ilike '%' || p_query || '%' or
        p.barcode            = p_query            or
        p.ingredients ilike '%' || p_query || '%'
      )
  ),
  filtered as (
    select base.*
    from base
    where (p_min_calories is null or base.cal  >= p_min_calories)
      and (p_max_calories is null or base.cal  <= p_max_calories)
      and (p_min_protein  is null or base.prot >= p_min_protein)
      and (p_max_protein  is null or base.prot <= p_max_protein)
      and (p_min_sugar    is null or base.sug  >= p_min_sugar)
      and (p_max_sugar    is null or base.sug  <= p_max_sugar)
  )
  select
    f.id, f.name, f.slug, f.barcode, f.image_url,
    f.diet_type, f.verification_status, f.serving_size, f.serving_unit,
    f.b_id, f.b_name, f.b_logo,
    f.c_id, f.c_name, f.c_slug,
    f.cal, f.prot, f.sug,
    count(*) over () as total_count
  from filtered f
  order by
    case when p_query != '' then similarity(f.name, p_query) else 0 end desc,
    f.created_at desc
  limit p_limit offset p_offset;
end;
$$;

-- ============================================================
-- 12. SEED DATA — Nutrients master list
-- ============================================================
insert into public.nutrients (name, slug, unit, description, display_order) values
  ('Energy',            'energy_kcal',   'kcal', 'Total calories',                          1),
  ('Protein',           'protein',       'g',    'Total protein',                            2),
  ('Carbohydrates',     'carbohydrates', 'g',    'Total carbohydrates',                      3),
  ('Total Fat',         'fat_total',     'g',    'Total fat',                                4),
  ('Dietary Fiber',     'fiber',         'g',    'Dietary fiber',                            5),
  ('Sugars',            'sugar',         'g',    'Total sugars',                             6),
  ('Sodium',            'sodium',        'mg',   'Sodium content',                           7),
  ('Saturated Fat',     'saturated_fat', 'g',    'Saturated fatty acids',                    8),
  ('Trans Fat',         'trans_fat',     'g',    'Trans fatty acids',                        9),
  ('Cholesterol',       'cholesterol',   'mg',   'Cholesterol',                             10),
  ('Calcium',           'calcium',       'mg',   'Calcium',                                 11),
  ('Iron',              'iron',          'mg',   'Iron',                                    12),
  ('Vitamin C',         'vitamin_c',     'mg',   'Ascorbic acid',                           13),
  ('Vitamin A',         'vitamin_a',     'µg',   'Vitamin A (retinol equivalents)',         14),
  ('Vitamin D',         'vitamin_d',     'µg',   'Cholecalciferol',                         15),
  ('Vitamin B12',       'vitamin_b12',   'µg',   'Cobalamin',                               16),
  ('Potassium',         'potassium',     'mg',   'Potassium',                               17),
  ('Zinc',              'zinc',          'mg',   'Zinc',                                    18),
  ('Omega-3',           'omega_3',       'g',    'Omega-3 fatty acids',                     19),
  ('Omega-6',           'omega_6',       'g',    'Omega-6 fatty acids',                     20);

-- ============================================================
-- 13. SEED DATA — Categories (all 34 from the spec)
-- ============================================================
insert into public.categories (name, slug, description, icon, is_active) values
  ('Biscuits',               'biscuits',               'Packaged biscuits and crackers',           '🍪', true),
  ('Namkeen',                'namkeen',                'Indian savoury snacks',                    '🥜', true),
  ('Soft Drinks',            'soft-drinks',            'Carbonated and non-carbonated soft drinks', '🥤', true),
  ('Energy Drinks',          'energy-drinks',          'Caffeinated and energy beverages',         '⚡', true),
  ('Chips & Wafers',         'chips-wafers',           'Potato chips, corn chips, wafers',         '🥔', true),
  ('Packaged Snacks',        'packaged-snacks',        'General packaged snack foods',             '🍿', true),
  ('Packaged Foods',         'packaged-foods',         'Processed and packaged food items',        '📦', true),
  ('Instant Noodles',        'instant-noodles',        'Instant and cup noodles',                  '🍜', true),
  ('Cookies',                'cookies',                'Sweet cookies and biscuits',               '🍪', true),
  ('Chocolates',             'chocolates',             'Chocolate bars and confectionery',         '🍫', true),
  ('Candy',                  'candy',                  'Candies, toffees, and gummies',            '🍬', true),
  ('Ice Cream',              'ice-cream',              'Ice creams, kulfi, and frozen desserts',   '🍦', true),
  ('Dairy Products',         'dairy-products',         'Milk, yogurt, cheese, butter, paneer',     '🥛', true),
  ('Fried Snacks',           'fried-snacks',           'Fried and deep-fried snack items',         '🍟', true),
  ('Bakery Products',        'bakery-products',        'Cakes, pastries, rolls, muffins',          '🥐', true),
  ('Sauces & Spreads',       'sauces-spreads',         'Ketchup, jams, peanut butter, spreads',    '🫙', true),
  ('Pickles',                'pickles',                'Achaar and pickled products',              '🫙', true),
  ('Ready-to-Eat',           'ready-to-eat',           'Frozen and ready-to-eat meals',            '🍱', true),
  ('Bread',                  'bread',                  'Bread, buns, and sliced bread',            '🍞', true),
  ('Juices',                 'juices',                 'Packaged fruit juices and drinks',         '🧃', true),
  ('Flavoured Milk',         'flavoured-milk',         'Chocolate, strawberry, and other milk',    '🥛', true),
  ('Tea',                    'tea',                    'Packaged tea and tea bags',                '🍵', true),
  ('Coffee',                 'coffee',                 'Packaged coffee and instant coffee',       '☕', true),
  ('Health & Protein',       'health-protein',         'Protein powders, health supplements',      '💪', true),
  ('Cereals',                'cereals',                'Breakfast cereals and oats',               '🥣', true),
  ('Nuts & Seeds',           'nuts-seeds',             'Packaged nuts, seeds, and dry fruits',     '🥜', true),
  ('Staples',                'staples',                'Rice, flour, pulses, and spices',          '🌾', true),
  ('Fruits',                 'fruits',                 'Fresh and packaged fruits',                '🍎', true),
  ('Vegetables',             'vegetables',             'Fresh and packaged vegetables',            '🥦', true),
  ('Meat',                   'meat',                   'Packaged meat and poultry products',       '🥩', true),
  ('Eggs',                   'eggs',                   'Eggs and egg products',                    '🥚', true),
  ('Seafood',                'seafood',                'Fish, prawns, and seafood products',       '🐟', true),
  ('Flavoured Water',        'flavoured-water',        'Flavoured and functional waters',          '💧', true),
  ('Frozen Foods',           'frozen-foods',           'Frozen meals, vegetables, and products',   '🧊', true);
