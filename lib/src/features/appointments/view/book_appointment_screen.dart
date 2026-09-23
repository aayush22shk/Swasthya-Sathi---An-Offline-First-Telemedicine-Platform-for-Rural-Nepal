import 'package:flutter/material.dart';
import '../../../common_widgets/doctors/doctor_model.dart';
import '../../../services/appointment_service.dart';
import '../../../services/doctor_service.dart';
import '../../consultation/view/esewa_payment_page.dart';

class BookAppointmentScreen extends StatefulWidget {
  final DoctorModel doctor;

  const BookAppointmentScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  String _selectedMode = 'video';
  final TextEditingController _reasonController = TextEditingController();

  List<String> _slots = [];
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String get _formattedDateParam {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });

    final slots = await DoctorService().getDoctorSlots(
      widget.doctor.id,
      _formattedDateParam,
    );

    if (mounted) {
      setState(() {
        _slots = slots;
        if (_slots.isNotEmpty) {
          _selectedSlot = _slots.first;
        }
        _isLoadingSlots = false;
      });
    }
  }

  DateTime? _constructScheduledDateTime() {
    if (_selectedSlot == null) return null;
    try {
      // Parse slot e.g. "09:30 AM" or "14:00"
      final parts = _selectedSlot!.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (parts.length > 1) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }

      return DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );
    } catch (_) {
      return DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        10,
        0,
      );
    }
  }

  Future<void> _handleProceed() async {
    final scheduledAt = _constructScheduledDateTime();
    if (scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appt = await AppointmentService().bookAppointment(
        doctorId: widget.doctor.id,
        scheduledAt: scheduledAt,
        mode: _selectedMode,
        fee: widget.doctor.feeAmount,
        reasonForVisit: _reasonController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Navigate to eSewa payment page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EsewaPaymentPage(
            doctorId: widget.doctor.id,
            doctorName: widget.doctor.name,
            specialty: widget.doctor.specialty,
            avatarUrl: widget.doctor.avatarUrl,
            consultationFee: widget.doctor.consultationFee,
            feeAmount: widget.doctor.feeAmount,
            appointmentId: appt.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // In case of offline/mock fallback: proceed directly to payment
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EsewaPaymentPage(
            doctorId: widget.doctor.id,
            doctorName: widget.doctor.name,
            specialty: widget.doctor.specialty,
            avatarUrl: widget.doctor.avatarUrl,
            consultationFee: widget.doctor.consultationFee,
            feeAmount: widget.doctor.feeAmount,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Summary Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(doc.avatarUrl),
                    onBackgroundImageError: (e, s) {},
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doc.specialty,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc.consultationFee,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0072FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Select Date
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            _buildDateSelector(),

            const SizedBox(height: 24),

            // Select Time Slot
            const Text(
              'Available Time Slots',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            _buildSlotGrid(),

            const SizedBox(height: 24),

            // Consultation Mode
            const Text(
              'Consultation Mode',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            _buildModeSelector(),

            const SizedBox(height: 24),

            // Reason for visit
            const Text(
              'Reason for Visit (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Briefly describe your symptoms or reason for consultation...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Proceed Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0072FF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Proceed to Pay ${doc.consultationFee}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              _fetchSlots();
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0072FF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0072FF) : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayName(date.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotGrid() {
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No slots available on this date. Please pick another day.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _slots.map((slot) {
        final isSelected = _selectedSlot == slot;
        return InkWell(
          onTap: () => setState(() => _selectedSlot = slot),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0072FF) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF0072FF) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeSelector() {
    final modes = [
      {'id': 'video', 'label': 'Video Call', 'icon': Icons.videocam_rounded},
      {'id': 'audio', 'label': 'Audio Call', 'icon': Icons.phone_rounded},
      {'id': 'chat', 'label': 'Chat Consult', 'icon': Icons.chat_bubble_rounded},
    ];

    return Row(
      children: modes.map((m) {
        final isSelected = _selectedMode == m['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMode = m['id'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0072FF) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    m['icon'] as IconData,
                    color: isSelected ? const Color(0xFF0072FF) : const Color(0xFF64748B),
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF0072FF) : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static String _weekdayName(int day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[day - 1];
  }
}
