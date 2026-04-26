import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';

class CreateBookingScreen extends StatefulWidget {
  final String currentUserId;
  /// Optional: callback when booking succeeds (for tab navigation)
  final VoidCallback? onBookingSuccess;

  const CreateBookingScreen({super.key, required this.currentUserId, this.onBookingSuccess});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final BookingRepository _bookingRepository = BookingRepository();

  bool _isLoading = false;
  String? _selectedService;

  final List<Map<String, dynamic>> _availableServices = const [
    {'name': 'Ganti Oli', 'icon': Icons.oil_barrel_rounded},
    {'name': 'Service Rutin', 'icon': Icons.build_rounded},
    {'name': 'Cuci Mobil', 'icon': Icons.water_drop_rounded},
    {'name': 'Turun Mesin', 'icon': Icons.settings_rounded},
    {'name': 'Pengecekan Kaki-kaki', 'icon': Icons.tire_repair_rounded},
  ];

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate() || _selectedService == null) {
      if (_selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a service type'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newBooking = BookingModel(
        id: '',
        userId: widget.currentUserId,
        serviceId: _selectedService!,
        vehicleData: {
          'license_plate': _licensePlateController.text.toUpperCase().trim(),
          'model': _vehicleModelController.text.trim(),
        },
      );

      await _bookingRepository.createBooking(newBooking);

      if (!mounted) return;

      // Reset the form
      _formKey.currentState!.reset();
      _licensePlateController.clear();
      _vehicleModelController.clear();
      setState(() => _selectedService = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Booking created! You are now in queue.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // If embedded as tab, call the success callback (e.g., switch to My Queue)
      widget.onBookingSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text('Book a Service', style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Schedule your next garage visit quickly and easily.',
                  style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),

                const SizedBox(height: 32),

                // ── SECTION: Customer & Vehicle Details ──
                _SectionHeader(icon: Icons.person_outline_rounded, label: 'Customer & Vehicle Details', colors: colors, text: text),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _licensePlateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'License Plate (e.g. B 1234 XYZ)',
                    prefixIcon: Icon(Icons.pin_rounded),
                    hintText: 'B 1234 XYZ',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'License plate is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Brand & Model',
                    prefixIcon: Icon(Icons.directions_car_rounded),
                    hintText: 'e.g. Honda Civic 2022',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Vehicle model is required' : null,
                ),

                const SizedBox(height: 32),

                // ── SECTION: Service Type ──
                _SectionHeader(icon: Icons.build_outlined, label: 'Service Type', colors: colors, text: text),
                const SizedBox(height: 16),

                // Service chips grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableServices.map((s) {
                    final isSelected = _selectedService == s['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedService = s['name'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? colors.primary : colors.outlineVariant,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              s['icon'] as IconData,
                              size: 16,
                              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s['name'] as String,
                              style: text.labelMedium?.copyWith(
                                color: isSelected ? colors.onPrimary : colors.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),

                // ── SUBMIT BUTTON ──
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submitBooking,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Confirm Booking',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: colors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Your booking will be added to the FCFS queue immediately.',
                        style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;
  final TextTheme text;

  const _SectionHeader({required this.icon, required this.label, required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 10),
        Text(label, style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
