import 'dart:isolate';

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
  static Future<OpenCC>? _loading;

  /// 載入一次就快取。字典合計約 1.1 MB。
  ///
  /// 解析（切行 + 五萬多次 map 寫入）是同步的，放在主 isolate 會凍住畫面幾百毫秒，
  /// 所以丟到 `Isolate.run`。整條 ASR 管線特地搬離主 isolate，這裡不能又搬回來。
  static Future<OpenCC> s2twp({AssetBundle? bundle}) {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    return _loading ??= _load(bundle ?? rootBundle);
  }

  static Future<OpenCC> _load(AssetBundle assets) async {
    try {
      Future<String> read(String name) =>
          assets.loadString('assets/opencc/$name');

      final normalize = [await read('CJK_Compatibility_Ideographs.txt')];
      final toTraditional = [
        await read('STPhrases.txt'),
        await read('STCharacters.txt'),
      ];
      final toTaiwan = [
        await read('TWPhrases.txt'),
        await read('TWVariantsPhrases.txt'),
        await read('TWVariants.txt'),
      ];

      final parsed = await _parseOffMainIsolate(
        normalize,
        toTraditional,
        toTaiwan,
      );

      return _cached = OpenCC._([
        for (final stage in parsed) _Dictionary(stage.$1, stage.$2),
        _Dictionary(_taiwanEveryday, 1),
      ]);
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  String convert(String input) {
    var text = input;
    for (final stage in _stages) {
      text = stage.apply(text);
    }
    return text;
  }
}

/// 台灣日常用字覆寫。**這份是我們自己維護的，不是 OpenCC 的資料。**
///
/// OpenCC 的 s2twp 依教育部標準用字把 台 對到 臺，所以會產出 臺灣、臺北、平臺。
/// 但台灣人日常書寫幾乎一律寫「台」。轉寫稿是要給使用者讀、之後還要當證據
/// 引用原話的，讀起來必須像人寫的，所以最後再過一遍把 臺 收回 台。
///
/// 代價是 兄臺、亭臺樓閣 這類文言用法也會被改掉。會議錄音裡出現的機率極低，
/// 而 台北／台中／平台／電台 天天都會出現，這個取捨划算。
const Map<String, String> _taiwanEveryday = {'臺': '台'};

/// 只收字串，不讓閉包碰到其他東西 —— 直接在 `_load` 裡寫 `Isolate.run`，
/// 閉包會連同一個 scope 的 AssetBundle 一起被捕捉，而 bundle 內部有 Future，
/// 無法跨 isolate 傳送。
Future<List<(Map<String, String>, int)>> _parseOffMainIsolate(
  List<String> normalize,
  List<String> toTraditional,
  List<String> toTaiwan,
) {
  return Isolate.run(
    () => [
      _parse(normalize),
      _parse(toTraditional),
      _parse(toTaiwan),
    ],
  );
}

/// 依序合併多份字典。先載入的優先，等同 OpenCC 的 short_circuit。
(Map<String, String>, int) _parse(List<String> contents) {
  final entries = <String, String>{};
  var longestKey = 0;

  for (final content in contents) {
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

      if (entries.containsKey(key)) continue;
      entries[key] = value;
      if (key.length > longestKey) longestKey = key.length;
    }
  }

  return (entries, longestKey);
}

class _Dictionary {
  _Dictionary(this._entries, this._longestKey);

  final Map<String, String> _entries;
  final int _longestKey;

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
