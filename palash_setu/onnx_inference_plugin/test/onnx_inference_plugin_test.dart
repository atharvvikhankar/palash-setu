import 'package:flutter_test/flutter_test.dart';
import 'package:onnx_inference_plugin/onnx_inference_plugin.dart';
import 'package:onnx_inference_plugin/onnx_inference_plugin_platform_interface.dart';
import 'package:onnx_inference_plugin/onnx_inference_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockOnnxInferencePluginPlatform
    with MockPlatformInterfaceMixin
    implements OnnxInferencePluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final OnnxInferencePluginPlatform initialPlatform = OnnxInferencePluginPlatform.instance;

  test('$MethodChannelOnnxInferencePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelOnnxInferencePlugin>());
  });

  test('getPlatformVersion', () async {
    OnnxInferencePlugin onnxInferencePlugin = OnnxInferencePlugin();
    MockOnnxInferencePluginPlatform fakePlatform = MockOnnxInferencePluginPlatform();
    OnnxInferencePluginPlatform.instance = fakePlatform;

    expect(await onnxInferencePlugin.getPlatformVersion(), '42');
  });
}
