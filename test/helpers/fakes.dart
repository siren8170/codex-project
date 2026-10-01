import 'package:one_day/core/services/audio_player_service.dart';
import 'package:one_day/core/services/audio_recorder_service.dart';
import 'package:one_day/core/services/time_service.dart';
import 'package:one_day/data/diary_store.dart';
import 'package:one_day/data/recording_store.dart';
import 'package:one_day/data/settings_store.dart';

class FakeRecorder implements AudioRecorderService {
  FakeRecorder({this.granted = true});

  final bool granted;
  int permissionRequests = 0;
  String? recordingPath;
  final calls = <String>[];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<String> recordingsDirectory() async => '/fake/recordings';

  @override
  Future<void> start(String path) async {
    calls.add('start');
    recordingPath = path;
  }

  @override
  Future<String> stop() async {
    calls.add('stop');
    return recordingPath!;
  }
}

/// 녹음 중지 시 파일이 생긴 것처럼 경로를 기억하는 메모리 저장소.
class MemoryRecordingStore implements RecordingStore {
  MemoryRecordingStore(this.recorder, this.clock);

  final FakeRecorder recorder;
  final TimeService clock;
  final _times = <String, DateTime>{};
  final _seeded = <String, DateTime>{};

  /// 녹음 과정 없이 [at] 시각에 저장된 녹음을 만든다.
  void seed(DateTime at) => _seeded['/fake/seeded/${_seeded.length}.m4a'] = at;

  @override
  Future<String> newRecordingPath() async {
    final path = '/fake/recordings/${_times.length}.m4a';
    _times[path] = clock.now();
    return path;
  }

  @override
  Future<List<Recording>> list() async => [
    for (final entry in _seeded.entries)
      Recording(path: entry.key, recordedAt: entry.value, sizeBytes: 4096),
    for (final entry in _times.entries)
      if (recorder.calls.contains('stop'))
        Recording(path: entry.key, recordedAt: entry.value, sizeBytes: 4096),
  ];

  @override
  Future<void> delete(Recording recording) async {
    _times.remove(recording.path);
    _seeded.remove(recording.path);
  }
}

class MemoryDiaryStore implements DiaryStore {
  MemoryDiaryStore([Iterable<Diary> diaries = const []])
    : saved = {for (final d in diaries) diaryKey(d.date): d};

  final Map<String, Diary> saved;

  @override
  Future<Map<String, Diary>> loadAll() async => {...saved};

  @override
  Future<void> save(Diary diary) async => saved[diaryKey(diary.date)] = diary;
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this.saved = const AppSettings()]);

  AppSettings saved;

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async => saved = settings;
}

/// 재생 시각을 테스트에서 직접 흘려보내는 가짜 재생기.
class FakePlayer implements AudioPlayerService {
  String? playingPath;
  Duration position = Duration.zero;
  Duration duration = const Duration(seconds: 5);
  final played = <String>[];
  int stops = 0;

  @override
  Future<void> play(String path) async {
    playingPath = path;
    position = Duration.zero;
    played.add(path);
  }

  @override
  Future<void> stop() async {
    stops++;
    playingPath = null;
  }

  /// 끝까지 재생된 상태로 만든다.
  void finish() => playingPath = null;

  @override
  Future<PlaybackStatus> status() async => PlaybackStatus(
    position: position,
    duration: duration,
    playing: playingPath != null,
  );
}

class FakeExporter implements AudioExportService {
  FakeExporter({this.result = true});

  bool result;
  final exported = <(String, String)>[];

  @override
  Future<bool> export(String path, String fileName) async {
    exported.add((path, fileName));
    return result;
  }
}
