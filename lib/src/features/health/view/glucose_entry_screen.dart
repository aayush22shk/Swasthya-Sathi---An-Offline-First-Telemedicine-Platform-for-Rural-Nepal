import 'package:flutter/material.dart';
import '../../../services/health_service.dart';

class GlucoseEntryScreen extends StatefulWidget {
  const GlucoseEntryScreen({super.key});
  @override
  State<GlucoseEntryScreen> createState() => _GlucoseEntryScreenState();
}

class _GlucoseEntryScreenState extends State<GlucoseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _glucoseCtrl = TextEditingController();
  String _type = 'fasting';
  String _unit = 'mg/dl';
  DateTime _measuredAt = DateTime.now();
  bool _isLoading = false;
  final HealthService _service = HealthService();

  static const _types = ['fasting', 'before_meal', 'after_meal', 'random', 'bedtime'];
  static const _typeLabels = {'fasting': 'Fasting', 'before_meal': 'Before Meal', 'after_meal': 'After Meal', 'random': 'Random', 'bedtime': 'Bedtime'};

  String _category(double v) {
    if (_unit == 'mg/dl') {
      if (_type == 'fasting') {
        if (v < 70) return 'Low (Hypoglycemia) ⚠️';
        if (v <= 99) return 'Normal ✅';
        if (v <= 125) return 'Pre-Diabetes';
        return 'Diabetic Range 🔴';
      }
      if (v > 200) return 'High ⚠️';
      if (v < 70) return 'Low ⚠️';
      return 'Within Range ✅';
    }
    return '';
  }

  Color _categoryColor(double v) {
    if (_type == 'fasting') {
      if (v < 70 || v > 125) return const Color(0xFFDC2626);
      if (v > 100) return const Color(0xFFF59E0B);
      return const Color(0xFF10B981);
    }
    return v > 200 || v < 70 ? const Color(0xFFDC2626) : const Color(0xFF10B981);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _service.addGlucoseReading(
        glucoseValue: double.parse(_glucoseCtrl.text),
        unit: _unit,
        measurementType: _type,
        measuredAt: _measuredAt,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Glucose reading saved!'), backgroundColor: Color(0xFF10B981)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFDC2626)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _glucoseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final val = double.tryParse(_glucoseCtrl.text);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(title: const Text('Blood Glucose', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF0F172A), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (val != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _categoryColor(val).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: _categoryColor(val).withValues(alpha: 0.3))),
                  child: Row(
                    children: [
                      Icon(Icons.water_drop_rounded, color: _categoryColor(val), size: 32),
                      const SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${val.toStringAsFixed(0)} $_unit', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _categoryColor(val))),
                        Text(_category(val), style: TextStyle(fontSize: 13, color: _categoryColor(val), fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Enter Reading', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _glucoseCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Glucose Value',
                      suffixText: _unit,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
                      filled: true, fillColor: const Color(0xFFF8FAFC),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null) return 'Enter a valid number';
                      if (n <= 0 || n > 600) return 'Enter a value between 1–600';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Text('Unit:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                    const SizedBox(width: 12),
                    ...['mg/dl', 'mmol/l'].map((u) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _unit = u),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _unit == u ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(u, style: TextStyle(color: _unit == u ? Colors.white : const Color(0xFF374151), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    )),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Measurement Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) {
                    final selected = _type == t;
                    return GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_typeLabels[t]!, style: TextStyle(color: selected ? Colors.white : const Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded, color: Color(0xFF64748B), size: 18),
                        const SizedBox(width: 10),
                        Text('${_measuredAt.day}/${_measuredAt.month}/${_measuredAt.year}  ${_measuredAt.hour.toString().padLeft(2,'0')}:${_measuredAt.minute.toString().padLeft(2,'0')}', style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w500)),
                        const Spacer(),
                        const Text('Change', style: TextStyle(color: Color(0xFF0072FF), fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
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

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(context: context, initialDate: _measuredAt, firstDate: DateTime.now().subtract(const Duration(days: 90)), lastDate: DateTime.now());
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_measuredAt));
    if (time == null || !mounted) return;
    setState(() => _measuredAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}
