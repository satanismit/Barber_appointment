import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new appointment
  Future<Appointment> createAppointment({
    required String userId,
    required String userName,
    required String userEmail,
    required DateTime dateTime,
    required String serviceType,
    String? notes,
  }) async {
    try {
      final docRef = await _firestore.collection('appointments').add({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'dateTime': Timestamp.fromDate(dateTime),
        'serviceType': serviceType,
        'status': 'pending', // Default status
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Return the created appointment
      return Appointment(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        dateTime: dateTime,
        serviceType: serviceType,
        status: 'pending',
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Get all appointments (admin view)
  Stream<List<Appointment>> getAllAppointments() {
    return _firestore
        .collection('appointments')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get accepted appointments in chronological order
  Stream<List<Appointment>> getAcceptedAppointments() {
    return _firestore
        .collection('appointments')
        .where('status', isEqualTo: 'accepted')
        .orderBy('dateTime', descending: false) // Oldest first
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get user's appointments
  Stream<List<Appointment>> getUserAppointments(String userId) {
    try {
      debugPrint('Fetching appointments for user: $userId');
      return _firestore
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .orderBy('dateTime', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('Error fetching appointments: $error');
            throw error;
          })
          .map((snapshot) {
            debugPrint('Found ${snapshot.docs.length} appointments');
            return snapshot.docs.map((doc) {
              try {
                return Appointment.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              } catch (e) {
                debugPrint('Error parsing appointment ${doc.id}: $e');
                debugPrint('Data: ${doc.data()}');
                rethrow;
              }
            }).toList();
          });
    } catch (e) {
      debugPrint('Error in getUserAppointments: $e');
      rethrow;
    }
  }

  // Check if a time slot is available
  Future<bool> isTimeSlotAvailable(DateTime dateTime) async {
    try {
      // Check for existing appointments within 1 hour before and after the requested time
      final startTime = dateTime.subtract(const Duration(hours: 1));
      final endTime = dateTime.add(const Duration(hours: 1));

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('dateTime', isGreaterThanOrEqualTo: startTime)
          .where('dateTime', isLessThanOrEqualTo: endTime)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      // If there are no appointments in the time slot, it's available
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check time slot availability: $e');
    }
  }

  // Delete an appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }
}
