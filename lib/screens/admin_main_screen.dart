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
          _HistoryTab(),
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
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: colors.onSurfaceVariant),
            selectedIcon: Icon(Icons.history_rounded, color: colors.primary),
            label: 'Riwayat',
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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  BookingStatus? _selectedStatus; // null = tampilkan semua

  // Cache uid -> nama pelanggan
  // ignore: prefer_final_fields
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch names for any UIDs not yet cached
  Future<void> _loadUserNames(List<BookingModel> bookings) async {
    final missing = bookings
        .map((b) => b.userId)
        .where((uid) => !_userNames.containsKey(uid))
        .toList();
    if (missing.isEmpty) return;
    final fetched = await _authRepository.getUserNames(missing);
    if (mounted) setState(() => _userNames.addAll(fetched));
  }

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

  List<BookingModel> _applyFilters(List<BookingModel> all) {
    return all.where((b) {
      // Status filter
      if (_selectedStatus != null && b.status != _selectedStatus) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final plate = (b.vehicleData['license_plate'] ?? '').toLowerCase();
        final name = (_userNames[b.userId] ?? '').toLowerCase();
        if (!plate.contains(_searchQuery) && !name.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
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
            Text('Jikens Auto Garage',
                style: text.labelSmall?.copyWith(color: colors.onPrimary.withValues(alpha: 0.7))),
            Text('Monitor Antrean',
                style: text.titleMedium?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold)),
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
                  Text('Gagal memuat antrean',
                      style: text.bodyLarge?.copyWith(color: colors.error)),
                ],
              ),
            );
          }

          final all = snapshot.data ?? [];

          // Fetch missing names in background (non-blocking)
          _loadUserNames(all);

          final bookings = _applyFilters(all);

          return Column(
            children: [
              // ── SEARCH + FILTER PANEL ────────────────────────────────────
              Container(
                color: colors.surfaceContainerLowest,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari nama pelanggan atau plat kendaraan...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status filter chips (scrollable)
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterChip(
                            label: 'Semua',
                            isSelected: _selectedStatus == null,
                            color: colors.primary,
                            onTap: () => setState(() => _selectedStatus = null),
                            colors: colors,
                            text: text,
                          ),
                          const SizedBox(width: 6),
                          ...BookingStatus.values.map((s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _FilterChip(
                              label: _statusLabel(s),
                              isSelected: _selectedStatus == s,
                              color: _statusColor(s, colors),
                              onTap: () => setState(() =>
                                  _selectedStatus = _selectedStatus == s ? null : s),
                              colors: colors,
                              text: text,
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Result count
                    Row(
                      children: [
                        Text(
                          '${bookings.length} dari ${all.length} antrean',
                          style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),

              // ── LIST ──────────────────────────────────────────────────────
              Expanded(
                child: bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 56, color: colors.outline),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _selectedStatus != null
                                  ? 'Tidak ada hasil yang cocok'
                                  : 'Antrean Kosong',
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty || _selectedStatus != null
                                  ? 'Coba ubah kata kunci atau filter status'
                                  : 'Tidak ada pesanan aktif saat ini.',
                              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final statusColor = _statusColor(booking.status, colors);
                          final customerName = _userNames[booking.userId] ?? '...';
                          // Find global FCFS position from the unfiltered list
                          final globalPos = all.indexOf(booking) + 1;

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
                                  // ── Header row: queue# + name + status pill ──
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
                                          '#$globalPos',
                                          style: text.labelLarge?.copyWith(
                                              color: colors.onPrimary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              customerName,
                                              style: text.titleSmall
                                                  ?.copyWith(fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              booking.vehicleData['license_plate'] ?? '-',
                                              style: text.bodySmall
                                                  ?.copyWith(color: colors.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                              color: statusColor.withValues(alpha: 0.4)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                  color: statusColor, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              _statusLabel(booking.status),
                                              style: text.labelSmall?.copyWith(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  Divider(color: colors.outlineVariant, height: 1),
                                  const SizedBox(height: 12),

                                  // ── Vehicle type + model + service ──
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _InfoChip(
                                          icon: booking.vehicleType == VehicleType.motorcycle
                                              ? Icons.two_wheeler_rounded
                                              : Icons.directions_car_rounded,
                                          label:
                                              '${booking.vehicleType == VehicleType.motorcycle ? 'Motor' : 'Mobil'} · ${booking.vehicleData['model'] ?? '-'}',
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

                                  // Notes (only if not empty)
                                  if (booking.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.notes_rounded,
                                              size: 14, color: colors.onSurfaceVariant),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              booking.notes,
                                              style: text.labelMedium
                                                  ?.copyWith(color: colors.onSurfaceVariant),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  // ── Update status ──
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Perbarui Status:',
                                          style: text.labelMedium
                                              ?.copyWith(color: colors.onSurfaceVariant)),
                                      PopupMenuButton<BookingStatus>(
                                        onSelected: (newStatus) =>
                                            _repository.updateBookingStatus(booking.id, newStatus),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: colors.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('Ubah',
                                                  style: text.labelMedium?.copyWith(
                                                      color: colors.onPrimary,
                                                      fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 4),
                                              Icon(Icons.arrow_drop_down_rounded,
                                                  color: colors.onPrimary, size: 18),
                                            ],
                                          ),
                                        ),
                                        itemBuilder: (context) =>
                                            BookingStatus.values.map((status) => PopupMenuItem(
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
                                                  Text(_statusLabel(status),
                                                      style: text.bodyMedium?.copyWith(
                                                          fontWeight: FontWeight.w500)),
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── FILTER CHIP ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final ColorScheme colors;
  final TextTheme text;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : colors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: text.labelSmall?.copyWith(
                color: isSelected ? color : colors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── INFO CHIP ─────────────────────────────────────────────────────────────────

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
            child: Text(label,
                style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                overflow: TextOverflow.ellipsis),
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

// ── HISTORY TAB ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final BookingRepository _repository = BookingRepository();
  final AuthRepository _authRepository = AuthRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ignore: prefer_final_fields
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserNames(List<BookingModel> bookings) async {
    final missing = bookings
        .map((b) => b.userId)
        .where((uid) => !_userNames.containsKey(uid))
        .toList();
    if (missing.isEmpty) return;
    final fetched = await _authRepository.getUserNames(missing);
    if (mounted) setState(() => _userNames.addAll(fetched));
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
            Text('Jikens Auto Garage',
                style: text.labelSmall
                    ?.copyWith(color: colors.onPrimary.withValues(alpha: 0.7))),
            Text('Riwayat Servis',
                style: text.titleMedium
                    ?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold)),
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
        stream: _repository.streamCompletedBookings(),
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
                  Text('Gagal memuat riwayat',
                      style: text.bodyLarge?.copyWith(color: colors.error)),
                ],
              ),
            );
          }

          final all = snapshot.data ?? [];
          _loadUserNames(all);

          // Apply search filter
          final filtered = _searchQuery.isEmpty
              ? all
              : all.where((b) {
                  final plate =
                      (b.vehicleData['license_plate'] ?? '').toLowerCase();
                  final name = (_userNames[b.userId] ?? '').toLowerCase();
                  return plate.contains(_searchQuery) ||
                      name.contains(_searchQuery);
                }).toList();

          return Column(
            children: [
              // ── SEARCH BAR ──
              Container(
                color: colors.surfaceContainerLowest,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari nama pelanggan atau plat kendaraan...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: const Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          '${filtered.length} servis selesai',
                          style: text.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),

              // ── LIST ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded,
                                size: 64, color: colors.outline),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada hasil yang cocok'
                                  : 'Belum Ada Riwayat',
                              style: text.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Coba ubah kata kunci pencarian'
                                  : 'Riwayat servis yang selesai akan muncul di sini.',
                              style: text.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final booking = filtered[index];
                          final customerName =
                              _userNames[booking.userId] ?? '...';
                          final completedAt = booking.createdAt;

                          return Container(
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Done badge
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF10B981),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Customer name + plate
                                        Text(
                                          customerName,
                                          style: text.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.pin_rounded,
                                                size: 12,
                                                color: colors.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Text(
                                              booking.vehicleData[
                                                      'license_plate'] ??
                                                  '-',
                                              style: text.bodySmall?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              booking.vehicleType ==
                                                      VehicleType.motorcycle
                                                  ? Icons.two_wheeler_rounded
                                                  : Icons.directions_car_rounded,
                                              size: 12,
                                              color: colors.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                booking.vehicleData['model'] ??
                                                    '-',
                                                style: text.bodySmall?.copyWith(
                                                    color: colors
                                                        .onSurfaceVariant),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Service chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colors.primary
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.build_rounded,
                                                  size: 12,
                                                  color: colors.primary),
                                              const SizedBox(width: 5),
                                              Text(
                                                booking.serviceId,
                                                style: text.labelSmall
                                                    ?.copyWith(
                                                        color: colors.primary,
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Notes (if any)
                                        if (booking.notes.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.notes_rounded,
                                                  size: 12,
                                                  color:
                                                      colors.onSurfaceVariant),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  booking.notes,
                                                  style: text.bodySmall
                                                      ?.copyWith(
                                                          color: colors
                                                              .onSurfaceVariant),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Date
                                  if (completedAt != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatDate(completedAt),
                                          style: text.labelSmall?.copyWith(
                                              color: colors.onSurfaceVariant),
                                        ),
                                        Text(
                                          _formatTime(completedAt),
                                          style: text.labelSmall?.copyWith(
                                              color: colors.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
