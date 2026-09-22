import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algohary_project/features/auth/data/models/user_model.dart';
import 'package:algohary_project/core/network/firebase_config.dart';

class ProviderRepository {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  Future<List<UserModel>> getProvidersByService(String serviceId) async {
    print('🔍 [ProviderRepository] Fetching providers for service ID: $serviceId');
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('user_type', isEqualTo: 'provider')
          .where('services', arrayContains: serviceId)
          .get();

      print('✅ [ProviderRepository] Found ${snapshot.docs.length} providers for $serviceId');
      
      final providers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        print('   -> Parsing provider: ${data['first_name']} ${data['last_name']} (ID: ${doc.id})');
        return UserModel.fromJson(data);
      }).toList();
      
      print('✅ [ProviderRepository] Successfully parsed ${providers.length} providers');
      return providers;
    } catch (e) {
      print('❌ [ProviderRepository] Error fetching providers: $e');
      throw Exception('Failed to load providers: $e');
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
      print('❌ [ProviderRepository] Error fetching governorate: $e');
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
      }).toList();
      if (query.isEmpty) return allProviders;
      
      final q = query.toLowerCase();
      return allProviders.where((p) {
        return p.firstName.toLowerCase().contains(q) || p.lastName.toLowerCase().contains(q);
      }).toList();
    } catch (e) {
      print('❌ [ProviderRepository] Error searching providers: $e');
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
      print('❌ Error fetching category details: $e');
      return null;
    }
  }

  Future<List<String>> getCityNames(List<String> cityIds, String langCode) async {
    if (cityIds.isEmpty) return [];
    
    try {
      final snapshot = await _firestore.collection('cities')
          .where(FieldPath.documentId, whereIn: cityIds.take(10).toList())
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return langCode == 'ar' ? (data['city_name_ar'] ?? '') : (data['city_name_en'] ?? '');
      }).cast<String>().toList();
    } catch (e) {
      print('❌ Error fetching city names: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getServiceDetails(List<String> serviceIds, String langCode) async {
    if (serviceIds.isEmpty) return [];
    
    try {
      // Note: whereIn only supports up to 10 elements
      final snapshot = await _firestore.collection('services')
          .where(FieldPath.documentId, whereIn: serviceIds.take(10).toList())
          .get();
          
      return snapshot.docs.map<Map<String, String>>((doc) {
        final data = doc.data();
        final nameAr = data['name_ar'] ?? '';
        final nameEn = data['name_en'] ?? '';
        return <String, String>{
          'id': doc.id,
          'name': (langCode == 'ar' ? nameAr : nameEn).toString(),
          'icon_url': (data['icon_url'] ?? '').toString(),
        };
      }).toList();
    } catch (e) {
      print('❌ Error fetching service details: $e');
      return [];
    }
  }
}
