import 'dart:io';

/// 錄音目錄的檔案層操作。
///
/// 只認得 `baseDir` 底下、名字全是數字的目錄（目錄名就是開始錄音的 epoch 毫秒）。
/// 刪除一律由 id 組出路徑，不接受外面傳進來的任意路徑，
/// 免得有一天誤刪到 `files/models/` 那 229 MB。
class RecordingStore {
  const RecordingStore();

  static final RegExp _id = RegExp(r'^\d+$');

  /// 列出錄音 id，新的排前面。
  List<String> listIds(String baseDir) {
    final dir = Directory(baseDir);
    if (!dir.existsSync()) return const [];

    final ids = dir
        .listSync()
        .whereType<Directory>()
        .map((entry) => entry.path.split(Platform.pathSeparator).last)
        .where(_id.hasMatch)
        .toList();
    // 目錄名是毫秒，位數一致，但還是照數值排，不靠字串長度。
    ids.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    return ids;
  }

  String pathOf(String baseDir, String id) =>
      '$baseDir${Platform.pathSeparator}$id';

  /// 刪掉一次錄音的整個目錄。目錄不存在就當作已經刪掉。
  Future<void> deleteOne(String baseDir, String id) async {
    if (!_id.hasMatch(id)) {
      throw ArgumentError.value(id, 'id', '不是合法的錄音 id');
    }
    final dir = Directory(pathOf(baseDir, id));
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// 刪掉全部錄音，回傳刪掉幾筆。
  Future<int> deleteAll(String baseDir) async {
    final ids = listIds(baseDir);
    for (final id in ids) {
      await deleteOne(baseDir, id);
    }
    return ids.length;
  }

  /// 錄音佔用的總位元組。只算錄音目錄，不含模型。
  Future<int> totalBytes(String baseDir) async {
    var total = 0;
    for (final id in listIds(baseDir)) {
      final dir = Directory(pathOf(baseDir, id));
      await for (final entry in dir.list(recursive: true)) {
        if (entry is File) total += await entry.length();
      }
    }
    return total;
  }
}
