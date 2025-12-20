import 'package:flutter/material.dart';
import 'dart:math';

class FintechPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  FintechPatternPainter({
    required this.color,
    this.opacity = 0.05,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    var filledPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Draw grid points/connectors
    final random = Random(42); // Fixed seed for consistent pattern
    final spacing = size.width / 8;
    
    // Draw some random connection lines like a network
    for (var i = 0; i < 20; i++) {
      final p1 = Offset(
        random.nextDouble() * size.width, 
        random.nextDouble() * size.height
      );
      final p2 = Offset(
        p1.dx + (random.nextDouble() - 0.5) * spacing * 3, 
        p1.dy + (random.nextDouble() - 0.5) * spacing * 3
      );
      canvas.drawLine(p1, p2, paint);
      canvas.drawCircle(p1, 2, filledPaint);
    }

    // Draw some subtle charts/graphs style lines
    var path = Path();
    var currentX = 0.0;
    var currentY = size.height * 0.8;
    path.moveTo(currentX, currentY);
    
    while(currentX < size.width) {
      currentX += 40;
      currentY -= (random.nextDouble() - 0.4) * 30; // Upward trend
      path.lineTo(currentX, currentY);
    }
    canvas.drawPath(path, paint..strokeWidth = 2);

    // Draw geometric shapes
    for (var i = 0; i < 5; i++) {
       final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height
      );
      final radius = 20.0 + random.nextDouble() * 30;
      canvas.drawCircle(center, radius, paint..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
