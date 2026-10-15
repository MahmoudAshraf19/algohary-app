import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algohary_project/core/network/firebase_config.dart';
import '../models/map_provider.dart';

/// Streams providers that are online right now from Firestore.
class MapProvidersRepository {
  MapProvidersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseConfig.firestore;

  final FirebaseFirestore _firestore;

  Stream<List<MapProvider>> watchOnlineProviders({String? excludeUserId}) {
    return _firestore
        .collection('users')
        .where('user_type', isEqualTo: 'provider')
        .where('is_online', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final result = <MapProvider>[];
      for (final doc in snapshot.docs) {
        if (doc.id == excludeUserId) continue;
        final provider = MapProvider.tryParse(doc.id, doc.data());
        if (provider != null) result.add(provider);
      }
      return result;
    });
  }
}
