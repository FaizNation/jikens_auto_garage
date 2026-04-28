import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';

class UserQueueScreen extends StatefulWidget {
  final String currentUserId;

  const UserQueueScreen({super.key, required this.currentUserId});

  @override
  State<UserQueueScreen> createState() => _UserQueueScreenState();
}

class _UserQueueScreenState extends State<UserQueueScreen> {
  final BookingRepository _repository = BookingRepository();

  Color _statusColor(BookingStatus status, ColorScheme colors) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFF59E0B);
      case BookingStatus.confirmed:
        return const Color(0xFF10B981);
      case BookingStatus.onProgress:
        return colors.secondaryContainer;
      case BookingStatus.done:
        return const Color(0xFF3B82F6);
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

  IconData _statusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.access_time_filled_rounded;
      case BookingStatus.confirmed:
        return Icons.check_circle_rounded;
      case BookingStatus.onProgress:
        return Icons.build_circle_rounded;
      case BookingStatus.done:
        return Icons.done_all_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('Antrean Saya', style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _repository.streamUserBookings(widget.currentUserId),
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
          final activeBooking = bookings.isNotEmpty ? bookings.first : null;
          final hasActive = activeBooking != null &&
              activeBooking.status != BookingStatus.done &&
              activeBooking.status != BookingStatus.cancelled;

          if (!hasActive) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_toggle_off_rounded, size: 56, color: colors.outline),
                    ),
                    const SizedBox(height: 24),
                    Text('Tidak Ada Pesanan Aktif', style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Anda tidak memiliki antrean aktif. Pergi ke tab Pesan untuk menjadwalkan layanan.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show active booking status
          final statusColor = _statusColor(activeBooking.status, colors);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pesanan Saat Ini', style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant, letterSpacing: 0.5)),
                const SizedBox(height: 12),

                // ── Status Hero Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_statusIcon(activeBooking.status), size: 52, color: statusColor),
                      ),
                      const SizedBox(height: 20),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                              _statusLabel(activeBooking.status),
                              style: text.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Vehicle & service info
                      _DetailRow(
                        icon: Icons.pin_rounded,
                        label: 'Plat Nomor',
                        value: activeBooking.vehicleData['license_plate'] ?? '-',
                        colors: colors,
                        text: text,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.directions_car_rounded,
                        label: 'Kendaraan',
                        value: activeBooking.vehicleData['model'] ?? '-',
                        colors: colors,
                        text: text,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.build_rounded,
                        label: 'Layanan',
                        value: activeBooking.serviceId,
                        colors: colors,
                        text: text,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Status Progress Steps ──
                Text('Kemajuan', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _StatusStepper(currentStatus: activeBooking.status, colors: colors, text: text),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;
  final TextTheme text;

  const _DetailRow({required this.icon, required this.label, required this.value, required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: 10),
        Text('$label: ', style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        Expanded(
          child: Text(value, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final BookingStatus currentStatus;
  final ColorScheme colors;
  final TextTheme text;

  const _StatusStepper({required this.currentStatus, required this.colors, required this.text});

  static const _steps = [
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.onProgress,
    BookingStatus.done,
  ];

  static const _labels = ['Menunggu', 'Terkonfirmasi', 'Dalam Proses', 'Selesai'];
  static const _icons = [
    Icons.access_time_rounded,
    Icons.check_circle_outline_rounded,
    Icons.build_rounded,
    Icons.done_all_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _steps.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: List.generate(_steps.length, (i) {
          final isDone = i < currentIdx;
          final isCurrent = i == currentIdx;
          final stepColor = isCurrent
              ? colors.secondaryContainer
              : isDone
                  ? const Color(0xFF10B981)
                  : colors.outline;

          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: (isDone || isCurrent) ? stepColor.withValues(alpha: 0.15) : colors.surfaceContainerLow,
                      shape: BoxShape.circle,
                      border: Border.all(color: stepColor, width: isCurrent ? 2 : 1),
                    ),
                    child: Icon(_icons[i], size: 14, color: stepColor),
                  ),
                  if (i < _steps.length - 1)
                    Container(
                      width: 2,
                      height: 28,
                      color: isDone ? const Color(0xFF10B981) : colors.outlineVariant,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _labels[i],
                  style: text.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? colors.onSurface : isDone ? colors.onSurfaceVariant : colors.outline,
                  ),
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Saat Ini', style: text.labelSmall?.copyWith(color: colors.secondaryContainer, fontWeight: FontWeight.bold)),
                ),
              ],
              if (isDone) ...[
                const Spacer(),
                Icon(Icons.check_rounded, size: 16, color: const Color(0xFF10B981)),
              ],
            ],
          );
        }),
      ),
    );
  }
}
