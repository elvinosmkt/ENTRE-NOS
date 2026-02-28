import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../domain/drawing_model.dart';

// State to hold the drawing data
class DrawingState {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final Color selectedColor;
  final double selectedStrokeWidth;
  final File? backgroundImage;
  final List<DrawingText> texts;

  const DrawingState({
    this.strokes = const [],
    this.currentStroke,
    this.selectedColor = const Color(0xFFFF4DA3),
    this.selectedStrokeWidth = 5.0,
    this.backgroundImage,
    this.texts = const [],
  });

  DrawingState copyWith({
    List<DrawingStroke>? strokes,
    DrawingStroke? currentStroke,
    Color? selectedColor,
    double? selectedStrokeWidth,
    File? backgroundImage,
    List<DrawingText>? texts,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      currentStroke: currentStroke ?? this.currentStroke,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedStrokeWidth: selectedStrokeWidth ?? this.selectedStrokeWidth,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      texts: texts ?? this.texts,
    );
  }
}

class DrawingController extends Notifier<DrawingState> {
  @override
  DrawingState build() {
    return const DrawingState();
  }

  void startStroke(Offset offset) {
    state = state.copyWith(
      currentStroke: DrawingStroke(
        points: [DrawingPoint(offset: offset, paint: Paint())],
        color: state.selectedColor,
        strokeWidth: state.selectedStrokeWidth,
      ),
    );
  }

  void updateStroke(Offset offset) {
    if (state.currentStroke == null) return;
    
    final newPoints = List<DrawingPoint>.from(state.currentStroke!.points)
      ..add(DrawingPoint(offset: offset, paint: Paint()));
      
    state = state.copyWith(
      currentStroke: DrawingStroke(
        points: newPoints,
        color: state.currentStroke!.color,
        strokeWidth: state.currentStroke!.strokeWidth,
      ),
    );
  }

  void endStroke() {
    if (state.currentStroke == null) return;
    
    final newStrokes = List<DrawingStroke>.from(state.strokes)
      ..add(state.currentStroke!);
      
    state = DrawingState(
       strokes: newStrokes,
       currentStroke: null,
       selectedColor: state.selectedColor,
       selectedStrokeWidth: state.selectedStrokeWidth,
       backgroundImage: state.backgroundImage,
    );
  }

  void clearCanvas() {
    state = DrawingState(
       strokes: [],
       currentStroke: null,
       selectedColor: state.selectedColor,
       selectedStrokeWidth: state.selectedStrokeWidth,
       backgroundImage: null,
       texts: [],
    );
  }
  
  void addText(String text, {Offset? position}) {
    // Adiciona o texto ao centro do canvas (ajustavel depois)
    final newTexts = List<DrawingText>.from(state.texts)
      ..add(DrawingText(
        text: text,
        color: state.selectedColor,
        position: position ?? const Offset(150, 200),
        fontSize: 22,
      ));
    state = state.copyWith(texts: newTexts);
  }
  
  void undo() {
    if (state.strokes.isNotEmpty) {
       final newStrokes = List<DrawingStroke>.from(state.strokes)..removeLast();
       state = state.copyWith(strokes: newStrokes);
    }
  }

  void setColor(Color color) {
    state = state.copyWith(selectedColor: color);
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(selectedStrokeWidth: width);
  }

  void setBackgroundImage(File? image) {
    state = state.copyWith(backgroundImage: image);
  }
}

final drawingControllerProvider = NotifierProvider<DrawingController, DrawingState>(DrawingController.new);
