import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/network/firebase_config.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  Future<List<ServiceModel>> getServicesByCategory(String categoryId) async {
    try {
      debugPrint('⏳ Loading services for category: $categoryId...');
      Query<Map<String, dynamic>> query = _firestore.collection('services');
      
      if (categoryId != 'all') {
        query = query.where('category_id', isEqualTo: categoryId);
      }
      
      final snapshot = await query.get();
      
      final servicesList = snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .where((service) => service.available)
          .toList();
          
      debugPrint('✅ Successfully loaded ${servicesList.length} services! 🚀');
      return servicesList;
    } catch (e) {
      debugPrint('❌ Error fetching services by category: $e 😢');
      return [];
    }
  }

  Future<List<ServiceModel>> getPopularServices() async {
    try {
      debugPrint('⏳ Loading popular services...');
      final snapshot = await _firestore
          .collection('services')
          .where('show_in_home', isEqualTo: true)
          .get();
      
      final servicesList = snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .where((service) => service.available)
          .toList();
          
      debugPrint('✅ Successfully loaded ${servicesList.length} popular services! 🚀');
      return servicesList;
    } catch (e) {
      debugPrint('❌ Error fetching popular services: $e 😢');
      return [];
    }
  }
}
