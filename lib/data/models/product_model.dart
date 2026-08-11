import 'brand_model.dart';
import 'category_model.dart';
import 'nutrient_model.dart';

enum DietType { veg, nonVeg, vegan, unknown }

enum VerificationStatus {
  unverified,
  imported,
  underReview,
  verified,
  outdated,
}

extension DietTypeExtension on DietType {
  String get label => switch (this) {
        DietType.veg => 'Vegetarian',
        DietType.nonVeg => 'Non-Vegetarian',
        DietType.vegan => 'Vegan',
        DietType.unknown => 'Unknown',
      };

  static DietType fromString(String? value) => switch (value?.toLowerCase()) {
        'veg' => DietType.veg,
        'non_veg' || 'nonveg' => DietType.nonVeg,
        'vegan' => DietType.vegan,
        _ => DietType.unknown,
      };
}

extension VerificationStatusExtension on VerificationStatus {
  String get label => switch (this) {
        VerificationStatus.unverified => 'Unverified',
        VerificationStatus.imported => 'Imported',
        VerificationStatus.underReview => 'Under Review',
        VerificationStatus.verified => 'Verified',
        VerificationStatus.outdated => 'Outdated',
      };

  static VerificationStatus fromString(String? value) =>
      switch (value?.toLowerCase()) {
        'unverified' => VerificationStatus.unverified,
        'imported' => VerificationStatus.imported,
        'under_review' => VerificationStatus.underReview,
        'verified' => VerificationStatus.verified,
        'outdated' => VerificationStatus.outdated,
        _ => VerificationStatus.unverified,
      };
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.brand,
    this.brandId,
    this.category,
    this.categoryId,
    this.subcategoryId,
    this.barcode,
    this.description,
    this.imageUrl,
    this.servingSize,
    this.servingUnit,
    this.ingredients,
    this.allergens,
    this.mayContainAllergens,
    this.dietType = DietType.unknown,
    this.manufacturer,
    this.country,
    this.source,
    this.verificationStatus = VerificationStatus.unverified,
    this.isPublished = false,
    this.nutrients = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final BrandModel? brand;
  final String? brandId;
  final CategoryModel? category;
  final String? categoryId;
  final String? subcategoryId;
  final String? barcode;
  final String? description;
  final String? imageUrl;
  final double? servingSize;
  final String? servingUnit;
  final String? ingredients;
  final List<String>? allergens;
  final List<String>? mayContainAllergens;
  final DietType dietType;
  final String? manufacturer;
  final String? country;
  final String? source;
  final VerificationStatus verificationStatus;
  final bool isPublished;
  final List<ProductNutrientModel> nutrients;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Look up a nutrient value by slug (per 100g).
  double? getNutrientPer100g(String slug) {
    try {
      return nutrients
          .firstWhere((n) => n.nutrient.slug == slug)
          .valuePer100g;
    } catch (_) {
      return null;
    }
  }

  /// Look up a nutrient value by slug (per serving).
  double? getNutrientPerServing(String slug) {
    try {
      return nutrients
          .firstWhere((n) => n.nutrient.slug == slug)
          .valuePerServing;
    } catch (_) {
      return null;
    }
  }

  bool get isVerified =>
      verificationStatus == VerificationStatus.verified;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      brand: json['brand'] != null
          ? BrandModel.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
      brandId: json['brand_id'] as String?,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      categoryId: json['category_id'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      servingSize: (json['serving_size'] as num?)?.toDouble(),
      servingUnit: json['serving_unit'] as String?,
      ingredients: json['ingredients'] as String?,
      allergens: json['allergens'] != null
          ? List<String>.from(json['allergens'] as List)
          : null,
      mayContainAllergens: json['may_contain_allergens'] != null
          ? List<String>.from(json['may_contain_allergens'] as List)
          : null,
      dietType:
          DietTypeExtension.fromString(json['diet_type'] as String?),
      manufacturer: json['manufacturer'] as String?,
      country: json['country'] as String?,
      source: json['source'] as String?,
      verificationStatus: VerificationStatusExtension.fromString(
        json['verification_status'] as String?,
      ),
      isPublished: (json['is_published'] as bool?) ?? false,
      nutrients: json['product_nutrients'] != null
          ? (json['product_nutrients'] as List)
              .map((e) => ProductNutrientModel.fromJson(
                    e as Map<String, dynamic>,
                  ))
              .toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  ProductModel copyWith({
    List<ProductNutrientModel>? nutrients,
    VerificationStatus? verificationStatus,
    bool? isPublished,
  }) {
    return ProductModel(
      id: id,
      name: name,
      slug: slug,
      brand: brand,
      brandId: brandId,
      category: category,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      barcode: barcode,
      description: description,
      imageUrl: imageUrl,
      servingSize: servingSize,
      servingUnit: servingUnit,
      ingredients: ingredients,
      allergens: allergens,
      mayContainAllergens: mayContainAllergens,
      dietType: dietType,
      manufacturer: manufacturer,
      country: country,
      source: source,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isPublished: isPublished ?? this.isPublished,
      nutrients: nutrients ?? this.nutrients,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProductModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
