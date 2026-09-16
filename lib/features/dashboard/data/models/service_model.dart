import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String categoryId;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final bool available;
  final String imageUrl;
  final bool showInHome;

  ServiceModel({
    required this.id,
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.available,
    required this.imageUrl,
    required this.showInHome,
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ServiceModel(
      id: data['id'] ?? doc.id,
      categoryId: data['category_id'] ?? '',
      nameAr: data['name_ar'] ?? '',
      nameEn: data['name_en'] ?? '',
      descriptionAr: data['description_ar'] ?? '',
      descriptionEn: data['description_en'] ?? '',
      available: data['available'] ?? false,
      imageUrl: data['image_url'] ?? '',
      showInHome: data['show_in_home'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'available': available,
      'image_url': imageUrl,
      'show_in_home': showInHome,
    };
  }
}
