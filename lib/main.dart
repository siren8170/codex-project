import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/services/audio_player_service.dart';
import 'core/services/audio_recorder_service.dart';
import 'core/services/time_service.dart';
import 'data/audio_cleanup_service.dart';
import 'data/diary_store.dart';
import 'data/recording_store.dart';
import 'data/settings_store.dart';
import 'presentation/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await launchApp());
}

/// 앱 실행 시 저장된 설정과 일기를 읽고, 오디오 보관 기간이 지난 녹음을 지운 뒤 앱을 만든다.
Future<OneDayApp> launchApp({
  TimeService? timeService,
  AudioRecorderService? recorder,
  AudioPlayerService? player,
  AudioExportService? exporter,
  RecordingStore? recordingStore,
  SettingsStore? settingsStore,
  DiaryStore? diaryStore,
}) async {
  final clock = timeService ?? SystemTimeService();
  final audioRecorder = recorder ?? const PlatformAudioRecorderService();
  final store =
      recordingStore ??
      LocalRecordingStore(
        directoryPath: audioRecorder.recordingsDirectory,
        timeService: clock,
      );
  final settingsFile = settingsStore ?? defaultSettingsStore(audioRecorder);
  final diaryFile = diaryStore ?? defaultDiaryStore(audioRecorder);
  var settings = const AppSettings();
  try {
    settings = await settingsFile.load();
    await AudioCleanupService(store: store, timeService: clock).deleteExpired(
      retentionDays: settings.retentionDays,
      turnoverHour: settings.turnoverHour,
    );
  } catch (error) {
    debugPrint('실행 시 설정 읽기 또는 오디오 정리 실패: $error');
  }
  var diaries = <String, Diary>{};
  try {
    diaries = await diaryFile.loadAll();
  } catch (error) {
    debugPrint('일기 읽기 실패: $error');
  }
  return OneDayApp(
    timeService: clock,
    recorder: audioRecorder,
    player: player,
    exporter: exporter,
    recordingStore: store,
    settingsStore: settingsFile,
    diaryStore: diaryFile,
    initialSettings: settings,
    initialDiaries: diaries,
  );
}

/// 녹음 폴더와 같은 앱 내부 저장소 경로에 [name] 파일을 둔다.
Future<String> Function() _appFile(
  AudioRecorderService recorder,
  String name,
) =>
    () async => '${await recorder.recordingsDirectory()}/../$name';

SettingsStore defaultSettingsStore(AudioRecorderService recorder) =>
    FileSettingsStore(filePath: _appFile(recorder, 'settings.json'));

DiaryStore defaultDiaryStore(AudioRecorderService recorder) =>
    FileDiaryStore(filePath: _appFile(recorder, 'diaries.json'));

class OneDayApp extends StatelessWidget {
  const OneDayApp({
    super.key,
    this.timeService,
    this.recorder,
    this.player,
    this.exporter,
    this.recordingStore,
    this.settingsStore,
    this.diaryStore,
    this.initialSettings = const AppSettings(),
    this.initialDiaries = const {},
  });

  final TimeService? timeService;
  final AudioRecorderService? recorder;
  final AudioPlayerService? player;
  final AudioExportService? exporter;
  final RecordingStore? recordingStore;
  final SettingsStore? settingsStore;
  final DiaryStore? diaryStore;
  final AppSettings initialSettings;
  final Map<String, Diary> initialDiaries;

  @override
  Widget build(BuildContext context) {
    final clock = timeService ?? SystemTimeService();
    final audioRecorder = recorder ?? const PlatformAudioRecorderService();
    return MaterialApp(
      title: '오늘 하루',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MainScreen(
        timeService: clock,
        recorder: audioRecorder,
        player: player ?? const PlatformAudioPlayerService(),
        exporter: exporter ?? const PlatformAudioExportService(),
        recordingStore:
            recordingStore ??
            LocalRecordingStore(
              directoryPath: audioRecorder.recordingsDirectory,
              timeService: clock,
            ),
        settingsStore: settingsStore ?? defaultSettingsStore(audioRecorder),
        diaryStore: diaryStore ?? defaultDiaryStore(audioRecorder),
        initialSettings: initialSettings,
        initialDiaries: initialDiaries,
      ),
    );
  }
}
