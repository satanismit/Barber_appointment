import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/appointment_service.dart';
import '../../../models/appointment_model.dart';
import '../../widgets/loading_indicator.dart';
import 'appointments_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _appointmentService = AppointmentService();
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authService.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.schedule), text: 'All Appointments'),
              Tab(icon: Icon(Icons.check_circle), text: 'Accepted'),
              Tab(icon: Icon(Icons.people), text: 'Customers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // All Appointments Tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Appointments')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Appointment>>(
                    stream: _appointmentService.getAllAppointments(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingIndicator();
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final appointments = snapshot.data ?? [];
                      
                      // Filter appointments based on selected filter
                      final filteredAppointments = _selectedFilter == 'all'
                          ? appointments
                          : appointments.where((a) => a.status == _selectedFilter).toList();

                      if (filteredAppointments.isEmpty) {
                        return const Center(
                          child: Text('No appointments found'),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = filteredAppointments[index];
                          return _buildAppointmentCard(appointment);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            // Accepted Appointments Tab
            const AdminAppointmentsListScreen(),
            
            // Customers Tab (Placeholder for now)
            const Center(child: Text('Customer management coming soon')),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final dateFormat = DateFormat('MMM d, y hh:mm a');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(appointment.userName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${appointment.serviceType}'),
            Text('Date: ${dateFormat.format(appointment.dateTime)}'),
            Text('Status: ${appointment.status.toUpperCase()}'),
            if (appointment.notes?.isNotEmpty ?? false)
              Text('Notes: ${appointment.notes}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (appointment.status == 'pending') ...[
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _updateAppointmentStatus(appointment, 'accepted'),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _updateAppointmentStatus(appointment, 'rejected'),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: () => _deleteAppointment(appointment.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAppointmentStatus(Appointment appointment, String status) async {
    try {
      await _appointmentService.updateAppointmentStatus(appointment.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment ${status} successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _appointmentService.deleteAppointment(appointmentId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment deleted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete appointment: $e')),
        );
      }
    }
  }
}
