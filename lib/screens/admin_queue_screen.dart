import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import '../repositories/auth_repository.dart';

class AdminQueueScreen extends StatefulWidget {
  const AdminQueueScreen({super.key});

  @override
  State<AdminQueueScreen> createState() => _AdminQueueScreenState();
}

class _AdminQueueScreenState extends State<AdminQueueScreen> {
  final BookingRepository _repository = BookingRepository();
  final AuthRepository _authRepository = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Queue'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _authRepository.logout();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _repository.streamAdminQueue(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading queue: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final bookings = snapshot.data;
          
          if (bookings == null || bookings.isEmpty) {
            return const Center(child: Text('No active bookings in queue.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      '${index + 1}', // Real-time Queue Number based on FCFS order
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    booking.vehicleData['license_plate'] ?? 'Unknown Vehicle',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Service: ${booking.serviceId}'),
                      Text('Status: ${booking.status.name.toUpperCase()}'),
                    ],
                  ),
                  trailing: PopupMenuButton<BookingStatus>(
                    onSelected: (newStatus) {
                      _repository.updateBookingStatus(booking.id, newStatus);
                    },
                    itemBuilder: (context) => BookingStatus.values.map((status) {
                      return PopupMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
