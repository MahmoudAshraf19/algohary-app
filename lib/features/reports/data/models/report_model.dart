import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String bookingId;
  final String reporterId;
  final String phone;
  final String email;
  final String details;
  final DateTime timestamp;
  final String status;

  ReportModel({
    required this.id,
    required this.bookingId,
    required this.reporterId,
    required this.phone,
    required this.email,
    required this.details,
    required this.timestamp,
    this.status = 'open',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'reporterId': reporterId,
      'phone': phone,
      'email': email,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReportModel(
      id: documentId,
      bookingId: map['bookingId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      details: map['details'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'open',
    );
  }
}
