import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingScreen extends StatefulWidget {
  final String barberName;
  const BookingScreen({super.key, required this.barberName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? selectedSlot;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final slots = ["10:00 AM", "11:00 AM", "12:00 PM", "2:00 PM", "3:00 PM"];

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          "Book ${widget.barberName}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Select a time slot",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: slots.length,
              itemBuilder: (context, index) {
                return RadioListTile<String>(
                  value: slots[index],
                  groupValue: selectedSlot,
                  activeColor: Colors.white,
                  title: Text(
                    slots[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedSlot = value;
                    });
                  },
                  tileColor: Colors.grey[850],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (selectedSlot != null) {
                  try {
                    final user = _auth.currentUser;
                    await _firestore.collection("appointments").add({
                      "barberName": widget.barberName,
                      "slot": selectedSlot,
                      "userId": user?.uid ?? "guest",
                      "timestamp": FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Booking confirmed at $selectedSlot"),
                        backgroundColor: Colors.black,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select a slot first"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Confirm Booking"),
            ),
          ),
        ],
      ),
    );
  }
}
