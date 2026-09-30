import 'package:flutter/material.dart';
import '../../../services/health_service.dart';

class BPEntryScreen extends StatefulWidget {
  const BPEntryScreen({super.key});
  @override
  State<BPEntryScreen> createState() => _BPEntryScreenState();
}

class _BPEntryScreenState extends State<BPEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  String _context = 'morning';
  DateTime _measuredAt = DateTime.now();
  bool _isLoading = false;
  final HealthService _service = HealthService();

  static const _contexts = ['morning', 'evening', 'before_meal', 'after_meal', 'random'];

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _heartRateCtrl.dispose();
    super.dispose();
  }

  String _bpCategory(int sys, int dia) {
    if (sys >= 180 || dia >= 120) return 'Hypertensive Crisis 🚨';
    if (sys >= 140 || dia >= 90) return 'High BP (Stage 2)';
    if (sys >= 130 || dia >= 80) return 'High BP (Stage 1)';
    if (sys >= 120 && sys < 130 && dia < 80) return 'Elevated';
    if (sys < 90 || dia < 60) return 'Low BP';
    return 'Normal ✅';
  }

  Color _bpColor(int sys, int dia) {
    if (sys >= 140 || dia >= 90) return const Color(0xFFDC2626);
    if (sys >= 130 || dia >= 80) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _service.addBPReading(
        systolic: int.parse(_systolicCtrl.text),
        diastolic: int.parse(_diastolicCtrl.text),
        heartRate: _heartRateCtrl.text.isNotEmpty ? int.parse(_heartRateCtrl.text) : null,
        measuredAt: _measuredAt,
        measurementContext: _context,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Blood pressure reading saved!'), backgroundColor: Color(0xFF10B981)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sys = int.tryParse(_systolicCtrl.text);
    final dia = int.tryParse(_diastolicCtrl.text);
    final showPreview = sys != null && dia != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Blood Pressure', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BP Preview Card
              if (showPreview)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bpColor(sys, dia).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _bpColor(sys, dia).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.monitor_heart_rounded, color: _bpColor(sys, dia), size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$sys / $dia mmHg', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _bpColor(sys, dia))),
                          Text(_bpCategory(sys, dia), style: TextStyle(fontSize: 13, color: _bpColor(sys, dia), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),

              // Input Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter Reading', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _numField('Systolic', 'Top number', _systolicCtrl, 40, 300, onChanged: (_) => setState(() {}))),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('/', style: TextStyle(fontSize: 28, color: Color(0xFF94A3B8), fontWeight: FontWeight.w300))),
                        Expanded(child: _numField('Diastolic', 'Bottom number', _diastolicCtrl, 20, 200, onChanged: (_) => setState(() {}))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _numField('Heart Rate (optional)', 'bpm', _heartRateCtrl, 20, 300),
                    const SizedBox(height: 16),
                    const Text('Measurement Context', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _contexts.map((c) {
                        final selected = _context == c;
                        return GestureDetector(
                          onTap: () => setState(() => _context = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(c.replaceAll('_', ' '), style: TextStyle(color: selected ? Colors.white : const Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: Color(0xFF64748B), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '${_measuredAt.day}/${_measuredAt.month}/${_measuredAt.year}  ${_measuredAt.hour.toString().padLeft(2, '0')}:${_measuredAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            const Text('Change', style: TextStyle(color: Color(0xFF0072FF), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Reading', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numField(String label, String hint, TextEditingController ctrl, int min, int max, {ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      validator: (v) {
        if (label.contains('optional') && (v == null || v.isEmpty)) return null;
        final n = int.tryParse(v ?? '');
        if (n == null) return 'Enter a number';
        if (n < min || n > max) return '$min–$max';
        return null;
      },
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(context: context, initialDate: _measuredAt, firstDate: DateTime.now().subtract(const Duration(days: 90)), lastDate: DateTime.now());
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_measuredAt));
    if (time == null || !mounted) return;
    setState(() => _measuredAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}
