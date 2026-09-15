import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const String _databaseId = 'algohary';

  // Singleton pattern for Firestore instance targeting the specific database
  static FirebaseFirestore get firestore {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: _databaseId,
    );
  }
}
