import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String imageUrl;
  final String userType; // 'customer', 'provider'
  final bool isActive;
  final bool isBlocked;
  final bool isOnline;
  final String? fcmToken;
  final Subscription subscription;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  
  // Provider specific fields
  final String? categoryId;
  final List<String>? services;
  final String? governorateId;
  final List<String>? cities;
  final String? about;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.imageUrl,
    this.userType = 'customer',
    this.isActive = true,
    this.isBlocked = false,
    this.isOnline = false,
    this.fcmToken,
    required this.subscription,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.categoryId,
    this.services,
    this.governorateId,
    this.cities,
    this.about,
  });

  /// Returns a copy with the given fields replaced. Provider-specific fields
  /// and every other attribute are preserved (previously rebuilding a model by
  /// hand silently dropped them).
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? imageUrl,
    bool? isActive,
    bool? isBlocked,
    bool? isOnline,
    String? fcmToken,
    Subscription? subscription,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      userType: userType,
      isActive: isActive ?? this.isActive,
      isBlocked: isBlocked ?? this.isBlocked,
      isOnline: isOnline ?? this.isOnline,
      fcmToken: fcmToken ?? this.fcmToken,
      subscription: subscription ?? this.subscription,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      categoryId: categoryId,
      services: services,
      governorateId: governorateId,
      cities: cities,
      about: about,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      userType: (json['user_type'] ?? 'customer').toString(),
      isActive: json['is_active'] ?? true,
      isBlocked: json['is_blocked'] ?? false,
      isOnline: json['is_online'] ?? false,
      fcmToken: json['fcm_token'],
      subscription: Subscription.fromJson(
        json['subscription'] is Map
            ? Map<String, dynamic>.from(json['subscription'] as Map)
            : <String, dynamic>{},
      ),
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
      lastLoginAt: (json['last_login_at'] as Timestamp?)?.toDate(),
      categoryId: json['category_id'],
      services: (json['services'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      governorateId: json['governorate_id'],
      cities: (json['cities'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      about: json['about'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'image_url': imageUrl,
      'user_type': userType,
      'is_active': isActive,
      'is_blocked': isBlocked,
      'is_online': isOnline,
      if (fcmToken != null) 'fcm_token': fcmToken,
      'subscription': subscription.toJson(),
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(), // Always update timestamp on save
      'last_login_at': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : FieldValue.serverTimestamp(),
      if (categoryId != null) 'category_id': categoryId,
      if (services != null) 'services': services,
      if (governorateId != null) 'governorate_id': governorateId,
      if (cities != null) 'cities': cities,
      if (about != null) 'about': about,
    };
  }
}

class Subscription {
  final bool isSubscribed;
  final String? plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  Subscription({
    this.isSubscribed = false,
    this.plan,
    this.startDate,
    this.endDate,
    this.isActive = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      isSubscribed: json['is_subscribed'] ?? false,
      plan: json['plan'],
      startDate: (json['start_date'] as Timestamp?)?.toDate(),
      endDate: (json['end_date'] as Timestamp?)?.toDate(),
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_subscribed': isSubscribed,
      if (plan != null) 'plan': plan,
      if (startDate != null) 'start_date': Timestamp.fromDate(startDate!),
      if (endDate != null) 'end_date': Timestamp.fromDate(endDate!),
      'is_active': isActive,
    };
  }
}
