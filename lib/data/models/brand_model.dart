class BrandModel {
  const BrandModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description,
    this.website,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? description;
  final String? website;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      website: json['website'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo_url': logoUrl,
        'description': description,
        'website': website,
        'is_active': isActive,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BrandModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
