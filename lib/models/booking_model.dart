import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String serviceId;
  final String status;
  final Timestamp createdAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      userId: map['userId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'serviceId': serviceId,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
