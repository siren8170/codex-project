import 'audio_recorder_service.dart';

class PlaybackStatus {
  const PlaybackStatus({
    required this.position,
    required this.duration,
    required this.playing,
  });

  final Duration position;
  final Duration duration;
  final bool playing;
}

/// 녹음 파일 재생 계약. 한 번에 한 파일만 재생한다.
abstract class AudioPlayerService {
  /// 재생 중인 파일이 있으면 멈추고 [path]를 처음부터 재생한다.
  Future<void> play(String path);

  Future<void> stop();

  Future<PlaybackStatus> status();
}

/// Android MediaPlayer를 MethodChannel로 호출한다.
class PlatformAudioPlayerService implements AudioPlayerService {
  const PlatformAudioPlayerService();

  @override
  Future<void> play(String path) =>
      audioChannel.invokeMethod<int>('play', {'path': path});

  @override
  Future<void> stop() => audioChannel.invokeMethod<void>('stopPlayback');

  @override
  Future<PlaybackStatus> status() async {
    final map = await audioChannel.invokeMapMethod<String, Object?>(
      'playbackStatus',
    );
    return PlaybackStatus(
      position: Duration(milliseconds: (map?['position'] as int?) ?? 0),
      duration: Duration(milliseconds: (map?['duration'] as int?) ?? 0),
      playing: (map?['playing'] as bool?) ?? false,
    );
  }
}

/// 녹음 파일을 기기의 외부 저장소로 내보내는 계약.
abstract class AudioExportService {
  /// 시스템 저장 창을 띄운다. 저장하면 true, 사용자가 취소하면 false.
  Future<bool> export(String path, String fileName);
}

/// 시스템 "다른 이름으로 저장" 창(파일 앱, 기본 위치 다운로드 폴더)을 연다.
class PlatformAudioExportService implements AudioExportService {
  const PlatformAudioExportService();

  @override
  Future<bool> export(String path, String fileName) async =>
      await audioChannel.invokeMethod<bool>('export', {
        'path': path,
        'fileName': fileName,
      }) ??
      false;
}
