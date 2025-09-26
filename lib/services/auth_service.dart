import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth change user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Notify listeners that the auth state has changed
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Make sure to notify listeners even on error
      notifyListeners();
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(
          userCredential.user!,
          name: name,
        );
        // Notify listeners that the auth state has changed
        notifyListeners();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Make sure to notify listeners even on error
      notifyListeners();
      throw _handleAuthException(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, {required String name}) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      // Create user data
      final userData = {
        'email': user.email,
        'name': name,
        'role': 'customer', // Default role is customer
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Set the document with merge: true to avoid overwriting if it already exists
      await userDoc.set(userData, SetOptions(merge: true));
      debugPrint('User document created/updated for ${user.uid}');
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }

  // Get user data
  Stream<AppUser?> get userData {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          return AppUser.fromMap(doc.data()!, doc.id);
        } else {
          // If document doesn't exist, create it
          await _createUserDocument(user, name: user.displayName ?? 'New User');
          // Get the newly created document
          final newDoc = await _firestore.collection('users').doc(user.uid).get();
          if (newDoc.exists && newDoc.data() != null) {
            return AppUser.fromMap(newDoc.data()!, newDoc.id);
          }
        }
        return null;
      } catch (e) {
        debugPrint('Error getting user data: $e');
        return null;
      }
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    // Notify listeners that the auth state has changed
    notifyListeners();
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
