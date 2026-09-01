import 'package:flutter_test/flutter_test.dart';

import 'package:aivoice/data/local/asr_worker.dart';

void main() {
  // 迴歸測試：worker 在建立 recognizer / VAD 的階段就拋例外時，SendPort 還沒送出
  // 來，早期版本的 `ready` completer 因此永遠不會完成，`transcribe()` 卡在 await，
  // 錄音頁停在「辨識中」而且不會顯示任何錯誤。這裡要求它明確失敗。
  test('a bad model path fails instead of hanging forever', () async {
    final worker = AsrWorker();
    addTearDown(worker.dispose);

    await expectLater(
      worker.transcribe(
        modelPath: '/nonexistent/model.int8.onnx',
        tokensPath: '/nonexistent/tokens.txt',
        vadPath: '/nonexistent/silero_vad.onnx',
        pcmPath: '/nonexistent/audio.pcm',
      ),
      throwsA(isA<Error>()),
    );
  }, timeout: const Timeout(Duration(seconds: 60)));
}
