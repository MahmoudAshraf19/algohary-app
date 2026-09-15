class CategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final bool available;
  final String imageUrl;
  final bool isAll;

  CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.available,
    required this.imageUrl,
    this.isAll = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      available: json['available'] as bool? ?? false,
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}
