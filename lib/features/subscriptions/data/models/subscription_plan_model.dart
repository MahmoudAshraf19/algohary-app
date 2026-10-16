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
      // Admin tools often store numbers (price / expiryDay) as numeric fields;
      // assigning them straight to a String threw a TypeError and broke the screen.
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      expiryDay: (data['expiryDay'] ?? '0').toString(),
      price: (data['price'] ?? '0').toString(),
      type: (data['type'] ?? 'free').toString(),
      image: (data['image'] ?? '').toString(),
      isEnable: data['isEnable'] ?? true,
      itemLimit: data['itemLimit']?.toString() ?? '0',
      orderLimit: data['orderLimit']?.toString() ?? '0',
      features: Map<String, dynamic>.from(data['features'] ?? {}),
      planPoints: (data['plan_points'] as List? ?? const []).map((e) => e.toString()).toList(),
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
