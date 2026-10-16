import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/firebase_config.dart';
import '../models/emergency_service_item.dart';

class EmergencyRepository {
  final FirebaseFirestore _firestore;

  EmergencyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseConfig.firestore;

  // Fallback static items in case Firestore collection isn't loaded or network drops
  static final List<EmergencyServiceItem> defaultItems = [
    const EmergencyServiceItem(
      id: 'ambulance',
      nameAr: 'الإسعاف',
      nameEn: 'Ambulance',
      contactNumber: '123',
      iconUrl:
          'https://firebasestorage.googleapis.com/v0/b/naslookapp-ecf15.firebasestorage.app/o/Emergency_icons%2FAmbulance.svg?alt=media&token=59dff648-534b-4c40-8d42-4568208bd16f',
      isAvailable: true,
    ),
    const EmergencyServiceItem(
      id: 'police',
      nameAr: 'الشرطة',
      nameEn: 'Police',
      contactNumber: '122',
      iconUrl:
          'https://firebasestorage.googleapis.com/v0/b/naslookapp-ecf15.firebasestorage.app/o/Emergency_icons%2Fpolice.svg?alt=media&token=6e55890c-7e85-4057-b190-940c84fd799e',
      isAvailable: true,
    ),
    const EmergencyServiceItem(
      id: 'fire_department',
      nameAr: 'المطافئ',
      nameEn: 'Fire Department',
      contactNumber: '180',
      iconUrl:
          'https://firebasestorage.googleapis.com/v0/b/naslookapp-ecf15.firebasestorage.app/o/Emergency_icons%2Ffire-extinguisher.svg?alt=media&token=10478bb5-4c7a-42d3-926a-98f681674916',
      isAvailable: true,
    ),
    const EmergencyServiceItem(
      id: 'traffic',
      nameAr: 'المرور',
      nameEn: 'Traffic',
      contactNumber: '128',
      iconUrl:
          'https://firebasestorage.googleapis.com/v0/b/naslookapp-ecf15.firebasestorage.app/o/Emergency_icons%2FTraffic.svg?alt=media&token=dfe646fa-f70e-4d03-aaa1-0040d9522c28',
      isAvailable: true,
    ),
  ];

  Stream<List<EmergencyServiceItem>> streamEmergencyServices() {
    return _firestore
        .collection('emergency')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return defaultItems;
          }
          final items = snapshot.docs
              .map((doc) => EmergencyServiceItem.fromFirestore(doc.data(), doc.id))
              .where((item) => item.isAvailable)
              .toList();
          return items.isNotEmpty ? items : defaultItems;
        })
        // Stream.handleError cannot substitute a value (its return value is
        // ignored), so on failure the UI used to wait forever for data. Emit the
        // built-in numbers instead.
        .transform(StreamTransformer<List<EmergencyServiceItem>, List<EmergencyServiceItem>>.fromHandlers(
          handleError: (error, stackTrace, sink) {
            debugPrint('Error streaming emergency services: $error');
            sink.add(defaultItems);
          },
        ));
  }
}
