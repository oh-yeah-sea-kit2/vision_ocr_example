import 'dart:async';
import 'package:flutter/services.dart';

class OCRService {
  static const MethodChannel _channel = MethodChannel('com.example.ocr');

  Future<String?> recognizeText(String imagePath) async {
    try {
      final String? result = await _channel
          .invokeMethod('recognizeText', {'imagePath': imagePath});
      return result;
    } on PlatformException catch (e) {
      print("Failed to recognize text: ${e.message}");
      return null;
    }
  }
}
