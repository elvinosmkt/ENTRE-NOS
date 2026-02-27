import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId = 'group.com.entrenos.app'; // Helper for iOS App Group
  static const String iOSWidgetName = 'EntreNosWidget'; // Name of the widget in Xcode

  Future<void> sendData({
    required Uint8List imageBytes,
    required String text,
    required String author,
  }) async {
    try {
      // Initialize the App Group for iOS
      await HomeWidget.setAppGroupId(appGroupId);
      
      // Save data
      await HomeWidget.saveWidgetData<String>('text', text);
      await HomeWidget.saveWidgetData<String>('author', author);
      
      // Save image to App Group as Base64 string
      final base64Image = base64Encode(imageBytes);
      await HomeWidget.saveWidgetData<String>('imageData', base64Image);
      
      // 2. Update Widget
      await HomeWidget.updateWidget(
        name: iOSWidgetName,
        iOSName: iOSWidgetName,
      );
      
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}
