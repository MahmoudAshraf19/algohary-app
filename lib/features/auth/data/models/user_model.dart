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
    this.fcmToken,
    required this.subscription,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.categoryId,
    this.services,
    this.governorateId,
    this.cities,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      imageUrl: json['image_url'] ?? '',
      userType: json['user_type'] ?? 'customer',
      isActive: json['is_active'] ?? true,
      isBlocked: json['is_blocked'] ?? false,
      fcmToken: json['fcm_token'],
      subscription: Subscription.fromJson(json['subscription'] ?? {}),
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
      lastLoginAt: (json['last_login_at'] as Timestamp?)?.toDate(),
      categoryId: json['category_id'],
      services: (json['services'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      governorateId: json['governorate_id'],
      cities: (json['cities'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
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
      if (fcmToken != null) 'fcm_token': fcmToken,
      'subscription': subscription.toJson(),
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(), // Always update timestamp on save
      'last_login_at': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : FieldValue.serverTimestamp(),
      if (categoryId != null) 'category_id': categoryId,
      if (services != null) 'services': services,
      if (governorateId != null) 'governorate_id': governorateId,
      if (cities != null) 'cities': cities,
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
