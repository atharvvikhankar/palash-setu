import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OnnxInferenceService {
  static const MethodChannel _channel = MethodChannel('onnx_inference_plugin');

  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initializeModels', {
        'mt_en_indic_path': 'assets/models/indictrans2_en_indic_dist_200M.onnx',
        'mt_indic_en_path': 'assets/models/indictrans2_indic_en_dist_200M.onnx'
      });
      debugPrint('ONNX Inference Service initialized successfully.');
    } on PlatformException catch (e) {
      debugPrint("Failed to initialize ONNX models: '${e.message}'.");
    }
  }

  Future<String> recognizeSpeech(String audioFilePath) async {
    try {
      final String result = await _channel.invokeMethod('recognizeSpeech', {'audioPath': audioFilePath});
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to run ASR: '${e.message}'.");
      return '';
    }
  }

  Future<String> translateText(String text, String direction) async {
    try {
      final String result = await _channel.invokeMethod('translateText', {'text': text, 'direction': direction});
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to run MT: '${e.message}'.");
      return '';
    }
  }

  Future<String> synthesizeSpeech(String text, String voice) async {
    try {
      final String audioPath = await _channel.invokeMethod('synthesizeSpeech', {'text': text, 'voice': voice});
      return audioPath; // Returns path to generated WAV file
    } on PlatformException catch (e) {
      debugPrint("Failed to run TTS: '${e.message}'.");
      return '';
    }
  }
}
