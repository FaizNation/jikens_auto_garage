import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, onProgress, done, cancelled }

class BookingModel {
  final String id;
  final String userId;
  final String serviceId;
  final Map<String, String> vehicleData;
  final BookingStatus status;
  final DateTime? createdAt; // Can be null locally before the server timestamp is fetched

  BookingModel({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.vehicleData,
    this.status = BookingStatus.pending,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json, String id) {
    return BookingModel(
      id: id,
      userId: json['user_id'] ?? '',
      serviceId: json['service_id'] ?? '',
      vehicleData: Map<String, String>.from(json['vehicle_data'] ?? {}),
      status: _statusFromString(json['status']),
      createdAt: json['created_at'] != null 
          ? (json['created_at'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'service_id': serviceId,
      'vehicle_data': vehicleData,
      'status': status.name,
    };
  }

  static BookingStatus _statusFromString(String? status) {
    switch (status) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'onProgress':
        return BookingStatus.onProgress;
      case 'done':
        return BookingStatus.done;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }
}
