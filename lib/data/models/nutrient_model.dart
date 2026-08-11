class NutrientModel {
  const NutrientModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.unit,
    this.description,
    this.displayOrder = 99,
  });

  final String id;
  final String name;
  final String slug;
  final String unit;  // 'g', 'mg', 'kcal', 'µg', '%'
  final String? description;
  final int displayOrder;

  factory NutrientModel.fromJson(Map<String, dynamic> json) {
    return NutrientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      unit: json['unit'] as String,
      description: json['description'] as String?,
      displayOrder: (json['display_order'] as int?) ?? 99,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'unit': unit,
        'description': description,
        'display_order': displayOrder,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NutrientModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class ProductNutrientModel {
  const ProductNutrientModel({
    required this.id,
    required this.productId,
    required this.nutrientId,
    required this.nutrient,
    this.valuePer100g,
    this.valuePerServing,
  });

  final String id;
  final String productId;
  final String nutrientId;
  final NutrientModel nutrient;
  final double? valuePer100g;
  final double? valuePerServing;

  factory ProductNutrientModel.fromJson(Map<String, dynamic> json) {
    return ProductNutrientModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      nutrientId: json['nutrient_id'] as String,
      nutrient: NutrientModel.fromJson(
        json['nutrient'] as Map<String, dynamic>,
      ),
      valuePer100g: (json['value_per_100g'] as num?)?.toDouble(),
      valuePerServing: (json['value_per_serving'] as num?)?.toDouble(),
    );
  }

  /// Returns the value scaled to [grams], based on per-100g.
  double? scaledValue(double grams) {
    if (valuePer100g == null) return null;
    return (valuePer100g! * grams) / 100.0;
  }
}
