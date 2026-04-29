import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, onProgress, done, cancelled }

enum VehicleType { car, motorcycle }

class BookingModel {
  final String id;
  final String userId;
  final String serviceId;
  final Map<String, String> vehicleData;
  final BookingStatus status;
  final VehicleType vehicleType;
  final String notes;
  final DateTime? createdAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.vehicleData,
    this.status = BookingStatus.pending,
    this.vehicleType = VehicleType.car,
    this.notes = '',
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json, String id) {
    return BookingModel(
      id: id,
      userId: json['user_id'] ?? '',
      serviceId: json['service_id'] ?? '',
      vehicleData: Map<String, String>.from(json['vehicle_data'] ?? {}),
      status: _statusFromString(json['status']),
      vehicleType: _vehicleTypeFromString(json['vehicle_type']),
      notes: json['notes'] ?? '',
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
      'vehicle_type': vehicleType.name,
      'notes': notes,
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

  static VehicleType _vehicleTypeFromString(String? type) {
    switch (type) {
      case 'motorcycle':
        return VehicleType.motorcycle;
      case 'car':
      default:
        return VehicleType.car;
    }
  }
}
