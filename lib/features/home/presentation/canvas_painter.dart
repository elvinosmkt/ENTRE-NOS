import 'package:flutter/material.dart';
import '../domain/drawing_model.dart';

class CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final List<DrawingText> texts;

  CanvasPainter({
    required this.strokes,
    this.currentStroke,
    this.texts = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw saved strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }

    // Draw texts
    for (final textItem in texts) {
      final textSpan = TextSpan(
        text: textItem.text,
        style: TextStyle(
          color: textItem.color,
          fontSize: textItem.fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: size.width - textItem.position.dx - 20);
      textPainter.paint(canvas, textItem.position);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;
    
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (stroke.points.isNotEmpty) {
      path.moveTo(stroke.points.first.offset.dx, stroke.points.first.offset.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].offset.dx, stroke.points[i].offset.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return true; 
  }
}
