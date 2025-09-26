import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../widgets/loading_indicator.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appointmentService = AppointmentService();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedService;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _services = [
    'Haircut',
    'Beard Trim',
    'Haircut & Beard',
    'Hair Color',
    'Hair Styling',
    'Shave',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time when date changes
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date first')),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null || _selectedService == null) {
      setState(() {
        _errorMessage = 'Please fill in all required fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Combine date and time
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Check if the selected time is in the past
      if (appointmentDateTime.isBefore(DateTime.now())) {
        throw Exception('Cannot book appointments in the past');
      }

      // Check if the selected time is within business hours
      if (!_isWithinBusinessHours(appointmentDateTime)) {
        throw Exception('Selected time is outside of business hours');
      }

      // Check if the time slot is available
      final isAvailable = await _appointmentService.isTimeSlotAvailable(appointmentDateTime);
      if (!isAvailable) {
        throw Exception('Selected time slot is not available. Please choose another time.');
      }

      // Get current user
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) throw Exception('User data not found');
      final userData = userDoc.data();

      // Create appointment
      await _appointmentService.createAppointment(
        userId: user.uid,
        userName: userData?['name'] ?? 'User',
        userEmail: user.email!,
        dateTime: appointmentDateTime,
        serviceType: _selectedService!,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to home screen
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  bool _isWithinBusinessHours(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final day = dateTime.weekday; // 1 = Monday, 7 = Sunday

    // Check if it's Sunday
    if (day == DateTime.sunday) {
      // Sunday hours: 10:00 AM - 4:00 PM
      if (hour < 10 || (hour == 16 && minute > 0) || hour >= 17) {
        return false;
      }
      return true;
    }
    
    // Check if it's Saturday
    if (day == DateTime.saturday) {
      // Saturday hours: 9:00 AM - 6:00 PM
      if (hour < 9 || (hour == 18 && minute > 0) || hour >= 19) {
        return false;
      }
      return true;
    }
    
    // Weekday hours: 9:00 AM - 8:00 PM
    if (hour < 9 || (hour == 20 && minute > 0) || hour >= 21) {
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: LoadingIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Service Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Service Type Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Service',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cut),
                ),
                value: _selectedService,
                items: _services.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedService = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a service';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Date Picker
              const Text(
                'Select Date & Time',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('MMM d, yyyy').format(_selectedDate!),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectedDate == null ? null : () => _selectTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime == null
                            ? 'Select Time'
                            : _selectedTime!.format(context),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_selectedDate != null && _selectedTime != null) ...{
                const SizedBox(height: 16),
                Text(
                  'Selected: ${DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!)} at ${_selectedTime!.format(context)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              },
              
              const SizedBox(height: 24),
              
              // Additional Notes
              const Text(
                'Additional Notes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any special requests or notes...',
                  border: OutlineInputBorder(),
                ),
              ),
              
              if (_errorMessage != null) ...{
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              },
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Book Appointment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
