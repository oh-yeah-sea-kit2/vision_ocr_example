import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ocr_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TextRecognitionScreen(),
    );
  }
}

class TextRecognitionScreen extends StatefulWidget {
  @override
  _TextRecognitionScreenState createState() => _TextRecognitionScreenState();
}

class _TextRecognitionScreenState extends State<TextRecognitionScreen> {
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();
  String _recognizedText = '';

  Future<void> _pickImageAndRecognizeText() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final String? text = await _ocrService.recognizeText(image.path);
      setState(() {
        _recognizedText = text ?? 'No text recognized.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Text Recognition')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickImageAndRecognizeText,
              child: Text('Select Image and Recognize Text'),
            ),
            SizedBox(height: 20),
            Text(_recognizedText, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
