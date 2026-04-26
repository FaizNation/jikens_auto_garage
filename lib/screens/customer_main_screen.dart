import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import 'create_booking_screen.dart';
import 'user_queue_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  final String currentUserId;
  final String displayName;

  const CustomerMainScreen({
    super.key,
    required this.currentUserId,
    required this.displayName,
  });

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _HomeTab(currentUserId: widget.currentUserId, displayName: widget.displayName, onGoToBooking: () => setState(() => _currentIndex = 1), onGoToQueue: () => setState(() => _currentIndex = 2)),
      CreateBookingScreen(currentUserId: widget.currentUserId),
      UserQueueScreen(currentUserId: widget.currentUserId),
      _ProfileTab(displayName: widget.displayName),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: colors.onSurfaceVariant),
            selectedIcon: Icon(Icons.home_rounded, color: colors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined, color: colors.onSurfaceVariant),
            selectedIcon: Icon(Icons.add_box_rounded, color: colors.primary),
            label: 'Book',
          ),
          NavigationDestination(
            icon: Icon(Icons.slow_motion_video_outlined, color: colors.onSurfaceVariant),
            selectedIcon: Icon(Icons.slow_motion_video_rounded, color: colors.primary),
            label: 'My Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: colors.onSurfaceVariant),
            selectedIcon: Icon(Icons.person_rounded, color: colors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── HOME TAB ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final String currentUserId;
  final String displayName;
  final VoidCallback onGoToBooking;
  final VoidCallback onGoToQueue;

  const _HomeTab({
    required this.currentUserId,
    required this.displayName,
    required this.onGoToBooking,
    required this.onGoToQueue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final firstName = displayName.split(' ').first;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.primary,
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                      style: text.titleLarge?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good day,', style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                      Text(firstName, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.secondaryContainer),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_gas_station_rounded, size: 14, color: colors.secondary),
                        const SizedBox(width: 4),
                        Text('FCFS', style: text.labelSmall?.copyWith(color: colors.secondary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── HERO BANNER ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready for your next service?',
                            style: text.titleMedium?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Book now and get in queue instantly.',
                            style: text.bodySmall?.copyWith(color: colors.onPrimary.withValues(alpha: 0.75)),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: onGoToBooking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.secondaryContainer,
                                foregroundColor: colors.onSecondaryContainer,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text('Book Now', style: text.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.onSecondaryContainer)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.directions_car_rounded, size: 72, color: colors.onPrimary.withValues(alpha: 0.2)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── QUICK ACTIONS ──
              Text('Quick Actions', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _QuickActionCard(
                    icon: Icons.add_box_rounded,
                    label: 'Book Service',
                    color: colors.primary,
                    onTap: onGoToBooking,
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCard(
                    icon: Icons.slow_motion_video_rounded,
                    label: 'My Queue',
                    color: colors.secondaryContainer,
                    onTap: onGoToQueue,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── SERVICES AVAILABLE ──
              Text('Available Services', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _ServiceList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 12),
              Text(label, style: text.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  final List<Map<String, dynamic>> _services = const [
    {'name': 'Ganti Oli', 'icon': Icons.oil_barrel_rounded, 'desc': 'Penggantian oli mesin & filter'},
    {'name': 'Service Rutin', 'icon': Icons.build_rounded, 'desc': 'Perawatan kendaraan berkala'},
    {'name': 'Cuci Mobil', 'icon': Icons.water_drop_rounded, 'desc': 'Cuci eksterior & interior'},
    {'name': 'Turun Mesin', 'icon': Icons.settings_rounded, 'desc': 'Overhaul mesin lengkap'},
    {'name': 'Kaki-kaki', 'icon': Icons.tire_repair_rounded, 'desc': 'Pengecekan ban & suspensi'},
  ];

  const _ServiceList();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: _services.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(s['icon'] as IconData, size: 20, color: colors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['name'] as String, style: text.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(s['desc'] as String, style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.outline),
          ],
        ),
      )).toList(),
    );
  }
}

// ── PROFILE TAB ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final String displayName;

  const _ProfileTab({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 48,
                backgroundColor: colors.primary,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: text.displaySmall?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Text(displayName, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),

              const SizedBox(height: 40),

              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  children: [
                    _ProfileInfoRow(icon: Icons.person_outline_rounded, label: 'Full Name', value: displayName, colors: colors, text: text),
                    Divider(height: 24, color: colors.outlineVariant),
                    _ProfileInfoRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '-', colors: colors, text: text),
                    Divider(height: 24, color: colors.outlineVariant),
                    _ProfileInfoRow(icon: Icons.badge_outlined, label: 'Role', value: 'Customer', colors: colors, text: text),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthRepository().logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;
  final TextTheme text;

  const _ProfileInfoRow({required this.icon, required this.label, required this.value, required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
