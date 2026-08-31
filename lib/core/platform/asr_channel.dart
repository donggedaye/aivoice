import 'package:flutter/services.dart';

enum NetworkType { wifi, mobile, none, other }

class DecodedPcm {
  const DecodedPcm({
    required this.path,
    required this.sampleRate,
    required this.channels,
    required this.bytes,
  });

  final String path;
  final int sampleRate;
  final int channels;
  final int bytes;
}

/// `AsrBridge` 的 Dart 端封裝：解碼、雜湊、網路型態。
class AsrChannel {
  const AsrChannel();

  static const MethodChannel _method = MethodChannel('app.aivoice.mobile/asr');

  Future<String> modelsDir() async {
    final path = await _method.invokeMethod<String>('modelsDir');
    if (path == null) throw StateError('modelsDir returned null');
    return path;
  }

  Future<NetworkType> networkType() async {
    switch (await _method.invokeMethod<String>('networkType')) {
      case 'wifi':
        return NetworkType.wifi;
      case 'mobile':
        return NetworkType.mobile;
      case 'none':
        return NetworkType.none;
      default:
        return NetworkType.other;
    }
  }

  Future<String> sha256(String path) async {
    final result = await _method.invokeMapMethod<String, dynamic>(
      'sha256',
      {'path': path},
    );
    return result!['sha256'] as String;
  }

  Future<DecodedPcm> decodeToPcm({
    required String input,
    required String output,
  }) async {
    final result = await _method.invokeMapMethod<String, dynamic>(
      'decodeToPcm',
      {'input': input, 'output': output},
    );
    return DecodedPcm(
      path: result!['path'] as String,
      sampleRate: result['sampleRate'] as int,
      channels: result['channels'] as int,
      bytes: (result['bytes'] as num).toInt(),
    );
  }
}
