import 'package:flutter/material.dart';
import 'barber_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark grey background
      appBar: AppBar(
        title: const Text("Customer Home",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.black, // Black app bar
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800], // Dark grey button
            foregroundColor: Colors.white, // White text
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text("View Barbers"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const BarberListScreen()),
            );
          },
        ),
      ),
    );
  }
}
