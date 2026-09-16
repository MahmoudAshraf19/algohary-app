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

      final allProviders = snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
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
}
