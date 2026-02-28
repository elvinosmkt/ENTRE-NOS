import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'drawing_controller.dart';
import 'canvas_painter.dart';

class DrawingCanvas extends ConsumerStatefulWidget {
  const DrawingCanvas({super.key});

  @override
  ConsumerState<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends ConsumerState<DrawingCanvas> {
  final GlobalKey _paintKey = GlobalKey();

  Future<Uint8List?> capturePng() async {
    try {
      RenderRepaintBoundary? boundary =
          _paintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) return null;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing canvas: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingControllerProvider);
    final controller = ref.read(drawingControllerProvider.notifier);

    return RepaintBoundary(
      key: _paintKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent to show dark background for Neon
          image: drawingState.backgroundImage != null
              ? DecorationImage(
                  image: FileImage(drawingState.backgroundImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // Required for transparent hit testing
          onPanStart: (details) {
            controller.startStroke(details.localPosition);
          },
          onPanUpdate: (details) {
            controller.updateStroke(details.localPosition);
          },
          onPanEnd: (details) {
            controller.endStroke();
          },
          child: CustomPaint(
            painter: CanvasPainter(
              strokes: drawingState.strokes,
              currentStroke: drawingState.currentStroke,
              texts: drawingState.texts,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}
