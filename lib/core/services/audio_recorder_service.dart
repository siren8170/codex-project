import 'package:flutter/services.dart';

/// 녹음·재생·내보내기를 처리하는 Android 네이티브 채널(`MainActivity.kt`).
const audioChannel = MethodChannel('one_day/audio');

/// 마이크 권한과 녹음을 화면에서 분리한 계약. 테스트에서는 가짜 구현을 주입한다.
abstract class AudioRecorderService {
  /// 마이크 권한을 확인하고, 없으면 시스템 권한 팝업을 띄운다.
  Future<bool> requestPermission();

  /// 녹음 파일을 보관할 앱 내부 저장소 경로.
  Future<String> recordingsDirectory();

  Future<void> start(String path);

  /// 녹음을 끝내고 저장된 파일 경로를 반환한다.
  Future<String> stop();
}

/// Android 기본 API(MediaRecorder)를 MethodChannel로 호출한다. 외부 패키지를 쓰지 않는다.
class PlatformAudioRecorderService implements AudioRecorderService {
  const PlatformAudioRecorderService();

  @override
  Future<bool> requestPermission() async =>
      await audioChannel.invokeMethod<bool>('requestPermission') ?? false;

  @override
  Future<String> recordingsDirectory() async =>
      (await audioChannel.invokeMethod<String>('recordingsDirectory'))!;

  @override
  Future<void> start(String path) =>
      audioChannel.invokeMethod<void>('start', {'path': path});

  @override
  Future<String> stop() async =>
      (await audioChannel.invokeMethod<String>('stop'))!;
}
