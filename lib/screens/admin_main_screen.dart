import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import '../repositories/auth_repository.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _AdminQueueTab(),
          _ServiceManagementTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined, color: colors.onSurfaceVariant),
            selectedIcon: Icon(Icons.list_alt_rounded, color: colors.primary),
            label: 'Antrean',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined, color: colors.onSurfaceVariant),
            selectedIcon: Icon(Icons.build_rounded, color: colors.primary),
            label: 'Layanan',
          ),
        ],
      ),
    );
  }
}

// ── ADMIN QUEUE TAB ───────────────────────────────────────────────────────────

class _AdminQueueTab extends StatefulWidget {
  const _AdminQueueTab();

  @override
  State<_AdminQueueTab> createState() => _AdminQueueTabState();
}

class _AdminQueueTabState extends State<_AdminQueueTab> {
  final BookingRepository _repository = BookingRepository();
  final AuthRepository _authRepository = AuthRepository();

  Color _statusColor(BookingStatus status, ColorScheme colors) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case BookingStatus.confirmed:
        return const Color(0xFF10B981); // Emerald
      case BookingStatus.onProgress:
        return colors.secondaryContainer; // Vibrant Orange
      case BookingStatus.done:
        return const Color(0xFF3B82F6); // Blue
      case BookingStatus.cancelled:
        return colors.error;
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'MENUNGGU';
      case BookingStatus.confirmed:
        return 'TERKONFIRMASI';
      case BookingStatus.onProgress:
        return 'DALAM PROSES';
      case BookingStatus.done:
        return 'SELESAI';
      case BookingStatus.cancelled:
        return 'DIBATALKAN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jikens Auto Garage', style: text.labelSmall?.copyWith(color: colors.onPrimary.withValues(alpha: 0.7))),
            Text('Monitor Antrean', style: text.titleMedium?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: colors.onPrimary),
            tooltip: 'Keluar',
            onPressed: () async => await _authRepository.logout(),
          ),
        ],
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _repository.streamAdminQueue(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
                  const SizedBox(height: 12),
                  Text('Gagal memuat antrean', style: text.bodyLarge?.copyWith(color: colors.error)),
                ],
              ),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 64, color: colors.outline),
                  const SizedBox(height: 16),
                  Text('Antrean Kosong', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Tidak ada pesanan aktif saat ini.', style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final statusColor = _statusColor(booking.status, colors);

              return Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Queue number + status
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${index + 1}',
                              style: text.labelLarge?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              booking.vehicleData['license_plate'] ?? 'Unknown',
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Status pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _statusLabel(booking.status),
                                  style: text.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: colors.outlineVariant, height: 1),
                      const SizedBox(height: 12),
                      // Vehicle model + service
                      Row(
                        children: [
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.directions_car_outlined,
                              label: booking.vehicleData['model'] ?? '-',
                              colors: colors,
                              text: text,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.build_outlined,
                              label: booking.serviceId,
                              colors: colors,
                              text: text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Update status row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Perbarui Status:', style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
                          PopupMenuButton<BookingStatus>(
                            onSelected: (newStatus) => _repository.updateBookingStatus(booking.id, newStatus),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Ubah', style: text.labelMedium?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down_rounded, color: colors.onPrimary, size: 18),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => BookingStatus.values.map((status) => PopupMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _statusColor(status, colors),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(_statusLabel(status), style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ],
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;
  final TextTheme text;

  const _InfoChip({required this.icon, required this.label, required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── SERVICE MANAGEMENT TAB ───────────────────────────────────────────────────

class _ServiceManagementTab extends StatelessWidget {
  const _ServiceManagementTab();

  static const List<Map<String, dynamic>> _services = [
    {'name': 'Ganti Oli', 'icon': Icons.oil_barrel_rounded, 'desc': 'Penggantian oli mesin & filter oli'},
    {'name': 'Service Rutin', 'icon': Icons.build_rounded, 'desc': 'Perawatan kendaraan berkala'},
    {'name': 'Cuci Mobil', 'icon': Icons.water_drop_rounded, 'desc': 'Cuci eksterior & interior'},
    {'name': 'Turun Mesin', 'icon': Icons.settings_rounded, 'desc': 'Overhaul mesin lengkap'},
    {'name': 'Pengecekan Kaki-kaki', 'icon': Icons.tire_repair_rounded, 'desc': 'Pengecekan ban & suspensi'},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final auth = AuthRepository();

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jikens Auto Garage', style: text.labelSmall?.copyWith(color: colors.onPrimary.withValues(alpha: 0.7))),
            Text('Manajemen Layanan', style: text.titleMedium?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: colors.onPrimary),
            tooltip: 'Keluar',
            onPressed: () async => await auth.logout(),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final s = _services[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(s['icon'] as IconData, size: 22, color: colors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'] as String, style: text.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(s['desc'] as String, style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                // Edit/manage button (placeholder for future)
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: colors.onSurfaceVariant),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Manajemen layanan segera hadir!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: colors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Fitur tambah layanan segera hadir!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: colors.primary,
            ),
          );
        },
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
