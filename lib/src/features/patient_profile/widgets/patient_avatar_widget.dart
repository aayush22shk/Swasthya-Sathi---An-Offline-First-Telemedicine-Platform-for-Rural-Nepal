import 'package:flutter/material.dart';

class PatientAvatarWidget extends StatelessWidget {
  final double size;
  final String? photoUrl;
  final String? initials;
  final bool showEditBadge;
  final VoidCallback? onEditTap;

  const PatientAvatarWidget({
    super.key,
    this.size = 84.0,
    this.photoUrl,
    this.initials,
    this.showEditBadge = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarBody = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFD4EFE9), // Soft mint / teal background
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildVectorIllustration(),
              )
            : _buildVectorIllustration(),
      ),
    );

    if (!showEditBadge && onEditTap == null) {
      return avatarBody;
    }

    final badgeSize = (size * 0.32).clamp(24.0, 34.0);

    return GestureDetector(
      onTap: onEditTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarBody,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: const Color(0xFF0072FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0072FF).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: badgeSize * 0.52,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVectorIllustration() {
    return CustomPaint(
      size: Size(size, size),
      painter: _AvatarPainter(),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Head / Face
    final facePaint = Paint()..color = const Color(0xFFFFDFC4); // skin tone
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.42),
        width: w * 0.38,
        height: h * 0.44,
      ),
      Radius.circular(w * 0.18),
    );
    canvas.drawRRect(faceRect, facePaint);

    // Dark Hair
    final hairPaint = Paint()..color = const Color(0xFF334155); // dark charcoal hair
    final hairPath = Path();
    hairPath.moveTo(w * 0.28, h * 0.4);
    hairPath.quadraticBezierTo(w * 0.26, h * 0.2, w * 0.5, h * 0.18);
    hairPath.quadraticBezierTo(w * 0.74, h * 0.2, w * 0.72, h * 0.4);
    hairPath.quadraticBezierTo(w * 0.65, h * 0.28, w * 0.5, h * 0.27);
    hairPath.quadraticBezierTo(w * 0.35, h * 0.28, w * 0.28, h * 0.4);
    hairPath.close();
    canvas.drawPath(hairPath, hairPaint);

    // Hair Top volume
    final hairTopPath = Path();
    hairTopPath.addOval(Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.24),
      width: w * 0.44,
      height: h * 0.22,
    ));
    canvas.drawPath(hairTopPath, hairPaint);

    // Teal Shirt / Body
    final shirtPaint = Paint()..color = const Color(0xFF00A896); // Vibrant medical teal
    final shirtPath = Path();
    shirtPath.moveTo(w * 0.15, h);
    shirtPath.quadraticBezierTo(w * 0.2, h * 0.68, w * 0.38, h * 0.64);
    // V-neck
    shirtPath.lineTo(w * 0.5, h * 0.76);
    shirtPath.lineTo(w * 0.62, h * 0.64);
    shirtPath.quadraticBezierTo(w * 0.8, h * 0.68, w * 0.85, h);
    shirtPath.close();
    canvas.drawPath(shirtPath, shirtPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
