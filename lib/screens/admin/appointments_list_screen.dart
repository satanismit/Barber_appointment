import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment_model.dart';
import '../../widgets/loading_indicator.dart';

class AdminAppointmentsListScreen extends StatelessWidget {
  const AdminAppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentService = Provider.of<AppointmentService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepted Appointments'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: appointmentService.getAcceptedAppointments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }

          final appointments = snapshot.data ?? [];
          
          if (appointments.isEmpty) {
            return const Center(child: Text('No accepted appointments found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildAppointmentCard(context, appointment);
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    final dateTime = appointment.dateTime;
    final formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
    final formattedTime = DateFormat('h:mm a').format(dateTime);
    final formattedCreatedAt = DateFormat('MMM d, yyyy hh:mm a').format(appointment.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0, left: 8.0, right: 8.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with customer name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appointment.userName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: _getStatusColor(appointment.status),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    appointment.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(appointment.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12.0),
            
            // Service type
            _buildInfoRow(
              context,
              icon: Icons.work_outline,
              label: 'Service',
              value: appointment.serviceType,
            ),
            
            const SizedBox(height: 8.0),
            
            // Date and time
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: formattedDate,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: _buildInfoRow(
                    context,
                    icon: Icons.access_time,
                    label: 'Time',
                    value: formattedTime,
                  ),
                ),
              ],
            ),
            
            // Notes if available
            if (appointment.notes?.isNotEmpty ?? false) ...{
              const SizedBox(height: 8.0),
              _buildInfoRow(
                context,
                icon: Icons.notes,
                label: 'Notes',
                value: appointment.notes!,
                maxLines: 3,
              ),
            },
            
            // Created at
            const SizedBox(height: 8.0),
            Text(
              'Created: $formattedCreatedAt',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.0, color: Colors.grey[700]),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
