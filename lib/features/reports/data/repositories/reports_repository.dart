import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/network/firebase_config.dart';
import '../models/report_model.dart';

class ReportsRepository {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  Future<void> submitReport(ReportModel report) async {
    try {
      await _firestore.collection('reports').doc(report.id).set(report.toMap());
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }
}
