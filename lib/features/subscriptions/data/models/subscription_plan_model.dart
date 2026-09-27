import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlanModel {
  final String id;
  final String name;
  final String description;
  final String expiryDay;
  final String price;
  final String type;
  final String image;
  final bool isEnable;
  final String itemLimit;
  final String orderLimit;
  final Map<String, dynamic> features;
  final List<String> planPoints;
  final String place;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.expiryDay,
    required this.price,
    required this.type,
    required this.image,
    required this.isEnable,
    required this.itemLimit,
    required this.orderLimit,
    required this.features,
    required this.planPoints,
    required this.place,
  });

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SubscriptionPlanModel(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      expiryDay: data['expiryDay'] ?? '0',
      price: data['price'] ?? '0',
      type: data['type'] ?? 'free',
      image: data['image'] ?? '',
      isEnable: data['isEnable'] ?? true,
      itemLimit: data['itemLimit']?.toString() ?? '0',
      orderLimit: data['orderLimit']?.toString() ?? '0',
      features: Map<String, dynamic>.from(data['features'] ?? {}),
      planPoints: List<String>.from(data['plan_points'] ?? []),
      place: data['place']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'expiryDay': expiryDay,
      'price': price,
      'type': type,
      'image': image,
      'isEnable': isEnable,
      'itemLimit': itemLimit,
      'orderLimit': orderLimit,
      'features': features,
      'plan_points': planPoints,
      'place': place,
    };
  }
}
