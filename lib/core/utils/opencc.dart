import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// OpenCC `s2twp`：簡體 → 台灣正體，含台灣用詞替換。
///
/// pub.dev 上兩個 OpenCC 套件都不能用（`opencc` 依賴已被取代的 native_assets_cli，
/// `flutter_opencc` 停在 Dart 2），所以直接照官方 `s2twp.json` 的轉換鏈自己實作。
/// 字典是 OpenCC 原始的 .txt，Apache-2.0，放在 `assets/opencc/`。
///
/// 轉換鏈就是兩段最長匹配替換：
///   1. STPhrases 短路 STCharacters      簡體 → 繁體
///   2. TWPhrases ∪ TWVariantsPhrases ∪ TWVariants   台灣用字與用詞
/// 前面再加一段 CJK 相容字正規化。
///
/// 同一組內用「先載入的優先」模擬 OpenCC 的 short_circuit：詞條字典的鍵較長，
/// 最長匹配自然會先命中詞條，命不中才落到單字字典。
class OpenCC {
  OpenCC._(this._stages);

  final List<_Dictionary> _stages;

  static OpenCC? _cached;

  /// 載入一次就快取。三個字典合計約 1.1 MB，只有第一次會花時間。
  static Future<OpenCC> s2twp({AssetBundle? bundle}) async {
    final cached = _cached;
    if (cached != null) return cached;

    final assets = bundle ?? rootBundle;

    final normalize = _Dictionary();
    await normalize.load(assets, 'assets/opencc/CJK_Compatibility_Ideographs.txt');

    final toTraditional = _Dictionary();
    await toTraditional.load(assets, 'assets/opencc/STPhrases.txt');
    await toTraditional.load(assets, 'assets/opencc/STCharacters.txt');

    final toTaiwan = _Dictionary();
    await toTaiwan.load(assets, 'assets/opencc/TWPhrases.txt');
    await toTaiwan.load(assets, 'assets/opencc/TWVariantsPhrases.txt');
    await toTaiwan.load(assets, 'assets/opencc/TWVariants.txt');

    return _cached = OpenCC._([normalize, toTraditional, toTaiwan]);
  }

  String convert(String input) {
    var text = input;
    for (final stage in _stages) {
      text = stage.apply(text);
    }
    return text;
  }
}

class _Dictionary {
  final Map<String, String> _entries = {};
  int _longestKey = 0;

  Future<void> load(AssetBundle bundle, String path) async {
    final content = await bundle.loadString(path);
    for (final line in content.split('\n')) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final tab = line.indexOf('\t');
      if (tab <= 0) continue;

      final key = line.substring(0, tab);
      // 一個鍵可以有多個候選值，以空白分隔；OpenCC 取第一個。
      var value = line.substring(tab + 1).trimRight();
      final space = value.indexOf(' ');
      if (space >= 0) value = value.substring(0, space);
      if (value.isEmpty) continue;

      // 先載入的字典優先，等同 short_circuit。
      if (_entries.containsKey(key)) continue;
      _entries[key] = value;
      if (key.length > _longestKey) _longestKey = key.length;
    }
  }

  /// 前向最長匹配。
  String apply(String input) {
    if (_entries.isEmpty || input.isEmpty) return input;

    final buffer = StringBuffer();
    var i = 0;
    while (i < input.length) {
      var matched = false;
      final maxLength =
          (input.length - i) < _longestKey ? input.length - i : _longestKey;

      for (var length = maxLength; length >= 1; length--) {
        final candidate = input.substring(i, i + length);
        final replacement = _entries[candidate];
        if (replacement != null) {
          buffer.write(replacement);
          i += length;
          matched = true;
          break;
        }
      }

      if (!matched) {
        // 沒命中就原樣抄一個字元。代理對要整組抄，不能從中間切開。
        final step = _isHighSurrogate(input.codeUnitAt(i)) &&
                i + 1 < input.length &&
                _isLowSurrogate(input.codeUnitAt(i + 1))
            ? 2
            : 1;
        buffer.write(input.substring(i, i + step));
        i += step;
      }
    }
    return buffer.toString();
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  static bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
}
