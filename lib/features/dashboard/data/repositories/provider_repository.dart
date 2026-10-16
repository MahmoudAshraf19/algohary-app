import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:algohary_project/features/auth/data/models/user_model.dart';
import 'package:algohary_project/core/network/firebase_config.dart';

class ProviderRepository {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  Future<List<UserModel>> getProvidersByService(String serviceId) async {
    debugPrint('🔍 [ProviderRepository] Fetching providers for service ID: $serviceId');
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('user_type', isEqualTo: 'provider')
          .where('services', arrayContains: serviceId)
          .get();

      debugPrint('✅ [ProviderRepository] Found ${snapshot.docs.length} providers for $serviceId');
      
      final providers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).where((u) => !u.isBlocked).toList(); // never offer blocked providers for booking
      
      debugPrint('✅ [ProviderRepository] Successfully parsed ${providers.length} providers');
      return providers;
    } catch (e) {
      debugPrint('❌ [ProviderRepository] Error fetching providers: $e');
      throw Exception('Failed to load providers: $e');
    }
  }

  Iterable<List<String>> _chunks(List<String> items, int size) sync* {
    for (var i = 0; i < items.length; i += size) {
      yield items.sublist(i, i + size > items.length ? items.length : i + size);
    }
  }

  final Map<String, Map<String, String>> _governoratesCache = {};

  Future<String> getGovernorateName(String governorateId, String langCode) async {
    if (_governoratesCache.containsKey(governorateId)) {
      return _governoratesCache[governorateId]?[langCode] ?? '';
    }
    
    try {
      final doc = await _firestore.collection('governorates').doc(governorateId).get();

      if (doc.exists) {
        final data = doc.data()!;
        _governoratesCache[governorateId] = {
          'ar': data['governorate_name_ar'] ?? '',
          'en': data['governorate_name_en'] ?? '',
        };
        return _governoratesCache[governorateId]?[langCode] ?? '';
      }
      return '';
    } catch (e) {
      debugPrint('❌ [ProviderRepository] Error fetching governorate: $e');
      return '';
    }
  }

  Future<List<UserModel>> searchProviders(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('user_type', isEqualTo: 'provider')
          .get();

      final allProviders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).where((u) => !u.isBlocked).toList();
      if (query.isEmpty) return allProviders;
      
      final q = query.toLowerCase();
      return allProviders.where((p) {
        return p.firstName.toLowerCase().contains(q) || p.lastName.toLowerCase().contains(q);
      }).toList();
    } catch (e) {
      debugPrint('❌ [ProviderRepository] Error searching providers: $e');
      return [];
    }
  }

  Future<Map<String, String>?> getCategoryDetails(String categoryId, String langCode) async {
    try {
      final doc = await _firestore.collection('categories').doc(categoryId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final nameAr = data['name_ar'] ?? '';
        final nameEn = data['name_en'] ?? '';
        return {
          'name': langCode == 'ar' ? nameAr : nameEn,
          'icon_url': data['icon_url'] ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching category details: $e');
      return null;
    }
  }

  Future<List<String>> getCityNames(List<String> cityIds, String langCode) async {
    if (cityIds.isEmpty) return [];
    
    try {
      // `whereIn` accepts at most 10 values and the old `.take(10)` silently
      // dropped every city after the tenth. Query in chunks instead.
      final names = <String>[];
      for (final chunk in _chunks(cityIds, 10)) {
        final snapshot = await _firestore.collection('cities')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          names.add(((langCode == 'ar' ? data['city_name_ar'] : data['city_name_en']) ?? '').toString());
        }
      }
      return names;
    } catch (e) {
      debugPrint('❌ Error fetching city names: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getServiceDetails(List<String> serviceIds, String langCode) async {
    if (serviceIds.isEmpty) return [];
    
    try {
      // whereIn only supports up to 10 elements: query in chunks (the previous
      // `.take(10)` silently hid the remaining services of a provider).
      final result = <Map<String, String>>[];
      for (final chunk in _chunks(serviceIds, 10)) {
        final snapshot = await _firestore.collection('services')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final nameAr = data['name_ar'] ?? '';
          final nameEn = data['name_en'] ?? '';
          result.add(<String, String>{
            'id': doc.id,
            'name': (langCode == 'ar' ? nameAr : nameEn).toString(),
            'icon_url': (data['icon_url'] ?? '').toString(),
          });
        }
      }
      return result;
    } catch (e) {
      debugPrint('❌ Error fetching service details: $e');
      return [];
    }
  }
}
