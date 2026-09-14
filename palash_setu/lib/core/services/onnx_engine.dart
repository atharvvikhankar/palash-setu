import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef InitEngineFunc = Int32 Function(Pointer<Utf8> modelPath);
typedef InitEngine = int Function(Pointer<Utf8> modelPath);

typedef TranslateTextFunc = Pointer<Utf8> Function(Pointer<Utf8> inputText);
typedef TranslateText = Pointer<Utf8> Function(Pointer<Utf8> inputText);

class OnnxTranslationEngine {
  static final OnnxTranslationEngine _instance = OnnxTranslationEngine._internal();
  factory OnnxTranslationEngine() => _instance;
  
  late DynamicLibrary _nativeLib;
  late InitEngine _initEngine;
  late TranslateText _translateText;
  
  bool _isInitialized = false;

  OnnxTranslationEngine._internal() {
    if (Platform.isAndroid) {
      _nativeLib = DynamicLibrary.open('libonnx_inference.so');
    } else if (Platform.isIOS) {
      _nativeLib = DynamicLibrary.process();
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    _initEngine = _nativeLib
        .lookup<NativeFunction<InitEngineFunc>>('init_translation_engine')
        .asFunction();

    _translateText = _nativeLib
        .lookup<NativeFunction<TranslateTextFunc>>('translate_text')
        .asFunction();
  }

  Future<void> initialize(String modelPath) async {
    if (_isInitialized) return;
    
    final pathPointer = modelPath.toNativeUtf8();
    final result = _initEngine(pathPointer);
    calloc.free(pathPointer);
    
    if (result != 0) {
      throw Exception('Failed to initialize ONNX engine (Error code: $result)');
    }
    
    _isInitialized = true;
  }

  Future<String> translate(String text) async {
    if (!_isInitialized) {
      throw Exception('Engine not initialized');
    }
    
    final textPointer = text.toNativeUtf8();
    final resultPointer = _translateText(textPointer);
    
    final translated = resultPointer.toDartString();
    
    calloc.free(textPointer);
    // Note: in a real implementation we would also need a C++ free function 
    // to free the char* returned by translateText if it was dynamically allocated.
    
    return translated;
  }
}
