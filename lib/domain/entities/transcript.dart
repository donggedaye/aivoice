/// 轉寫段落。9/3 只會有一段涵蓋整檔；9/4 接上 VAD 之後才會真的切段。
class TranscriptSegment {
  const TranscriptSegment({
    required this.id,
    required this.startMs,
    required this.endMs,
    required this.text,
    this.confidence,
  });

  final String id;
  final int startMs;
  final int endMs;
  final String text;
  final double? confidence;
}

class Transcript {
  const Transcript({required this.recordingId, required this.segments});

  final String recordingId;
  final List<TranscriptSegment> segments;

  String get text => segments
      .map((segment) => segment.text)
      .where((line) => line.isNotEmpty)
      .join('\n');
}
