
import 'onnx_inference_plugin_platform_interface.dart';

class OnnxInferencePlugin {
  Future<String?> getPlatformVersion() {
    return OnnxInferencePluginPlatform.instance.getPlatformVersion();
  }
}
