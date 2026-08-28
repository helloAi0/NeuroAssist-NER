import 'package:flutter/material.dart';

enum MotifType { assamese, naga, mizo }

class CulturalMotifPainter extends CustomPainter {
  final MotifType type;
  final Color primaryColor;
  final Color secondaryColor;

  CulturalMotifPainter({
    required this.type,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case MotifType.assamese:
        _drawAssameseGamosaMotif(canvas, size);
        break;
      case MotifType.naga:
        _drawNagaGeometricMotif(canvas, size);
        break;
      case MotifType.mizo:
        _drawMizoPuanMotif(canvas, size);
        break;
    }
  }

  void _drawAssameseGamosaMotif(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final path = Path();
    double w = size.width;
    double h = size.height;
    double step = w / 8;

    for (double x = 0; x < w; x += step) {
      for (double y = 0; y < h; y += step) {
        path.reset();
        path.moveTo(x + step / 2, y);
        path.lineTo(x + step, y + step / 2);
        path.lineTo(x + step / 2, y + step);
        path.lineTo(x, y + step / 2);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawNagaGeometricMotif(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    double w = size.width;
    double h = size.height;
    double chevronHeight = 20.0;

    for (double y = 0; y < h; y += chevronHeight * 1.5) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= w; x += 40) {
        path.lineTo(x + 20, y + chevronHeight);
        path.lineTo(x + 40, y);
      }
      canvas.drawPath(path, strokePaint);
    }

    final accentPath = Path();
    accentPath.moveTo(w / 2, h / 2 - 15);
    accentPath.lineTo(w / 2 + 15, h / 2);
    accentPath.lineTo(w / 2, h / 2 + 15);
    accentPath.lineTo(w / 2 - 15, h / 2);
    accentPath.close();
    canvas.drawPath(accentPath, fillPaint);
  }

  void _drawMizoPuanMotif(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final altPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    double stripeHeight = 12.0;
    for (double y = 0; y < size.height; y += stripeHeight * 2.5) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, stripeHeight),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, y + stripeHeight + 2, size.width, stripeHeight / 2),
        altPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CulturalMotifPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}