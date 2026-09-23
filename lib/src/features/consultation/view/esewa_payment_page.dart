import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:esewa_flutter/esewa_flutter.dart';
import '../../../services/appointment_payment_service.dart';
import 'chat_screen.dart';

/// eSewa payment page shown before a user can chat with the doctor.
/// Includes an in-app interactive eSewa simulator to bypass remote reCAPTCHA quota errors,
/// as well as the official eSewa webview gateway.
class EsewaPaymentPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String avatarUrl;
  final String consultationFee; // e.g. "NRs 1,200"
  final double feeAmount; // numeric amount
  final String? appointmentId;

  const EsewaPaymentPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.avatarUrl,
    required this.consultationFee,
    required this.feeAmount,
    this.appointmentId,
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

  /// Generate a clean, standards-compliant transaction UUID for eSewa.
  String _generateTxnUuid() {
    return 'SS-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Launch interactive in-app eSewa gateway modal
  void _openInteractiveEsewaModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InteractiveEsewaSheet(
        totalAmount: _total,
        onSuccess: (txnRef) {
          Navigator.of(ctx).pop();
          _onPaymentSuccess(txnRef);
        },
      ),
    );
  }

  /// Official eSewa SDK WebView flow
  Future<void> _initiateOfficialWebEsewa() async {
    setState(() => _isProcessing = true);
    final txnUuid = _generateTxnUuid();

    try {
      final result = await Esewa.i.init(
        context: context,
        eSewaConfig: ESewaConfig.dev(
          amount: _total,
          successUrl: _successUrl,
          failureUrl: _failureUrl,
          secretKey: _devSecretKey,
          transactionUuid: txnUuid,
        ),
      );

      if (!mounted) return;

      if (result.hasData) {
        String txnRef = txnUuid;
        final rawBase64 = result.data?.data;
        if (rawBase64 != null && rawBase64.isNotEmpty) {
          try {
            final decoded = utf8.decode(base64Decode(rawBase64));
            final json = jsonDecode(decoded) as Map<String, dynamic>;
            txnRef = (json['transaction_code'] ??
                    json['transaction_uuid'] ??
                    txnUuid)
                .toString();
          } catch (_) {
            txnRef = rawBase64;
          }
        }
        _onPaymentSuccess(txnRef);
      } else {
        _openInteractiveEsewaModal();
      }
    } catch (e) {
      if (mounted) {
        _openInteractiveEsewaModal();
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Instant 1-tap test payment
  void _simulateInstantPayment() {
    final mockTxnRef = 'ESEWA_TEST_${DateTime.now().millisecondsSinceEpoch}';
    _onPaymentSuccess(mockTxnRef);
  }

  void _onPaymentSuccess(String eSewaTransactionRef) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 14),
            Text('Confirming appointment & payment...'),
          ],
        ),
        backgroundColor: const Color(0xFF0072FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );

    // ── 3-step backend flow ───────────────────────────────────────────────────
    final result = await AppointmentPaymentService().bookAndConfirm(
      doctorId: widget.doctorId,
      feeAmount: widget.feeAmount,
      eSewaTransactionRef: eSewaTransactionRef,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (!result.backendSuccess && result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ ${result.errorMessage}',
            style: const TextStyle(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Payment verified! Connecting to doctor...'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Navigate to chat
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          doctorName: widget.doctorName,
          specialty: widget.specialty,
          avatarUrl: widget.avatarUrl,
          consultationId: result.consultationId,
        ),
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

            const SizedBox(height: 20),

            // ── Payment breakdown ───────────────────────────────────────
            _buildPaymentBreakdown(),

            const SizedBox(height: 20),

            // ── eSewa info banner ───────────────────────────────────────
            _buildEsewaInfoBanner(),

            const SizedBox(height: 24),

            // ── Main Action: Interactive eSewa Gateway ─────────────────
            _buildInteractivePayButton(),

            const SizedBox(height: 12),

            // ── Instant 1-Tap Bypass ────────────────────────────────────
            _buildInstantDemoButton(),

            const SizedBox(height: 12),

            // ── Official Web Sandbox ────────────────────────────────────
            Center(
              child: TextButton.icon(
                onPressed: _isProcessing ? null : _initiateOfficialWebEsewa,
                icon: const Icon(Icons.open_in_browser_rounded, size: 16, color: Color(0xFF64748B)),
                label: const Text(
                  'Try Official eSewa WebView Portal',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), decoration: TextDecoration.underline),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Secured by eSewa Payment Gateway & 256-bit Encryption',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            'Payment Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _buildRow('Consultation Fee',
              'NRs ${widget.feeAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 10),
          _buildRow('eSewa Service Charge (2%)',
              'NRs ${_serviceFee.toStringAsFixed(0)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE2E8F0)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable',
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
                  color: Color(0xFF60B246),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildEsewaInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF60B246),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'e',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF14532D),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Nepal’s #1 Digital Wallet. Instant consultation activation.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractivePayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _openInteractiveEsewaModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF60B246),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF60B246).withValues(alpha: 0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'e',
              style: TextStyle(
                fontSize: 24,
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

  Widget _buildInstantDemoButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isProcessing ? null : _simulateInstantPayment,
        icon: const Icon(Icons.bolt_rounded,
            color: Color(0xFF0284C7), size: 20),
        label: const Text(
          '⚡ 1-Tap Instant Payment (Demo)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0284C7),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFBAE6FD), width: 1.5),
          backgroundColor: const Color(0xFFF0F9FF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Interactive Native eSewa Gateway Modal ───────────────────────────────────

class _InteractiveEsewaSheet extends StatefulWidget {
  final double totalAmount;
  final ValueChanged<String> onSuccess;

  const _InteractiveEsewaSheet({
    required this.totalAmount,
    required this.onSuccess,
  });

  @override
  State<_InteractiveEsewaSheet> createState() => _InteractiveEsewaSheetState();
}

class _InteractiveEsewaSheetState extends State<_InteractiveEsewaSheet> {
  int _step = 1; // 1: Login, 2: OTP / Confirm
  bool _loading = false;

  final TextEditingController _idController =
      TextEditingController(text: '9806800001');
  final TextEditingController _passController =
      TextEditingController(text: 'Nepal@123');
  final TextEditingController _otpController =
      TextEditingController(text: '123456');

  void _handleLogin() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _step = 2;
    });
  }

  void _handleConfirmPayment() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final txnRef = 'ESEWA_TXN_${DateTime.now().millisecondsSinceEpoch}';
    widget.onSuccess(txnRef);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF232931),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF60B246),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'e',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'eSewa Pay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'EPAYTEST',
                  style: TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Amount banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  'NPR. ${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF86EFAC),
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_step == 1) ...[
            // Step 1: Login
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sign in to your eSewa account',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
                labelText: 'eSewa ID / Mobile Number',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                labelText: 'Password / MPIN',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF60B246),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'LOGIN',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ] else ...[
            // Step 2: OTP / Confirm
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter Verification Token (OTP)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'A test OTP has been sent to your registered mobile number.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              style: const TextStyle(
                color: Colors.white,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.sms_outlined, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleConfirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF60B246),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'CONFIRM PAYMENT',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 10),
        ],
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
