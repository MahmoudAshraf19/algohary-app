import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/network/firebase_config.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  Future<List<CategoryModel>> getCategories() async {
    try {
      print('⏳ Loading categories from Firestore...');
      final snapshot = await _firestore.collection('categories').get();
      
      final categoriesList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Inject document ID
        return CategoryModel.fromJson(data);
      }).where((cat) => cat.available).toList();
      
      print('✅ Successfully loaded ${categoriesList.length} categories from Firestore! 🚀');
      return categoriesList;
    } catch (e) {
      print('❌ Failed to load categories from Firestore: $e 😢');
      return [];
    }
  }
}
