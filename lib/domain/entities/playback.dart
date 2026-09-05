/// 播放器送回來的事件。播放本身是「開始就不管」，結束與失敗都靠這個通知。
sealed class PlaybackEvent {
  const PlaybackEvent();
}

/// 這一段播完了。
class PlaybackCompleted extends PlaybackEvent {
  const PlaybackCompleted();
}

class PlaybackFailed extends PlaybackEvent {
  const PlaybackFailed(this.message);

  final String message;
}
