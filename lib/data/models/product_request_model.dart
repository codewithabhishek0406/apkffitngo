enum RequestStatus { pending, inReview, fulfilled, rejected }

class ProductRequestModel {
  const ProductRequestModel({
    required this.id,
    required this.productName,
    this.brand,
    this.barcode,
    this.photoUrl,
    this.labelPhotoUrl,
    this.message,
    this.status = RequestStatus.pending,
    this.createdAt,
  });

  final String id;
  final String productName;
  final String? brand;
  final String? barcode;
  final String? photoUrl;
  final String? labelPhotoUrl;
  final String? message;
  final RequestStatus status;
  final DateTime? createdAt;

  factory ProductRequestModel.fromJson(Map<String, dynamic> json) {
    return ProductRequestModel(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      brand: json['brand'] as String?,
      barcode: json['barcode'] as String?,
      photoUrl: json['photo_url'] as String?,
      labelPhotoUrl: json['label_photo_url'] as String?,
      message: json['message'] as String?,
      status: _statusFromString(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static RequestStatus _statusFromString(String? s) =>
      switch (s?.toLowerCase()) {
        'in_review' => RequestStatus.inReview,
        'fulfilled' => RequestStatus.fulfilled,
        'rejected' => RequestStatus.rejected,
        _ => RequestStatus.pending,
      };

  Map<String, dynamic> toInsertJson() => {
        'product_name': productName,
        'brand': brand,
        'barcode': barcode,
        'photo_url': photoUrl,
        'label_photo_url': labelPhotoUrl,
        'message': message,
        'status': 'pending',
      };
}
