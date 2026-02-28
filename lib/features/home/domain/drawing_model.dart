import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class DrawingStroke {
  final List<DrawingPoint> points;
  final Color color;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class DrawingText {
  final String text;
  final Color color;
  final Offset position;
  final double fontSize;

  DrawingText({
    required this.text,
    required this.color,
    required this.position,
    this.fontSize = 24.0,
  });
}
