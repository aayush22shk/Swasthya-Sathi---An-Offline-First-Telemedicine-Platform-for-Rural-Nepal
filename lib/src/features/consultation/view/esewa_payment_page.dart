import 'package:flutter/material.dart';
import 'package:esewa_flutter/esewa_flutter.dart';
import 'chat_screen.dart';

/// eSewa payment page shown before a user can chat with the doctor.
/// Uses the developer/sandbox environment (ESewaConfig.dev).
class EsewaPaymentPage extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String avatarUrl;
  final String consultationFee; // e.g. "NRs 1,200"
  final double feeAmount; // numeric amount

  const EsewaPaymentPage({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.avatarUrl,
    required this.consultationFee,
    required this.feeAmount,
  });

  @override
  State<EsewaPaymentPage> createState() => _EsewaPaymentPageState();
}

class _EsewaPaymentPageState extends State<EsewaPaymentPage> {
  bool _isProcessing = false;

  // Developer-mode eSewa secret key (EPAYTEST)
  static const String _devSecretKey = '8gBm/:&EnhH.1/q';
  static const String _successUrl = 'https://developer.esewa.com.np/success';
  static const String _failureUrl = 'https://developer.esewa.com.np/failure';

  double get _serviceFee => (widget.feeAmount * 0.02).roundToDouble();
  double get _total => widget.feeAmount + _serviceFee;

  Future<void> _initiatePayment() async {
    setState(() => _isProcessing = true);
    try {
      final result = await Esewa.i.init(
        context: context,
        eSewaConfig: ESewaConfig.dev(
          amount: _total,
          successUrl: _successUrl,
          failureUrl: _failureUrl,
          secretKey: _devSecretKey,
          transactionUuid: 'CONSULT_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      if (!mounted) return;

      if (result.hasData) {
        // Payment successful – open chat screen
        _onPaymentSuccess();
      } else {
        _showSnack(
          result.error ?? 'Payment was cancelled or failed. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Payment error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _onPaymentSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          doctorName: widget.doctorName,
          specialty: widget.specialty,
          avatarUrl: widget.avatarUrl,
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Consultation Payment',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Doctor summary card ─────────────────────────────────────
            _DoctorSummaryCard(
              doctorName: widget.doctorName,
              specialty: widget.specialty,
              avatarUrl: widget.avatarUrl,
            ),

            const SizedBox(height: 24),

            // ── Payment breakdown ───────────────────────────────────────
            _buildPaymentBreakdown(),

            const SizedBox(height: 24),

            // ── eSewa info banner ───────────────────────────────────────
            _buildEsewaInfoBanner(),

            const SizedBox(height: 24),

            // ── Test credentials hint (dev only) ───────────────────────
            _buildDevHint(),

            const SizedBox(height: 32),

            // ── Pay button ─────────────────────────────────────────────
            _buildPayButton(),

            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Secured by eSewa Payment Gateway',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Doctor summary ──────────────────────────────────────────────────────
  Widget _buildPaymentBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x09000000), blurRadius: 14, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _breakdownRow('Consultation Fee', widget.consultationFee),
          const SizedBox(height: 10),
          _breakdownRow(
            'Service Charge (2%)',
            'NRs ${_serviceFee.toStringAsFixed(0)}',
            secondary: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'NRs ${_total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0072FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value,
      {bool secondary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: secondary
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569))),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: secondary
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF334155))),
      ],
    );
  }

  Widget _buildEsewaInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF60B246), Color(0xFF4A9535)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'e',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay with eSewa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Fast, secure & trusted digital wallet in Nepal',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded,
              color: Colors.white70, size: 22),
        ],
      ),
    );
  }

  Widget _buildDevHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: Color(0xFFD97706), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Developer / Test Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'eSewa ID: 9806800001\nPassword: Nepal@123\nMPIN: 1122',
                  style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                  // ignore: unnecessary_string_escapes
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF60B246),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF60B246).withValues(alpha: 0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'e',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pay NRs ${_total.toStringAsFixed(0)} via eSewa',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Doctor summary card ─────────────────────────────────────────────────────

class _DoctorSummaryCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final String avatarUrl;

  const _DoctorSummaryCard({
    required this.doctorName,
    required this.specialty,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x09000000), blurRadius: 14, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              avatarUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person,
                    color: Color(0xFF0072FF), size: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(specialty,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.video_call_rounded,
                          size: 14, color: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text('Video Consultation',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
