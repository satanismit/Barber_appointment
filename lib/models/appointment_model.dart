import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime dateTime;
  final String serviceType;
  final String status; // 'pending', 'accepted', 'rejected', 'completed', 'cancelled'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.dateTime,
    required this.serviceType,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromMap(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      serviceType: data['serviceType'] ?? 'Haircut',
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'dateTime': Timestamp.fromDate(dateTime),
      'serviceType': serviceType,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
