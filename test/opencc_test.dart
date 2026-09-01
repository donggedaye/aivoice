import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aivoice/core/utils/opencc.dart';

/// 直接從專案目錄讀字典，不依賴測試用的 asset bundle。
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}

void main() {
  late OpenCC converter;

  setUpAll(() async {
    converter = await OpenCC.s2twp(bundle: _DiskBundle());
  });

  test('simplified characters become traditional', () {
    expect(converter.convert('数'), '數');
    expect(converter.convert('网'), '網');
  });

  test('Taiwan phrases win over a plain traditional conversion', () {
    // 软件 -> 軟件（第一段）-> 軟體（第二段的台灣用詞）
    expect(converter.convert('软件'), '軟體');
    expect(converter.convert('网络'), '網路');
    expect(converter.convert('服务器'), '伺服器');
    expect(converter.convert('数据'), '資料');
  });

  test('phrases already traditional still get Taiwan wording', () {
    expect(converter.convert('信息'), '資訊');
  });

  test('Taiwan variants apply after the phrase pass', () {
    // 里面 -> 裏面（STPhrases）-> 裡面（TWVariants 的 裏->裡）
    expect(converter.convert('里面'), '裡面');
  });

  test('text with no mapping is left alone', () {
    expect(converter.convert('正體中文'), '正體中文');
    expect(converter.convert('ABC 123 !?'), 'ABC 123 !?');
    expect(converter.convert(''), '');
  });

  // 上游 OpenCC 依教育部標準把 台 對到 臺，我們在最後一段收回來，
  // 因為台灣人日常就是寫「台」。
  test('台 stays 台, overriding upstream s2twp', () {
    expect(converter.convert('台湾'), '台灣');
    expect(converter.convert('台灣'), '台灣');
    expect(converter.convert('台北'), '台北');
    expect(converter.convert('平台'), '平台');
    expect(converter.convert('电台'), '電台');
  });

  test('a real sentence converts end to end', () {
    expect(
      converter.convert('开饭时间早上9点至下午5点'),
      '開飯時間早上9點至下午5點',
    );
  });
}
