import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'onnx_inference_plugin_platform_interface.dart';

/// An implementation of [OnnxInferencePluginPlatform] that uses method channels.
class MethodChannelOnnxInferencePlugin extends OnnxInferencePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('onnx_inference_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
