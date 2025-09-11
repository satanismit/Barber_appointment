import 'package:flutter/material.dart';
import 'booking_screen.dart';

class BarberListScreen extends StatelessWidget {
  const BarberListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final barbers = [
      {"name": "Bhavya Barber", "shop": "Mullet Cuts"},
      {"name": "Ambika Barber", "shop": "Buzz Styles"},
      {"name": "Om Barber", "shop": "Two Side Salon"},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark grey background
      appBar: AppBar(
        title: const Text(
          "Available Barbers",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black, // Black app bar
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: barbers.length,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.grey[850], // Dark card background
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              title: Text(
                barbers[index]["name"]!,
                style: const TextStyle(color: Colors.white), // White text
              ),
              subtitle: Text(
                barbers[index]["shop"]!,
                style: TextStyle(color: Colors.grey[400]), // Lighter grey
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800], // Dark grey button
                  foregroundColor: Colors.white, // White text
                ),
                child: const Text("Book"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BookingScreen(barberName: barbers[index]["name"]!),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
