import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../services/health_service.dart';
import 'bp_entry_screen.dart';
import 'glucose_entry_screen.dart';
import 'weight_entry_screen.dart';
import 'health_analysis_screen.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen>
    with SingleTickerProviderStateMixin {
  final HealthService _service = HealthService();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  List<BPReading> _bpReadings = [];
  List<GlucoseReading> _glucoseReadings = [];
  List<WeightReading> _weightReadings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getBPHistory(limit: 14),
        _service.getGlucoseHistory(limit: 14),
        _service.getWeightHistory(limit: 14),
      ]);
      if (mounted) {
        setState(() {
          _bpReadings = results[0] as List<BPReading>;
          _glucoseReadings = results[1] as List<GlucoseReading>;
          _weightReadings = results[2] as List<WeightReading>;
          _isLoading = false;
        });
        _animCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0072FF)))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: const Color(0xFF0072FF),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildQuickEntryRow(),
                            const SizedBox(height: 20),
                            _buildBPCard(),
                            const SizedBox(height: 16),
                            _buildGlucoseCard(),
                            const SizedBox(height: 16),
                            _buildWeightCard(),
                            const SizedBox(height: 20),
                            _buildAnalysisButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0072FF), Color(0xFF00C6FF)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Health Monitor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('Track your vitals & trends', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEntryRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Record Vitals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _quickEntryBtn('Blood\nPressure', Icons.monitor_heart_rounded, const Color(0xFFDC2626), const Color(0xFFFEF2F2), () => _navigateAndRefresh(const BPEntryScreen()))),
            const SizedBox(width: 10),
            Expanded(child: _quickEntryBtn('Blood\nGlucose', Icons.water_drop_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF), () => _navigateAndRefresh(const GlucoseEntryScreen()))),
            const SizedBox(width: 10),
            Expanded(child: _quickEntryBtn('Weight', Icons.scale_rounded, const Color(0xFF059669), const Color(0xFFECFDF5), () => _navigateAndRefresh(const WeightEntryScreen()))),
          ],
        ),
      ],
    );
  }

  Widget _quickEntryBtn(String label, IconData icon, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadData();
  }

  // ─── BLOOD PRESSURE CARD ──────────────────────────────────────────────────

  Widget _buildBPCard() {
    final latest = _bpReadings.isNotEmpty ? _bpReadings.first : null;
    return _buildVitalsCard(
      title: 'Blood Pressure',
      icon: Icons.monitor_heart_rounded,
      color: const Color(0xFFDC2626),
      latestLabel: latest != null ? '${latest.systolic} / ${latest.diastolic}' : '-- / --',
      sublabel: latest != null ? '${latest.category} • ${DateFormat('MMM d').format(latest.measuredAt)}' : 'No readings yet',
      unit: 'mmHg',
      chart: _bpReadings.length >= 3 ? _buildBPChart() : _buildNoDataChart(),
      onAdd: () => _navigateAndRefresh(const BPEntryScreen()),
    );
  }

  Widget _buildBPChart() {
    final reversed = _bpReadings.reversed.toList();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: reversed.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.systolic.toDouble())).toList(),
            isCurved: true,
            color: const Color(0xFFDC2626),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: const Color(0xFFDC2626).withValues(alpha: 0.08)),
          ),
          LineChartBarData(
            spots: reversed.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.diastolic.toDouble())).toList(),
            isCurved: true,
            color: const Color(0xFFF97316),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            dashArray: [4, 3],
          ),
        ],
      ),
    );
  }

  // ─── GLUCOSE CARD ─────────────────────────────────────────────────────────

  Widget _buildGlucoseCard() {
    final latest = _glucoseReadings.isNotEmpty ? _glucoseReadings.first : null;
    return _buildVitalsCard(
      title: 'Blood Glucose',
      icon: Icons.water_drop_rounded,
      color: const Color(0xFF7C3AED),
      latestLabel: latest != null ? latest.glucoseValue.toStringAsFixed(0) : '--',
      sublabel: latest != null ? '${latest.typeLabel} • ${DateFormat('MMM d').format(latest.measuredAt)}' : 'No readings yet',
      unit: 'mg/dL',
      chart: _glucoseReadings.length >= 3 ? _buildGlucoseChart() : _buildNoDataChart(),
      onAdd: () => _navigateAndRefresh(const GlucoseEntryScreen()),
    );
  }

  Widget _buildGlucoseChart() {
    final reversed = _glucoseReadings.reversed.toList();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: reversed.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.glucoseValue)).toList(),
            isCurved: true,
            color: const Color(0xFF7C3AED),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF7C3AED).withValues(alpha: 0.08)),
          ),
        ],
      ),
    );
  }

  // ─── WEIGHT CARD ──────────────────────────────────────────────────────────

  Widget _buildWeightCard() {
    final latest = _weightReadings.isNotEmpty ? _weightReadings.first : null;
    double? change;
    if (_weightReadings.length >= 2) {
      change = latest!.weightKg - _weightReadings.last.weightKg;
    }
    final changeStr = change != null
        ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg vs ${_weightReadings.length} readings ago'
        : null;
    return _buildVitalsCard(
      title: 'Weight',
      icon: Icons.scale_rounded,
      color: const Color(0xFF059669),
      latestLabel: latest != null ? latest.weightKg.toStringAsFixed(1) : '--',
      sublabel: changeStr ?? (latest != null ? DateFormat('MMM d').format(latest.measuredAt) : 'No readings yet'),
      unit: 'kg',
      chart: _weightReadings.length >= 3 ? _buildWeightChart() : _buildNoDataChart(),
      onAdd: () => _navigateAndRefresh(const WeightEntryScreen()),
    );
  }

  Widget _buildWeightChart() {
    final reversed = _weightReadings.reversed.toList();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: reversed.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weightKg)).toList(),
            isCurved: true,
            color: const Color(0xFF059669),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF059669).withValues(alpha: 0.08)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataChart() {
    return const Center(
      child: Text('Record 3+ readings to see trend', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
    );
  }

  // ─── GENERIC VITALS CARD ──────────────────────────────────────────────────

  Widget _buildVitalsCard({
    required String title,
    required IconData icon,
    required Color color,
    required String latestLabel,
    required String sublabel,
    required String unit,
    required Widget chart,
    required VoidCallback onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: color, size: 16),
                      const SizedBox(width: 4),
                      Text('Add', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(latestLabel, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 6),
              Text(unit, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 2),
          Text(sublabel, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          SizedBox(height: 80, child: chart),
        ],
      ),
    );
  }

  // ─── ANALYSIS BUTTON ──────────────────────────────────────────────────────

  Widget _buildAnalysisButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthAnalysisScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF0072FF).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Health Analysis', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 3),
                  Text('Get AI-powered insights on your health trends', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
