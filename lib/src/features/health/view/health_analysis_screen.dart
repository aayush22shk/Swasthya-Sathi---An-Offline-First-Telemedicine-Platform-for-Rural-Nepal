import 'package:flutter/material.dart';
import '../../../services/health_service.dart';

class HealthAnalysisScreen extends StatefulWidget {
  const HealthAnalysisScreen({super.key});
  @override
  State<HealthAnalysisScreen> createState() => _HealthAnalysisScreenState();
}

class _HealthAnalysisScreenState extends State<HealthAnalysisScreen>
    with TickerProviderStateMixin {
  final HealthService _service = HealthService();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  HealthAnalysis? _analysis;
  AIExplanation? _aiExplanation;
  bool _isGenerating = false;
  bool _isExplaining = false;
  String _selectedPeriod = '30d';
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateAnalysis() async {
    setState(() { _isGenerating = true; _error = null; _analysis = null; _aiExplanation = null; });
    try {
      final analysis = await _service.generateAnalysis(period: _selectedPeriod);
      if (mounted) setState(() { _analysis = analysis; _isGenerating = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isGenerating = false; });
    }
  }

  Future<void> _getAIExplanation() async {
    if (_analysis == null) return;
    setState(() => _isExplaining = true);
    try {
      final explanation = await _service.getAIExplanation(analysisId: _analysis!.id);
      if (mounted) setState(() { _aiExplanation = explanation; _isExplaining = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isExplaining = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e'), backgroundColor: const Color(0xFFDC2626)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Health Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            _buildGenerateButton(),
            if (_error != null) ...[const SizedBox(height: 16), _buildErrorCard(_error!)],
            if (_isGenerating) ...[const SizedBox(height: 32), _buildGeneratingLoader()],
            if (_analysis != null) ...[
              const SizedBox(height: 20),
              _buildAnalysisResults(),
              const SizedBox(height: 16),
              if (_aiExplanation == null) _buildGetAIButton(),
              if (_isExplaining) ...[const SizedBox(height: 24), _buildExplainingLoader()],
              if (_aiExplanation != null) ...[const SizedBox(height: 16), _buildAIExplanation()],
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))]),
      child: Row(
        children: [
          for (final p in ['7d', '30d', '90d'])
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPeriod = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedPeriod == p ? const Color(0xFF0072FF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    p == '7d' ? 'Last 7 Days' : p == '30d' ? 'Last 30 Days' : 'Last 90 Days',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedPeriod == p ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.analytics_rounded),
        label: const Text('Generate Health Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: _isGenerating ? null : _generateAnalysis,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0072FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildGeneratingLoader() {
    return Center(
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0072FF), Color(0xFF00C6FF)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Analyzing your health data...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          const Text('Computing statistics & detecting trends', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildExplainingLoader() {
    return Center(
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA855F7)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          const Text('AI is generating your explanation...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          const Text('This may take a few seconds', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    final a = _analysis!;
    final bp = a.bloodPressure;
    final glucose = a.glucose;
    final weight = a.weight;
    final flags = a.flags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📊 Analysis Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        if (flags.isNotEmpty) _buildFlagsCard(flags),
        if (bp != null) _buildMetricCard('🩸 Blood Pressure', const Color(0xFFDC2626), _bpSummary(bp)),
        const SizedBox(height: 12),
        if (glucose != null) _buildMetricCard('💧 Blood Glucose', const Color(0xFF7C3AED), _glucoseSummary(glucose)),
        const SizedBox(height: 12),
        if (weight != null) _buildMetricCard('⚖️ Weight', const Color(0xFF059669), _weightSummary(weight)),
      ],
    );
  }

  Widget _buildFlagsCard(List<dynamic> flags) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.flag_rounded, color: Color(0xFFF59E0B), size: 18),
            SizedBox(width: 8),
            Text('Clinical Alerts', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          ...flags.map((f) {
            final severity = f['severity'] ?? 'info';
            final color = severity == 'critical' ? const Color(0xFFDC2626) : severity == 'alert' ? const Color(0xFFF59E0B) : const Color(0xFF0072FF);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.circle, color: color, size: 8),
                const SizedBox(width: 8),
                Expanded(child: Text(f['message'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, Color color, List<_MetricRow> rows) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(r.label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              Text(r.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: r.highlighted ? color : const Color(0xFF0F172A))),
            ]),
          )),
        ],
      ),
    );
  }

  List<_MetricRow> _bpSummary(Map<String, dynamic> bp) => [
    _MetricRow('Readings', '${bp['measurement_count'] ?? 0}'),
    if (bp['latest'] != null) _MetricRow('Latest', '${bp['latest']['systolic']}/${bp['latest']['diastolic']} mmHg', highlighted: true),
    if (bp['average_30d'] != null) _MetricRow('30-Day Avg', '${bp['average_30d']['systolic']}/${bp['average_30d']['diastolic']} mmHg'),
    _MetricRow('Trend', _trendLabel(bp['trend'])),
  ];

  List<_MetricRow> _glucoseSummary(Map<String, dynamic> g) => [
    _MetricRow('Readings', '${g['measurement_count'] ?? 0}'),
    if (g['latest'] != null) _MetricRow('Latest', '${g['latest']['value']} ${g['latest']['unit']}', highlighted: true),
    if (g['fasting_average_30d'] != null) _MetricRow('Fasting Avg (30d)', '${g['fasting_average_30d']} mg/dL'),
    _MetricRow('Trend', _trendLabel(g['trend'])),
  ];

  List<_MetricRow> _weightSummary(Map<String, dynamic> w) => [
    _MetricRow('Readings', '${w['measurement_count'] ?? 0}'),
    if (w['latest_kg'] != null) _MetricRow('Current', '${w['latest_kg']} kg', highlighted: true),
    if (w['change_30d_kg'] != null) _MetricRow('30-Day Change', '${w['change_30d_kg'] >= 0 ? '+' : ''}${w['change_30d_kg']} kg'),
  ];

  String _trendLabel(dynamic t) => switch (t) {
    'increasing' => '⬆️ Increasing',
    'decreasing' => '⬇️ Decreasing',
    'stable' => '➡️ Stable',
    _ => '📊 Insufficient data',
  };

  Widget _buildGetAIButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Get AI Explanation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: _isExplaining ? null : _getAIExplanation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAIExplanation() {
    final ai = _aiExplanation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA855F7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('AI Health Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 12),
            Text(ai.summary, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          ]),
        ),
        if (ai.safetyMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3))),
            child: Row(children: [
              const Icon(Icons.warning_rounded, color: Color(0xFFDC2626)),
              const SizedBox(width: 12),
              Expanded(child: Text(ai.safetyMessage!, style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600, fontSize: 13))),
            ]),
          ),
        ],
        if (ai.observations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAISection('📋 Observations', ai.observations.map((o) => o['message']?.toString() ?? '').where((s) => s.isNotEmpty).toList(), const Color(0xFF0072FF)),
        ],
        if (ai.recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAISection('💡 Recommendations', ai.recommendations.map((r) => r['message']?.toString() ?? '').where((s) => s.isNotEmpty).toList(), const Color(0xFF059669)),
        ],
        if (ai.questionsForClinician.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAISection('🩺 Questions for Your Doctor', ai.questionsForClinician, const Color(0xFF7C3AED)),
        ],
        if (ai.disclaimer != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Text(ai.disclaimer!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
          ),
        ],
      ],
    );
  }

  Widget _buildAISection(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6, right: 10), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4))),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
        const SizedBox(width: 12),
        Expanded(child: Text(error, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13))),
      ]),
    );
  }
}

class _MetricRow {
  final String label;
  final String value;
  final bool highlighted;
  _MetricRow(this.label, this.value, {this.highlighted = false});
}
