import 'package:flutter/material.dart';

class GymFitLogo extends StatelessWidget {
  const GymFitLogo({super.key, this.size = 22, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WeightlifterPainter(color: effectiveColor),
      ),
    );
  }
}

class _WeightlifterPainter extends CustomPainter {
  const _WeightlifterPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final s = size.width;
    final cx = s / 2;

    // Head
    canvas.drawCircle(Offset(cx, s * 0.15), s * 0.10, paint);

    // Torso - shield shape
    final torso = Path()
      ..moveTo(cx - s * 0.18, s * 0.28)
      ..lineTo(cx + s * 0.18, s * 0.28)
      ..lineTo(cx + s * 0.12, s * 0.50)
      ..lineTo(cx + s * 0.06, s * 0.58)
      ..lineTo(cx - s * 0.06, s * 0.58)
      ..lineTo(cx - s * 0.12, s * 0.50)
      ..close();
    canvas.drawPath(torso, paint);

    final limbPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s * 0.08;

    // Left arm - reaching up to barbell
    canvas.drawLine(
      Offset(cx - s * 0.17, s * 0.30),
      Offset(cx - s * 0.26, s * 0.12),
      limbPaint,
    );
    canvas.drawLine(
      Offset(cx - s * 0.26, s * 0.12),
      Offset(cx - s * 0.17, s * 0.04),
      limbPaint,
    );

    // Right arm - reaching up to barbell
    canvas.drawLine(
      Offset(cx + s * 0.17, s * 0.30),
      Offset(cx + s * 0.26, s * 0.12),
      limbPaint,
    );
    canvas.drawLine(
      Offset(cx + s * 0.26, s * 0.12),
      Offset(cx + s * 0.17, s * 0.04),
      limbPaint,
    );

    // Barbell bar
    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.045;
    canvas.drawLine(
      Offset(cx - s * 0.34, s * 0.02),
      Offset(cx + s * 0.34, s * 0.02),
      barPaint,
    );

    // Weight plates
    void drawPlate(double x, double w, double h) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, s * 0.02), width: w, height: h),
          Radius.circular(s * 0.015),
        ),
        paint,
      );
    }

    drawPlate(cx - s * 0.36, s * 0.06, s * 0.12);
    drawPlate(cx - s * 0.40, s * 0.04, s * 0.09);
    drawPlate(cx + s * 0.36, s * 0.06, s * 0.12);
    drawPlate(cx + s * 0.40, s * 0.04, s * 0.09);

    // Legs
    canvas.drawLine(
      Offset(cx - s * 0.06, s * 0.57),
      Offset(cx - s * 0.16, s * 0.82),
      limbPaint,
    );
    canvas.drawLine(
      Offset(cx - s * 0.16, s * 0.82),
      Offset(cx - s * 0.24, s * 0.84),
      limbPaint..strokeWidth = s * 0.065,
    );

    canvas.drawLine(
      Offset(cx + s * 0.06, s * 0.57),
      Offset(cx + s * 0.16, s * 0.82),
      limbPaint..strokeWidth = s * 0.08,
    );
    canvas.drawLine(
      Offset(cx + s * 0.16, s * 0.82),
      Offset(cx + s * 0.24, s * 0.84),
      limbPaint..strokeWidth = s * 0.065,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
